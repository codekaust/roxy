import Foundation

// MARK: - API Request/Response Models

/// Request body for task submission
struct TaskRequest: Codable {
    let task: String
}

/// Response for task submission
struct TaskResponse: Codable {
    let success: Bool
    let message: String
    let error: String?

    init(success: Bool, message: String, error: String? = nil) {
        self.success = success
        self.message = message
        self.error = error
    }
}

/// Agent status for web client polling
struct AgentStatus: Codable {
    let nSteps: Int
    let stopped: Bool
    let currentTask: String
    let lastGoal: String?
}

/// Log entry data transfer object for SSE streaming
struct LogEntryDTO: Codable {
    let timestamp: String  // ISO8601 format
    let message: String
    let level: String

    init(from entry: LogEntry) {
        let formatter = ISO8601DateFormatter()
        self.timestamp = formatter.string(from: entry.timestamp)
        self.message = entry.message
        self.level = entry.level.rawValue
    }
}

/// Chat message data transfer object for web chat UI
struct ChatMessageDTO: Codable {
    let id: String
    let timestamp: String  // ISO8601 format
    let type: String  // "user", "ai", "system"
    let subtype: String  // "conversation", "taskExecution"
    let content: String
    let status: String  // "complete", "inProgress", "error"
    let systemLogs: [LogEntryDTO]

    init(from message: ChatMessage) {
        self.id = message.id.uuidString

        let formatter = ISO8601DateFormatter()
        self.timestamp = formatter.string(from: message.timestamp)

        // Map type
        switch message.type {
        case .user: self.type = "user"
        case .aiResponse: self.type = "ai"
        case .system: self.type = "system"
        }

        // Map subtype
        switch message.subtype {
        case .conversation: self.subtype = "conversation"
        case .taskExecution: self.subtype = "taskExecution"
        }

        self.content = message.content

        // Map status
        switch message.status {
        case .complete: self.status = "complete"
        case .inProgress: self.status = "inProgress"
        case .error: self.status = "error"
        }

        // Map system logs
        self.systemLogs = message.systemLogs.map { LogEntryDTO(from: $0) }
    }
}
