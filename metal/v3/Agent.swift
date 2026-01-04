import Foundation
import SwiftUI

// This needs to be an Actor or run on a specific actor to manage state safely
@MainActor
class Agent {
    private let settings: AgentSettings
    private let perception: Perception
    private let actionExecutor: ActionExecutor
    private let fileSystem: FileSystem
    
    // We need an LLM Client
    // TODO: Move API key to secure storage or Settings
    private let llmClient = GeminiApi(
        modelName: "gemini-3-flash-preview",
        apiKey: "AIzaSyBAPzvrfZF0_aPS7FkoynkdxmuP_cQcwWc"
    )
    
    // Observable State (Published to SwiftUI)
    private var state: AgentState
    private var memoryManager: MemoryManager?
    
    init(state: AgentState) {
        self.state = state
        self.settings = AgentSettings()
        self.perception = Perception()
        self.fileSystem = FileSystem()
        // We initialize actionExecutor with the real input manager
        self.actionExecutor = ActionExecutor()
    }
    
    func start(task: String) {
        Task {
            await runLoop(initialTask: task)
        }
    }
    
    func stop() {
        DispatchQueue.main.async {
            self.state.stopped = true
            OverlayManager.shared.clear()
        }
    }
    
    private func runLoop(initialTask: String) async {
        // 1. Setup
        fileSystem.reset()
        
        
        let memManager = MemoryManager(task: initialTask, fileSystem: fileSystem, settings: settings)
        self.memoryManager = memManager
        
    
        self.state.stopped = false
        self.state.nSteps = 0
        self.state.currentTask = initialTask
    
        
        let maxSteps = settings.maxActionsPerStep * 10 // Arbitrary limit
        

        
        // 2. Loop
        while !state.stopped && state.nSteps < maxSteps {
            
            // A. SENSE
            LogManager.shared.sensing("Sensing...")
            let screenAnalysis = await perception.analyze()
            await OverlayManager.shared.update(elements: screenAnalysis.elements)
            // B. THINK (Prepare)
            let stepInfo = AgentStepInfo(stepNumber: state.nSteps, maxSteps: maxSteps)
            
            // 1. Get generic messages from Memory
            let rawMessages = memManager.createMessages(
                modelOutput: state.lastModelOutput,
                result: state.lastResult,
                stepInfo: stepInfo,
                screenAnalysis: screenAnalysis
            )
            
            // 2. Convert to Gemini-specific format (The "Clean" way)
            let geminiMessages = rawMessages.map(GeminiMessage.init)
            
            // C. THINK (Call LLM)
            LogManager.shared.thinking("Thinking...")
            // Ensure UI updates regarding thinking happen on main thread
            DispatchQueue.main.async { self.state.paused = true } // Just reusing 'paused' as 'busy' indicator if needed

            guard let agentOutput = await llmClient.generateAgentOutput(messages: geminiMessages) else {
                LogManager.shared.error("LLM Failure")
                state.consecutiveFailures += 1
                if state.consecutiveFailures > 3 { break }
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                continue
            }
            
            state.consecutiveFailures = 0
            
            DispatchQueue.main.async {
                self.state.lastModelOutput = agentOutput
                self.state.paused = false
            }

            LogManager.shared.goal("Goal: \(agentOutput.nextGoal ?? "Unknown")")

            // D. ACT
            LogManager.shared.acting("Acting...")
            var results: [ActionResult] = []

            for action in agentOutput.action {
                let res = await actionExecutor.execute(action: action, screenAnalysis: screenAnalysis, fileSystem: fileSystem)
                results.append(res)

                LogManager.shared.info("  -> \(res.longTermMemory ?? res.error ?? "Done")")

                if res.error != nil { break } // Stop step on error
                if res.isDone == true {
                    DispatchQueue.main.async { self.state.stopped = true }
                    LogManager.shared.success("Task Done!")
                }
            }
            
            DispatchQueue.main.async {
                self.state.lastResult = results
                self.state.nSteps += 1
            }
            
            // Delay for pacing
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        }
        await OverlayManager.shared.clear()
        LogManager.shared.info("--- Agent Stopped ---")

    }
}

