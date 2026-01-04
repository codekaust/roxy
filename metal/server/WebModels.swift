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
