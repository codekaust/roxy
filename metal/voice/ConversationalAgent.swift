import Foundation
import SwiftUI
import Combine // 1. Import Combine
import AppKit

@MainActor
class ConversationalAgent: ObservableObject {
    
    // Dependencies
    // We make sttManager accessible so the View can observe it if needed,
    // but usually, we map it to published vars here.
    let sttManager = STTManager()
    private let ttsManager = TTSManager.shared
    private let perception = Perception()
    private let llmClient: VoiceGeminiApi
    
    // The "Task Executor" Agent
    private let taskAgentState = AgentState()
    private lazy var taskAgent: Agent = Agent(state: taskAgentState)
    
    // State
    @Published var isListening: Bool = false
    @Published var isThinking: Bool = false
    @Published var liveCaption: String = "" // To show user what is being heard
    
    private var conversationHistory: [GeminiMessage] = []
    
    // 2. Cancellation token for the silence timer
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize LLM client with API key from ConfigurationManager
        let apiKey = ConfigurationManager.shared.getAPIKey(for: .geminiLLM) ?? ""
        self.llmClient = VoiceGeminiApi(
            modelName: "gemini-3-flash-preview",
            apiKey: apiKey
        )
        initializeConversation()
    }
    
    // MARK: - Public Control
    
    func startSession() {
        LogManager.shared.info("ConversationalAgent: Session Started \(conversationHistory)")
        initializeConversation()
        startListening()
    }

    func stopSession() {
        LogManager.shared.info("ConversationalAgent: Session Stopped")
        sttManager.stopRecording()
        ttsManager.stop()
        taskAgent.stop()
        self.conversationHistory = []
        self.isListening = false
        // Cancel any pending silence timers
        cancellables.removeAll()
    }
    

    // MARK: - Core Loop (Listen -> Think -> Act)
    
    func toggleSession() {
        if isListening {
            stopSession()
        } else {
            startSession()
        }
    }
    
    private func startListening() {
        guard !isListening else { return }

        LogManager.shared.info("ConversationalAgent: Listening...")
        self.isListening = true
        self.liveCaption = ""
        
        // 1. Start the actual microphone engine
        sttManager.startRecording()
        
        // 2. Setup Silence Detection using Combine
        sttManager.$transcribedText
            .dropFirst() // Ignore the initial empty string
            .filter { !$0.isEmpty } // Only process if we have actual text
            .handleEvents(receiveOutput: { [weak self] (text: String) in
                // Update the UI immediately as words come in
                self?.liveCaption = text
                
                // Show in Overlay (Last One Wins)
                Task { @MainActor in
                    _ = OverlayManager.shared.showCaption(text: text)
                }
            })
            // 3. THE MAGIC: Wait for 1.5 seconds of silence
            .debounce(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [weak self] finalString in
                guard let self = self else { return }


                // If we are here, the user hasn't spoken for 1.5 seconds
                LogManager.shared.info("Silence detected. Committing: \(finalString)")
                self.processInput(text: finalString)
            }
            .store(in: &cancellables)
    }
    
    // Call this when STT is done
    func processInput(text: String) {
        // Stop listening so we don't pick up the agent's own voice
        sttManager.stopRecording()
        self.isListening = false
        cancellables.removeAll() 
        
        guard !text.isEmpty else { return }
        
        Task {
            await handleUserInput(text)
        }
    }
    
    // MARK: - Logic Port: processUserInput
    
    private func handleUserInput(_ userInput: String) async {
        LogManager.shared.info("ConversationalAgent: User said: \(userInput)")

        // 1. Check for hard stop command
        if userInput.lowercased().contains("stop") || userInput.lowercased().contains("exit") {
            await gracefulShutdown(message: "Goodbye!", reason: "command")
            return
        }
        
        self.isThinking = true
        
        // 2. Update System Prompts
//        updateSystemPromptWithAgentStatus()
        await updateSystemPromptWithScreenContext()
        updateSystemPromptWithTime()
        
        // 3. Add User Message to History
        conversationHistory.append(GeminiMessage(role: .user, parts: [.text(userInput)]))
        
        // 4. Call LLM
        let decision: ModelDecision? = await llmClient.generate(messages: conversationHistory)
        
        self.isThinking = false
        
        guard let decision = decision else {
            await speakAndListen(text: "I'm having trouble thinking right now. Could you repeat that?")
            return
        }

        LogManager.shared.info("ConversationalAgent: Decision -> Type: \(decision.type) | Reply: \(decision.reply)")

        // 5. Handle Decision
        switch decision.type {
        case "Task":
            await handleTaskDecision(decision)
        case "KillTask":
            await handleKillTaskDecision(decision)
        case "Reply":
            fallthrough
        default:
            conversationHistory.append(GeminiMessage(role: .model, parts: [.text(decision.safeReply)]))
            if decision.shouldEnd == "Finished" {
                await gracefulShutdown(message: decision.safeReply, reason: "model_ended")
            } else {
                await speakAndListen(text: decision.safeReply)
            }
        }
    }
    
    private func handleTaskDecision(_ decision: ModelDecision) async {
        if !taskAgentState.stopped && taskAgentState.nSteps > 0 {
            let busyMsg = "I'm already working on '\(taskAgentState.currentTask)'. Ask me to stop it if you want to switch."
            conversationHistory.append(GeminiMessage(role: .model, parts: [.text(busyMsg)]))
            await speakAndListen(text: busyMsg)
            return
        }
        
        let permissionsGood = AXIsProcessTrusted()
        if !permissionsGood {
             let permMsg = "I need accessibility permissions to do that."
             conversationHistory.append(GeminiMessage(role: .model, parts: [.text(permMsg)]))
             await speakAndListen(text: permMsg)
             return
        }

        LogManager.shared.info("ConversationalAgent: Starting Task Agent with instruction: \(decision.instruction)")

        // Add to chat history
        DispatchQueue.main.async {
            ChatHistoryManager.shared.addUserMessage(decision.instruction)
            ChatHistoryManager.shared.startAIResponse(
                initialLog: "Processing voice command: \(decision.instruction)"
            )
        }

        await ttsManager.speak(decision.safeReply)
        taskAgent.start(task: decision.instruction)
    }
    
    private func handleKillTaskDecision(_ decision: ModelDecision) async {
        if !taskAgentState.stopped {
            taskAgent.stop()
            await speakAndListen(text: decision.safeReply)
        } else {
            await speakAndListen(text: "There was no automation running, but I can help with something else.")
        }
    }
    
    private func speakAndListen(text: String) async {
        await ttsManager.speak(text)
        
        // Resume listening (Continuous Conversation Loop)
        startListening()
    }
    
    private func gracefulShutdown(message: String, reason: String) async {
        LogManager.shared.info("ConversationalAgent: Shutting down (\(reason))")
        await ttsManager.speak(message)
        stopSession()
    }

    // MARK: - Prompt Engineering
    
    private func initializeConversation() {

        let systemPrompt = """
            You are a helpful voice assistant called Metal that can either have a conversation or ask an executor to execute tasks on the user's MacOS.
            The executor can speak, listen, see the screen, tap the screen, and basically use the Laptop as a normal human would.



            ### Current Screen Context ###
            {screen_context}
            ### End Screen Context ###

            Some Guideline:
            1. If the user ask you to do something creative, you do this task and be the most creative person in the world.
            2. If you know the user's name from the memories, refer to them by their name to make the conversation more personal and friendly as often as possible.
            3. Use the current screen context to better understand what the user is looking at and provide more relevant responses.
            4. If the user asks about something on the screen, you can reference the screen content directly.
            5. Always ask for clarification if the user's request is ambiguous or unclear.
            6. When the user ask to sing, shout or produce any sound, just generate text, we will sing it for you.
            7. When asked about personal stuff make up stuff as real person would., dont say I am AI, i dont think, do not lie that you are an AI and live inside user computer.

            Analyze the user's request and respond ONLY with a single, valid JSON object.
            Do not include any text, notes, or explanations outside of the JSON object.
            The JSON object must have the following structure:
            
            {
              "Type": "String",
              "Reply": "String",
              "Instruction": "String",
              "Should End": "String"
            }

            Here are the rules for the JSON values:
            - "Type": Must be one of "Task", "Reply", or "KillTask".
              - Use "Task" if the user is asking you to DO something on the device (e.g., "open settings", "send a text to Mom").
              - Use "Reply" for conversational questions (e.g., "what's the weather?", "tell me a joke").
              - Use "KillTask" ONLY if an automation task is running and the user wants to stop it.
            - "Reply": The text to speak to the user. This is a confirmation for a "Task", or the direct answer for a "Reply".
            - "Instruction": The precise, literal instruction for the task agent. This field should be an empty string "" if the "Type" is not "Task".
            - "Should End": Must be either "Continue" or "Finished". Use "Finished" only when the conversation is naturally over.
        
            Current Time : {time_context}
        """

        

        conversationHistory = [GeminiMessage(role: .user, parts: [.text(systemPrompt)])]
    }
    //TODO: Implement latyer
    // private func updateSystemPromptWithAgentStatus() {
    //     guard let sysMsg = conversationHistory.first else { return }
    //     guard case .text(let promptText) = sysMsg.parts.first else { return }
        
    //     let isRunning = !taskAgentState.stopped && taskAgentState.nSteps > 0
    //     let statusContext = isRunning ? "IMPORTANT: A task is currently running." : "CONTEXT: No task is running."
        
    //     // Simple replace (Note: ideally use a base template to avoid overwrite issues in long sessions)
    //     let newPrompt = promptText.replacingOccurrences(of: "{agent_status_context}", with: statusContext)
    //     conversationHistory[0] = GeminiMessage(role: .user, parts: [.text(newPrompt)])
    // }
    
    private func updateSystemPromptWithTime() {
        // Implementation omitted for brevity (same as previous)
        guard let sysMsg = conversationHistory.first else { return }
        guard case .text(let promptText) = sysMsg.parts.first else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeContext = "Current Date and Time: \(formatter.string(from: Date()))"
        
        let newPrompt = promptText.replacingOccurrences(of: "{time_context}", with: timeContext)
        conversationHistory[0] = GeminiMessage(role: .user, parts: [.text(newPrompt)])
    }
    
    private func updateSystemPromptWithScreenContext() async {
        let analysis = await perception.analyze()
        guard let sysMsg = conversationHistory.first else { return }
        guard case .text(let promptText) = sysMsg.parts.first else { return }
        
        // Use a placeholder if it exists, otherwise prompt might degrade over time without base template
        let newPrompt = promptText.replacingOccurrences(of: "{screen_context}", with: analysis.uiRepresentation)
        conversationHistory[0] = GeminiMessage(role: .user, parts: [.text(newPrompt)])
    }
}
