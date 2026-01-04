import Foundation

enum MessageType {
    case user           // User's command/question
    case aiResponse     // AI's response (groups system logs)
    case system         // Individual system log
}

enum MessageSubtype {
    case conversation    // Simple back-and-forth chat (no system logs)
    case taskExecution   // Agent executing a task (has system logs)
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
    var subtype: MessageSubtype  // NEW: Distinguish conversation from task execution
    var content: String  // Changed to var so it can be updated
    var status: MessageStatus
    var systemLogs: [LogEntry]  // Nested logs under AI response

    init(id: UUID = UUID(), timestamp: Date = Date(), type: MessageType,
         subtype: MessageSubtype = .taskExecution,  // Default for backward compatibility
         content: String, status: MessageStatus = .complete, systemLogs: [LogEntry] = []) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.subtype = subtype
        self.content = content
        self.status = status
        self.systemLogs = systemLogs
    }
}
