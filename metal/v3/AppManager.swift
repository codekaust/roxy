//
//  AppManager.swift
//  metal
//
//  Created by Ayush on 23/12/25.
//

import Foundation
import AppKit

class AppManager {
    
    // Cache the list so we don't scan the hard drive every time you click "Open"
    private static var cachedAppList: [String: URL] = [:]
    
    /// 1. Scans the system for installed apps.
    static func refreshAppList() {
        let fileManager = FileManager.default
        var apps: [String: URL] = [:]
        
        // Directories where apps usually live on macOS
        let appDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            "\(NSHomeDirectory())/Applications" // User's local apps
        ]
        
        for path in appDirectories {
            // Skip if directory doesn't exist or we can't read it
            guard let urls = try? fileManager.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil) else { continue }
            
            for url in urls {
                // We only care about .app bundles
                if url.pathExtension == "app" {
                    // Clean the name: "Google Chrome.app" -> "Google Chrome"
                    let name = url.deletingPathExtension().lastPathComponent
                    apps[name] = url
                }
            }
        }
        
        cachedAppList = apps
        print("AppManager: Indexed \(apps.count) apps.")
    }
    
    /// 2. Attempts to find and open an app by name (fuzzy match).
    /// Returns a status string to display in the UI.
    static func launchApp(name: String) -> String {
        // Ensure we have data
        if cachedAppList.isEmpty {
            refreshAppList()
        }
        
        // Clean input: remove whitespace, make lowercase
        let cleanedInput = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // A. Try Exact Match (Fastest)
        if let url = cachedAppList[name] {
            open(url: url)
            return "Launched exact match: \(name)"
        }
        
        // B. Try Case-Insensitive Match
        // e.g. User types "safari" -> Matches "Safari"
        if let match = cachedAppList.keys.first(where: { $0.lowercased() == cleanedInput }) {
            open(url: cachedAppList[match]!)
            return "Launched: \(match)"
        }
        
        // C. Try Partial Match
        // e.g. User types "code" -> Matches "Visual Studio Code" or "Xcode"
        if let match = cachedAppList.keys.first(where: { $0.lowercased().contains(cleanedInput) }) {
            open(url: cachedAppList[match]!)
            return "Launched partial match: \(match)"
        }
        
        return "❌ Could not find app named '\(name)'"
    }
    
    // Helper to actually perform the system call
    private static func open(url: URL) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true // Bring to front
        
        NSWorkspace.shared.openApplication(at: url, configuration: config) { app, error in
            if let error = error {
                print("AppManager: Failed to open \(url.lastPathComponent): \(error)")
            } else {
                print("AppManager: Successfully launched \(app?.localizedName ?? "App")")
            }
        }
    }
}
