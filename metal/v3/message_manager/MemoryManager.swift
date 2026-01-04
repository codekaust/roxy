import Foundation

class MemoryManager {
    private var task: String
    private let fileSystem: FileSystem
    private let settings: AgentSettings
    
    // State
    var historyItems: [HistoryItem] = []
    var readStateDescription: String = ""
    private var systemMessage: String = ""
    
    init(task: String, fileSystem: FileSystem, settings: AgentSettings) {
        self.task = task
        self.fileSystem = fileSystem
        self.settings = settings
        
        // Init History
        self.historyItems.append(HistoryItem(stepNumber: 0, systemMessage: "Agent initialized"))
        
        // Load System Prompt
        self.systemMessage = SystemPromptLoader.getSystemMessage(settings: settings)
    }
    
    func addNewTask(newTask: String) {
        self.task = newTask
        historyItems.append(HistoryItem(stepNumber: 0, systemMessage: "<user_request> added: \(newTask)"))
    }
    
    // Create the full message payload for the LLM
    func createMessages(
        modelOutput: AgentOutput?,
        result: [ActionResult]?,
        stepInfo: AgentStepInfo,
        screenAnalysis: ScreenAnalysis
    ) -> [LLMMessage] {
        
        // 1. Update History with previous step results
        updateHistory(modelOutput: modelOutput, result: result, stepInfo: stepInfo)
        
        // 2. Build User Message (The current state)
        let builderArgs = UserMessageBuilder.Args(
            task: self.task,
            screenAnalysis: screenAnalysis,
            fileSystem: self.fileSystem,
            agentHistoryDescription: getAgentHistoryDescription(),
            readStateDescription: self.readStateDescription,
            stepInfo: stepInfo
        )
        
        let stateMessage = UserMessageBuilder.build(args: builderArgs)
        
        // 3. Return formatted messages
        return [
            LLMMessage(role: "system", content: systemMessage),
            LLMMessage(role: "user", content: stateMessage)
        ]
    }
    
    private func updateHistory(modelOutput: AgentOutput?, result: [ActionResult]?, stepInfo: AgentStepInfo) {
        // Clear old read state
        self.readStateDescription = ""
        
        guard let output = modelOutput else {
            if stepInfo.stepNumber > 1 {
                 historyItems.append(HistoryItem(stepNumber: stepInfo.stepNumber, error: "Agent failed to produce valid output."))
            }
            return
        }
        
        // Process Actions
        var actionResultsText = ""
        if let results = result {
            for (index, res) in results.enumerated() {
                // Populate read state if needed
                if res.includeExtractedContentOnlyOnce, let content = res.extractedContent {
                    self.readStateDescription += content + "\n"
                }
                
                // Format for history
                if let memory = res.longTermMemory {
                    actionResultsText += "Action \(index + 1): \(memory)\n"
                } else if let err = res.error {
                    actionResultsText += "Action \(index + 1): ERROR - \(err.prefix(200))\n"
                }
            }
        }
        
        let newItem = HistoryItem(
            stepNumber: stepInfo.stepNumber,
            evaluation: output.evaluationPreviousGoal,
            memory: output.memory,
            nextGoal: output.nextGoal,
            actionResults: actionResultsText.isEmpty ? nil : actionResultsText
        )
        
        historyItems.append(newItem)
    }
    
    private func getAgentHistoryDescription() -> String {
        // Simple truncation strategy
        let maxItems = 10
        if historyItems.count <= maxItems {
            return historyItems.map { $0.toPromptString() }.joined(separator: "\n")
        }
        
        let first = historyItems.first?.toPromptString() ?? ""
        let recent = historyItems.suffix(maxItems - 1).map { $0.toPromptString() }
        let omitted = historyItems.count - maxItems
        
        return first + "\n<sys>[... \(omitted) previous steps omitted...]</sys>\n" + recent.joined(separator: "\n")
    }
}

// Helper struct for generic LLM API
struct LLMMessage: Codable {
    let role: String
    let content: String
}
