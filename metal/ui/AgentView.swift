import SwiftUI

struct AgentView: View {
    // 1. Existing Shared State for the Task Agent
    @StateObject private var agentState = AgentState()
    
    // 2. NEW: The Voice Agent
    @EnvironmentObject var voiceAgent: ConversationalAgent
    
    // 3. Persistence & Text Input
    @AppStorage("lastTask") private var lastTask: String = ""
    @State private var taskInput: String = ""
    
    // 4. Agent Reference (Lazy init)
    @State private var agent: Agent?
    @State private var isAgentInitialized = false
    
    var body: some View {
        VStack(spacing: 16) {
            
            // --- HEADER ---
            HStack {
                Text("Panda Agent")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                
                // STATUS INDICATOR
                if voiceAgent.isThinking {
                    Text("Thinking...")
                        .foregroundColor(.orange)
                        .font(.caption)
                } else if voiceAgent.isListening {
                    // Display the live caption here
                    Text(voiceAgent.liveCaption.isEmpty ? "Listening..." : "\"\(voiceAgent.liveCaption)\"")
                        .foregroundColor(.green)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            // --- MAIN CONTROLS ---
            HStack(spacing: 12) {
                
                // A. TEXT INPUT (Classic Mode)
                TextField("What would you like to do?", text: $taskInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isRunning || voiceAgent.isListening) // Disable if busy
                    .onSubmit { startTextAgent() }
                
                // B. VOICE BUTTON (New)
                Button {
                    toggleVoiceSession()
                } label: {
                    Image(systemName: voiceAgent.isListening ? "mic.fill" : "mic.slash.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(voiceAgent.isListening ? .white : .primary)
                        .padding(8)
                        .background(voiceAgent.isListening ? Color.red : Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(voiceAgent.isListening ? "Stop Listening" : "Start Voice Assistant")
                
                // C. START/STOP BUTTON (Text Mode)
                if isRunning {
                    Button(role: .destructive) {
                        stopTextAgent()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                    .tint(.red)
                } else {
                    Button {
                        startTextAgent()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .disabled(taskInput.isEmpty)
                }
            }
            
            // --- HEADER ---
                        HStack {
                            Text("Panda Agent")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            
                            // STATUS INDICATOR
                            if voiceAgent.isThinking {
                                Text("Thinking...")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            } else if voiceAgent.isListening {
                                // Display the live caption here
                                Text(voiceAgent.liveCaption.isEmpty ? "Listening..." : "\"\(voiceAgent.liveCaption)\"")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
            
            Divider()
            
            // --- TASK LOG / OUTPUT AREA ---
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if isRunning {
                        Text("Current Task: \(agentState.currentTask)")
                            .font(.headline)
                        
                        Text("Step \(agentState.nSteps)...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Ready for instructions.")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .onAppear {
            // Init the Task Agent (used by both Text & Voice logic)
            if !isAgentInitialized {
                agentState.nSteps = 0
                agentState.stopped = true
                self.agent = Agent(state: agentState)
                isAgentInitialized = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var isRunning: Bool {
        return agentState.nSteps > 0 && !agentState.stopped
    }
    
    // MARK: - Voice Logic
    
    func toggleVoiceSession() {
        if voiceAgent.isListening {
            voiceAgent.stopSession()
        } else {
            // Stop text agent if running to avoid conflicts
            if isRunning { stopTextAgent() }
            voiceAgent.startSession()
        }
    }
    
    // MARK: - Text Logic
    
    func startTextAgent() {
        // Stop voice if active
        if voiceAgent.isListening { voiceAgent.stopSession() }
        
        guard !taskInput.isEmpty else { return }
        
        lastTask = taskInput
        agentState.nSteps = 0
        agentState.stopped = false
        agent?.start(task: taskInput)
    }
    
    func stopTextAgent() {
        agent?.stop()
    }
}
