import SwiftUI

struct AgentView: View {
    // State objects
    @StateObject private var agentState = AgentState()
    @EnvironmentObject var voiceAgent: ConversationalAgent
    @ObservedObject private var chatHistory = ChatHistoryManager.shared

    // Local state
    @State private var messageInput: String = ""
    @State private var agent: Agent?
    @State private var isAgentInitialized = false

    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            chatHeader

            // CHAT MESSAGES
            chatScrollView

            // INPUT BAR (fixed at bottom)
            ChatInputBar(
                text: $messageInput,
                isDisabled: isTaskRunning,
                onSubmit: sendMessage,
                onVoiceToggle: toggleVoice,
                isVoiceActive: voiceAgent.isListening
            )
        }
        .background(Color.black)  // Pure black OLED background
        .onAppear(perform: initializeAgent)
    }

    // MARK: - Subviews

    var chatHeader: some View {
        HStack {
            AIStatusVisualization(state: currentAIState)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                GradientText(
                    "Roxy",
                    gradient: RoxyGradients.cyanPurple,
                    font: RoxyFonts.title2,
                    fontWeight: .bold,
                    shimmer: true
                )

                Text(statusText)
                    .font(RoxyFonts.caption)
                    .foregroundColor(statusColor)
            }

            Spacer()

            if !chatHistory.messages.isEmpty {
                FuturisticButton(
                    icon: "trash",
                    variant: .iconOnly,
                    size: .small
                ) {
                    clearChat()
                }
            }
        }
        .padding(RoxySpacing.md)
        .darkGlassEffect(
            tint: RoxyColors.neonPurple,
            neonBorder: RoxyGradients.neonBorderMagenta,
            opacity: 0.2
        )
    }

    var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: RoxySpacing.md) {
                    if chatHistory.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(chatHistory.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(RoxySpacing.md)
            }
            .onChange(of: chatHistory.messages.count) {
                if let lastMessage = chatHistory.messages.last {
                    withAnimation(RoxyAnimation.smoothSpring) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: RoxySpacing.lg) {
            ThinkingParticles()
                .frame(height: 120)

            GradientText(
                "Ready to assist",
                gradient: RoxyGradients.cyanPurple,
                font: RoxyFonts.title3,
                fontWeight: .semibold
            )

            Text("Send a message or use voice to start")
                .font(RoxyFonts.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(RoxySpacing.xl)
    }

    // MARK: - Computed Properties

    var isTaskRunning: Bool {
        agentState.nSteps > 0 && !agentState.stopped
    }

    var currentAIState: AIStatusVisualization.AIState {
        if voiceAgent.isListening {
            return .listening
        } else if isTaskRunning {
            return .thinking
        } else {
            return .idle
        }
    }

    var statusText: String {
        if voiceAgent.isListening {
            return voiceAgent.liveCaption.isEmpty ? "Listening..." : "\"\(voiceAgent.liveCaption)\""
        } else if isTaskRunning {
            return "Working on it..."
        } else {
            return "Ready"
        }
    }

    var statusColor: Color {
        if voiceAgent.isListening {
            return RoxyColors.listening
        } else if isTaskRunning {
            return RoxyColors.thinking
        } else {
            return RoxyColors.idle
        }
    }

    // MARK: - Actions

    func sendMessage() {
        guard !messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let text = messageInput
        messageInput = ""

        // Add user message to chat
        chatHistory.addUserMessage(text)

        // Start AI response
        chatHistory.startAIResponse(initialLog: "Processing your request...")

        // Start agent
        agentState.nSteps = 0
        agentState.stopped = false
        agent?.start(task: text)
    }

    func toggleVoice() {
        if voiceAgent.isListening {
            voiceAgent.stopSession()
        } else {
            if isTaskRunning {
                agent?.stop()
            }
            voiceAgent.startSession()
        }
    }

    func clearChat() {
        withAnimation(RoxyAnimation.spring) {
            chatHistory.clear()
            LogManager.shared.clear()
        }
    }

    func initializeAgent() {
        if !isAgentInitialized {
            agentState.nSteps = 0
            agentState.stopped = true
            self.agent = Agent(state: agentState)
            isAgentInitialized = true
        }
    }
}
