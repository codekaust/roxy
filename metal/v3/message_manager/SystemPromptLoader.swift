import Foundation

class SystemPromptLoader {
    
    static func getSystemMessage(settings: AgentSettings) -> String {
        let actionsDesc = generateActionsDescription()
        
        // Get generic prompt from Prompts.swift (ensure Prompts.macOSSystemPrompt exists)
        var prompt = Prompts.macOSSystemPrompt
        
        // Replacements
        prompt = prompt.replacingOccurrences(of: "{max_actions}", with: String(settings.maxActionsPerStep))
        prompt = prompt.replacingOccurrences(of: "{available_actions}", with: actionsDesc)

        // Add User Info with preferences
        let userInfo = PreferenceManager.shared.getUserInfoSection()
        prompt = prompt.replacingOccurrences(of: "{user_info}", with: userInfo)
        
        return prompt
    }
    
  private static func generateActionsDescription() -> String {
        // Iterate over the source of truth in Action.swift
        let specs = Action.allSpecs
        
        var output = ""
        
        for spec in specs {
            output += "<action>\n"
            output += "  <name>\(spec.name)</name>\n"
            output += "  <description>\(spec.description)</description>\n"
            
            if !spec.params.isEmpty {
                output += "  <parameters>\n"
                for param in spec.params {
                    output += "     <param>"
                    output += "<name>\(param.name)</name>"
                    output += "<type>\(param.type)</type>"
                    if !param.description.isEmpty {
                        output += "<description>\(param.description)</description>"
                    }
                    output += "</param>\n"
                }
                output += "  </parameters>\n"
            }
            
            output += "</action>\n\n"
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
