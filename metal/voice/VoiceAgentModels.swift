import Foundation

// Mirrors the Kotlin 'ModelDecision' data class
struct ModelDecision: Codable {
    let type: String       // "Task", "Reply", "KillTask"
    let reply: String      // What to speak to the user
    let instruction: String // The prompt for the Task Agent (if Type is Task)
    let shouldEnd: String   // "Continue" or "Finished"
    
    // Safety check for empty replies
    var safeReply: String {
        return reply.isEmpty ? "I'm not sure how to respond to that." : reply
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case reply = "Reply"
        case instruction = "Instruction"
        case shouldEnd = "Should End"
    }
}
