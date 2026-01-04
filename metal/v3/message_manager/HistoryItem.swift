import Foundation

// Represents a single item in the agent's high-level history summary.
struct HistoryItem: Codable {
    let stepNumber: Int?
    let evaluation: String?
    let memory: String?
    let nextGoal: String?
    let actionResults: String?
    let error: String?
    let systemMessage: String? // For special messages like "Task updated"
    
    init(stepNumber: Int? = nil, evaluation: String? = nil, memory: String? = nil, nextGoal: String? = nil, actionResults: String? = nil, error: String? = nil, systemMessage: String? = nil) {
        self.stepNumber = stepNumber
        self.evaluation = evaluation
        self.memory = memory
        self.nextGoal = nextGoal
        self.actionResults = actionResults
        self.error = error
        self.systemMessage = systemMessage
    }
    
    // Formats this item into a string for the LLM prompt.
    func toPromptString() -> String {
        let stepStr = (stepNumber != nil) ? "step_\(stepNumber!)" : "step_unknown"
        
        var content = ""
        
        if let err = error {
            content = err
        } else if let sys = systemMessage {
            content = sys
        } else {
            var parts: [String] = []
            if let ev = evaluation { parts.append("Evaluation of Previous Step: \(ev)") }
            if let mem = memory { parts.append("Memory: \(mem)") }
            if let goal = nextGoal { parts.append("Next Goal: \(goal)") }
            if let res = actionResults { parts.append(res) }
            content = parts.joined(separator: "\n")
        }
        
        return "<\(stepStr)>\n\(content)\n</\(stepStr)>"
    }
}
