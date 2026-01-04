import Foundation

// MARK: - Configuration
struct AgentSettings {
    var maxActionsPerStep: Int = 10
    var maxFailures: Int = 3
    var saveConversationPath: String? = nil
    var useThinking: Bool = false
}

// MARK: - State
// Using ObservableObject is correct for SwiftUI updates
class AgentState: ObservableObject {
    @Published var nSteps: Int = 1
    @Published var stopped: Bool = true
    @Published var paused: Bool = false // Added
    @Published var currentTask: String = "" // Added to track current objective
    
    var consecutiveFailures: Int = 0
    var lastResult: [ActionResult]? = nil
    var lastModelOutput: AgentOutput? = nil
    
    // We will hold the messages in MemoryManager, but this tracks high level history
    var historyItems: [AgentHistory] = []
}

struct AgentStepInfo {
    let stepNumber: Int
    let maxSteps: Int
    
    func isLastStep() -> Bool {
        return stepNumber >= maxSteps - 1
    }
}

// MARK: - Action Result
struct ActionResult: Codable {
    var isDone: Bool? = false
    var success: Bool? = nil
    var error: String? = nil
    var longTermMemory: String? = nil
    var extractedContent: String? = nil
    var includeExtractedContentOnlyOnce: Bool = false // Added to match Kotlin logic
    var attachments: [String]? = nil
}

// MARK: - Brain (Thinking State)
struct AgentBrain {
    let thinking: String?
    let evaluationPreviousGoal: String?
    let memory: String?
    let nextGoal: String?
}

// MARK: - Agent Output (From LLM)
struct AgentOutput: Codable {
    let thinking: String?
    let evaluationPreviousGoal: String?
    let memory: String?
    let nextGoal: String?
    let action: [Action]
    
    enum CodingKeys: String, CodingKey {
        case thinking
        case evaluationPreviousGoal = "evaluation_previous_goal"
        case memory
        case nextGoal = "next_goal"
        case action
    }
    
    // Helper to extract just the thought process for UI overlays
    var currentState: AgentBrain {
        return AgentBrain(
            thinking: thinking,
            evaluationPreviousGoal: evaluationPreviousGoal,
            memory: memory,
            nextGoal: nextGoal
        )
    }
}

// MARK: - History Item
struct AgentHistory {
    let modelOutput: AgentOutput?
    let result: [ActionResult]
    // Note: We are not storing the full ScreenState here yet to save memory,
    // but in Kotlin you stored 'state'. We can add that back if needed for debugging.
    let metadata: StepMetadata?
}

struct StepMetadata {
    let stepStartTime: Date
    let stepEndTime: Date
    let stepNumber: Int
    
    var durationSeconds: TimeInterval {
        return stepEndTime.timeIntervalSince(stepStartTime)
    }
}
