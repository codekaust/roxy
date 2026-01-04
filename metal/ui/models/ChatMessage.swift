import Foundation

enum MessageType {
    case user           // User's command/question
    case aiResponse     // AI's response (groups system logs)
    case system         // Individual system log
}

enum MessageStatus {
    case complete       // Finished processing
    case inProgress     // Currently executing
    case error          // Failed
}

struct ChatMessage: Identifiable {
    let id: UUID
    let timestamp: Date
    let type: MessageType
    var content: String  // Changed to var so it can be updated
    var status: MessageStatus
    var systemLogs: [LogEntry]  // Nested logs under AI response

    init(id: UUID = UUID(), timestamp: Date = Date(), type: MessageType,
         content: String, status: MessageStatus = .complete, systemLogs: [LogEntry] = []) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.content = content
        self.status = status
        self.systemLogs = systemLogs
    }
}
