//
//  GeminiModels.swift
//  metal
//
//  Created by Ayush on 22/12/25.
//

import Foundation

// MARK: - Message Roles
enum MessageRole: String, Codable {
    case user = "user"
    case model = "model"
    case tool = "tool"
}

// MARK: - Content Parts
// Swift enums with associated values are great for "Sealed Classes"
enum ContentPart: Codable {
    case text(String)
    
    // Custom coding keys to handle the JSON structure if needed,
    // but for simple text parts, we can often simplify.
    // Assuming internal usage, we'll keep it simple.
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else {
            throw DecodingError.typeMismatch(ContentPart.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown content part type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let t): try container.encode(t)
        }
    }
}

// MARK: - Gemini Message

struct GeminiMessage: Codable {
    let role: MessageRole
    let parts: [ContentPart]
    let toolCode: String?
    
    init(role: MessageRole, parts: [ContentPart], toolCode: String? = nil) {
        self.role = role
        self.parts = parts
        self.toolCode = toolCode
    }
    
    // Convenience for simple text
    init(text: String) {
        self.role = .user
        self.parts = [.text(text)]
        self.toolCode = nil
    }
}

// MARK: - EXTENSION: Adapter for MemoryManager
// This keeps the Agent code clean by moving the conversion logic here.
extension GeminiMessage {
    init(from generic: LLMMessage) {
        // Safe mapping with a fallback
        self.role = MessageRole(rawValue: generic.role) ?? .user
        self.parts = [.text(generic.content)]
        self.toolCode = nil
    }
}
