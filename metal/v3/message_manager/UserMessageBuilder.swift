//
//  UserMessageBuilder.swift
//  metal
//
//  Created by Ayush on 22/12/25.
//

import Foundation

struct UserMessageBuilder {
    
    struct Args {
        let task: String
        let screenAnalysis: ScreenAnalysis
        let fileSystem: FileSystem
        let agentHistoryDescription: String
        let readStateDescription: String
        let stepInfo: AgentStepInfo
        // Optional: Sensitive data map could be added here
        let maxUiRepresentationLength: Int = 40000
    }
    
    static func build(args: Args) -> String {
        var prompt = ""
        
        // 1. History
        prompt += "<agent_history>\n"
        prompt += args.agentHistoryDescription.isEmpty ? "No history yet." : args.agentHistoryDescription
        prompt += "\n</agent_history>\n\n"
        
        // 2. Agent State (Internal & Files)
        prompt += "<agent_state>\n"
        prompt += buildAgentStateBlock(args: args)
        prompt += "\n</agent_state>\n\n"
        
        // 3. Mac State (The Screen)
        prompt += "<mac_state>\n"
        prompt += buildMacStateBlock(screenAnalysis: args.screenAnalysis, maxLength: args.maxUiRepresentationLength)
        prompt += "\n</mac_state>\n\n"
        
        // 4. Read State (Temporary file content)
        if !args.readStateDescription.isEmpty {
            prompt += "<read_state>\n"
            prompt += args.readStateDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            prompt += "\n</read_state>\n\n"
        }
        
        return prompt
    }
    
    private static func buildMacStateBlock(screenAnalysis: ScreenAnalysis, maxLength: Int) -> String {
        let originalUi = screenAnalysis.uiRepresentation
        var finalUi = originalUi
        var truncMsg = ""
        
        if originalUi.count > maxLength {
            finalUi = String(originalUi.prefix(maxLength))
            truncMsg = " (truncated to \(maxLength) characters)"
        }
        
        return """
        Current App: \(screenAnalysis.activeAppName)
        Visible elements on the current screen:\(truncMsg)
        \(finalUi)
        """
    }
    
    private static func buildAgentStateBlock(args: Args) -> String {
        // We need to implement a 'getTodoContents' on FileSystem later, or just read todo.md
        let todoContent = args.fileSystem.readFile(fileName: "todo.md")
        let todoDisplay = todoContent.hasPrefix("Error") ? "[Current todo.md is empty, fill it with your plan when applicable]" : todoContent
        
        let dateStr = Date().formatted(date: .numeric, time: .shortened)
        let stepDesc = "Step \(args.stepInfo.stepNumber + 1) of \(args.stepInfo.maxSteps) max possible steps\nCurrent date: \(dateStr)"
        
        return """
        <user_request>
        \(args.task)
        </user_request>
        <file_system>
        Persistent storage is available at ~/Documents/
        </file_system>
        <todo_contents>
        \(todoDisplay)
        </todo_contents>
        <step_info>
        \(stepDesc)
        </step_info>
        """
    }
}
