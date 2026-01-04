//
//  PreferenceModels.swift
//  metal
//
//  Created by Claude on 04/01/26.
//

import Foundation

/// Result from LLM preference extraction
struct PreferenceExtractionResult: Codable {
    let preferences: [PreferenceCategory]
}

/// A category of preferences (e.g., "Browsers", "Contacts")
struct PreferenceCategory: Codable {
    let category: String
    let items: [String]
}
