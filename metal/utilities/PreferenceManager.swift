//
//  PreferenceManager.swift
//  metal
//
//  Created by Claude on 04/01/26.
//

import Foundation
import SwiftUI

class PreferenceManager: ObservableObject {
    static let shared = PreferenceManager()

    private let fileManager = FileManager.default
    private let maxPreferenceSize = 8000 // characters

    @Published var preferencesLoaded: Bool = false

    // Check if feature is enabled
    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "preferenceLearningEnabled")
    }

    private init() {
        // Set default value if not set
        if UserDefaults.standard.object(forKey: "preferenceLearningEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "preferenceLearningEnabled")
        }
    }

    // MARK: - Public API

    /// Returns formatted user info section for system prompt (thread-safe)
    func getUserInfoSection() -> String {
        // Check if feature is enabled
        guard isEnabled else {
            return "User: macOS Owner"
        }

        let preferences = loadPreferences()

        if preferences.isEmpty {
            return """
            User: macOS Owner

            <user_preferences>
            No user preferences learned yet. As you complete tasks, you will learn the user's habits and preferences.
            </user_preferences>
            """
        }

        return """
        User: macOS Owner

        <user_preferences>
        \(preferences)
        </user_preferences>
        """
    }

    /// Extracts and saves preferences after task completion
    func learnFromTask(
        task: String,
        history: [HistoryItem],
        finalResult: [ActionResult]?,
        fileSystem: FileSystem
    ) async {
        // Check if feature is enabled
        guard isEnabled else {
            LogManager.shared.debug("PreferenceManager: Learning disabled")
            return
        }

        guard let extracted = await extractPreferencesViaLLM(task: task, history: history, finalResult: finalResult) else {
            return
        }

        // Skip if no preferences found
        guard !extracted.preferences.isEmpty else {
            LogManager.shared.debug("PreferenceManager: No preferences found in task")
            return
        }

        // Merge and save
        let existing = loadPreferences()
        let merged = mergePreferences(existing: existing, new: extracted)

        if savePreferences(merged) {
            LogManager.shared.info("PreferenceManager: Learned \(extracted.preferences.count) preference categories")
        }
    }

    /// Manually reset all preferences
    func clearAllPreferences() -> Bool {
        do {
            let fileURL = getPreferencesFileURL()

            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                LogManager.shared.info("PreferenceManager: Cleared all preferences")
            }

            return true
        } catch {
            LogManager.shared.error("PreferenceManager: Failed to clear preferences - \(error)")
            return false
        }
    }

    /// Get file path for debugging
    func getPreferencesPath() -> URL {
        return getPreferencesFileURL()
    }

    // MARK: - Private Methods

    private func getPreferencesFileURL() -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let roxyDir = appSupport.appendingPathComponent("org.roxyorg.roxy")

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: roxyDir, withIntermediateDirectories: true)

        return roxyDir.appendingPathComponent("preferences.md")
    }

    private func loadPreferences() -> String {
        do {
            let fileURL = getPreferencesFileURL()

            guard fileManager.fileExists(atPath: fileURL.path) else {
                return ""
            }

            let content = try String(contentsOf: fileURL, encoding: .utf8)

            // Basic validation: Should start with "# Roxy"
            if !content.hasPrefix("# Roxy") {
                throw NSError(domain: "PreferenceManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Corrupted file"])
            }

            // Check size limit
            if content.count > maxPreferenceSize {
                LogManager.shared.warning("PreferenceManager: Preferences file too large (\(content.count) chars), truncating to \(maxPreferenceSize)")
                return String(content.prefix(maxPreferenceSize))
            }

            return content

        } catch {
            LogManager.shared.error("PreferenceManager: Failed to load preferences - \(error)")

            // Handle corrupted file
            let fileURL = getPreferencesFileURL()
            if fileManager.fileExists(atPath: fileURL.path) {
                let backupURL = fileURL.deletingLastPathComponent()
                    .appendingPathComponent("preferences.md.corrupted-\(Date().timeIntervalSince1970)")
                try? fileManager.moveItem(at: fileURL, to: backupURL)
                LogManager.shared.info("PreferenceManager: Moved corrupted file to \(backupURL.lastPathComponent)")
            }

            return ""
        }
    }

    private func savePreferences(_ content: String) -> Bool {
        do {
            let fileURL = getPreferencesFileURL()
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            LogManager.shared.error("PreferenceManager: Failed to save preferences - \(error)")
            return false
        }
    }

    private func extractPreferencesViaLLM(
        task: String,
        history: [HistoryItem],
        finalResult: [ActionResult]?
    ) async -> PreferenceExtractionResult? {
        // Build context from history
        let historySummary = history.map { item in
            var summary = ""
            if let goal = item.nextGoal {
                summary += "Goal: \(goal)\n"
            }
            if let actions = item.actionResults {
                summary += "Actions: \(actions)\n"
            }
            return summary
        }.joined(separator: "\n")

        let completionMessage = finalResult?.compactMap { $0.longTermMemory }.joined(separator: " ") ?? "Task ended"

        // Build prompt
        var prompt = Prompts.preferenceExtractionPrompt
        prompt = prompt.replacingOccurrences(of: "{original_task}", with: task)
        prompt = prompt.replacingOccurrences(of: "{history_summary}", with: historySummary)
        prompt = prompt.replacingOccurrences(of: "{completion_message}", with: completionMessage)

        // Call Gemini API
        let apiKey = ConfigurationManager.shared.getAPIKey(for: .geminiLLM) ?? ""
        let geminiClient = GeminiApi(modelName: "gemini-2.0-flash-exp", apiKey: apiKey)

        let messages = [
            GeminiMessage(role: .user, parts: [.text(prompt)])
        ]

        // Get response
        guard let response = await geminiClient.generateAgentOutput(messages: messages) else {
            LogManager.shared.error("PreferenceManager: Failed to extract preferences from LLM")
            return nil
        }

        // Try to parse the thinking field as JSON
        guard let thinkingText = response.thinking else {
            LogManager.shared.error("PreferenceManager: No thinking field in LLM response")
            return nil
        }

        // Try to extract JSON from the thinking text
        return parsePreferencesFromText(thinkingText)
    }

    private func parsePreferencesFromText(_ text: String) -> PreferenceExtractionResult? {
        // Try to find JSON in the text
        let jsonPattern = "\\{[\\s\\S]*\"preferences\"[\\s\\S]*\\}"

        if let regex = try? NSRegularExpression(pattern: jsonPattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {

            let jsonString = String(text[range])

            if let jsonData = jsonString.data(using: .utf8),
               let result = try? JSONDecoder().decode(PreferenceExtractionResult.self, from: jsonData) {
                return result
            }
        }

        // If no JSON pattern found, try parsing the entire text
        if let jsonData = text.data(using: .utf8),
           let result = try? JSONDecoder().decode(PreferenceExtractionResult.self, from: jsonData) {
            return result
        }

        LogManager.shared.error("PreferenceManager: Failed to parse JSON from LLM response")
        return nil
    }

    private func mergePreferences(existing: String, new: PreferenceExtractionResult) -> String {
        // Parse existing markdown into categories
        var existingCategories = parseMarkdownToCategories(existing)

        // Merge new preferences
        for newCategory in new.preferences {
            if var existingItems = existingCategories[newCategory.category] {
                // Deduplicate and append
                for newItem in newCategory.items {
                    if !existingItems.contains(where: { isSimilar($0, newItem) }) {
                        existingItems.append(newItem)
                    }
                }
                existingCategories[newCategory.category] = existingItems
            } else {
                // New category
                existingCategories[newCategory.category] = newCategory.items
            }
        }

        // Rebuild markdown
        return buildMarkdownFromCategories(existingCategories)
    }

    private func parseMarkdownToCategories(_ markdown: String) -> [String: [String]] {
        var categories: [String: [String]] = [:]

        let lines = markdown.components(separatedBy: .newlines)
        var currentCategory: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Category header (## Category)
            if trimmed.hasPrefix("## ") {
                currentCategory = String(trimmed.dropFirst(3))
                if categories[currentCategory!] == nil {
                    categories[currentCategory!] = []
                }
            }
            // Item (- Item text)
            else if trimmed.hasPrefix("- "), let category = currentCategory {
                let item = String(trimmed.dropFirst(2))
                categories[category]?.append(item)
            }
        }

        return categories
    }

    private func buildMarkdownFromCategories(_ categories: [String: [String]]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var output = "# Roxy User Preferences\n\n"
        output += "Last Updated: \(dateFormatter.string(from: Date()))\n\n"

        for (category, items) in categories.sorted(by: { $0.key < $1.key }) {
            output += "## \(category)\n"
            for item in items {
                output += "- \(item)\n"
            }
            output += "\n"
        }

        return output
    }

    private func isSimilar(_ str1: String, _ str2: String) -> Bool {
        // Simple similarity check: 90% threshold using Levenshtein distance
        let distance = levenshteinDistance(str1.lowercased(), str2.lowercased())
        let maxLen = max(str1.count, str2.count)

        guard maxLen > 0 else { return true }

        return Double(distance) / Double(maxLen) < 0.1
    }

    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let s1 = Array(str1)
        let s2 = Array(str2)

        var distances = Array(repeating: Array(repeating: 0, count: s2.count + 1), count: s1.count + 1)

        for i in 0...s1.count {
            distances[i][0] = i
        }

        for j in 0...s2.count {
            distances[0][j] = j
        }

        for i in 1...s1.count {
            for j in 1...s2.count {
                if s1[i - 1] == s2[j - 1] {
                    distances[i][j] = distances[i - 1][j - 1]
                } else {
                    distances[i][j] = min(
                        distances[i - 1][j] + 1,      // deletion
                        distances[i][j - 1] + 1,      // insertion
                        distances[i - 1][j - 1] + 1   // substitution
                    )
                }
            }
        }

        return distances[s1.count][s2.count]
    }
}
