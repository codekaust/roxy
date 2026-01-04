import SwiftUI
import Combine

class ChatHistoryManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private var cancellables = Set<AnyCancellable>()
    private var currentTaskStartIndex: Int?

    // Singleton
    static let shared = ChatHistoryManager()
    private init() {
        observeLogManager()
    }

    // Add user message
    func addUserMessage(_ text: String) {
        let message = ChatMessage(
            type: .user,
            content: text,
            status: .complete
        )
        messages.append(message)
    }

    // NEW: Add conversational AI message (no system logs)
    func addConversationalAIMessage(_ text: String) {
        let message = ChatMessage(
            type: .aiResponse,
            subtype: .conversation,  // No system logs
            content: text,
            status: .complete
        )
        messages.append(message)
    }

    // Start AI response (when task begins)
    func startAIResponse(initialLog: String = "Starting task...") {
        let message = ChatMessage(
            type: .aiResponse,
            subtype: .taskExecution,  // Has system logs
            content: initialLog,
            status: .inProgress,
            systemLogs: []
        )
        messages.append(message)
        currentTaskStartIndex = LogManager.shared.logs.count
    }

    // Update current AI response with new logs
    func updateCurrentAIResponse() {
        guard var lastMessage = messages.last,
              lastMessage.type == .aiResponse,
              lastMessage.status == .inProgress,
              let startIndex = currentTaskStartIndex else {
            return
        }

        // Get new logs since task started
        let allLogs = LogManager.shared.logs
        if startIndex < allLogs.count {
            let newLogs = Array(allLogs[startIndex...])
            lastMessage.systemLogs = newLogs
            messages[messages.count - 1] = lastMessage
        }
    }

    // Complete AI response (when task finishes)
    func completeAIResponse(finalMessage: String) {
        guard messages.last?.type == .aiResponse else { return }

        var lastMessage = messages.last!
        lastMessage.content = finalMessage
        lastMessage.status = .complete
        messages[messages.count - 1] = lastMessage
        currentTaskStartIndex = nil
    }

    // Mark AI response as error
    func markAIResponseAsError(errorMessage: String) {
        guard messages.last?.type == .aiResponse else { return }

        var lastMessage = messages.last!
        lastMessage.content = errorMessage
        lastMessage.status = .error
        messages[messages.count - 1] = lastMessage
        currentTaskStartIndex = nil
    }

    // Clear all messages
    func clear() {
        messages.removeAll()
        currentTaskStartIndex = nil
    }

    // Observe LogManager for real-time updates
    private func observeLogManager() {
        LogManager.shared.$logs
            .sink { [weak self] _ in
                self?.updateCurrentAIResponse()
            }
            .store(in: &cancellables)
    }
}
