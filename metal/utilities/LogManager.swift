//
//  LogManager.swift
//  metal
//
//  Centralized logging system for capturing and displaying logs in the UI
//

import Foundation
import SwiftUI

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let level: LogLevel

    enum LogLevel: String {
        case debug = "🔍"
        case info = "ℹ️"
        case success = "✅"
        case warning = "⚠️"
        case error = "❌"
        case thinking = "🤔"
        case sensing = "👀"
        case acting = "⚡️"
        case goal = "🤖"
    }

    var formattedMessage: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: timestamp)
        return "[\(time)] \(level.rawValue) \(message)"
    }
}

class LogManager: ObservableObject {
    static let shared = LogManager()

    @Published var logs: [LogEntry] = []
    private let maxLogs = 1000 // Limit to prevent memory issues
    private let queue = DispatchQueue(label: "com.metal.logmanager", attributes: .concurrent)

    private init() {}

    func log(_ message: String, level: LogEntry.LogLevel = .info) {
        let entry = LogEntry(timestamp: Date(), message: message, level: level)

        // Also print to console for debugging
        print(entry.formattedMessage)

        // Update logs on main thread for UI
        queue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.logs.append(entry)

                // Trim old logs if needed
                if self.logs.count > self.maxLogs {
                    self.logs.removeFirst(self.logs.count - self.maxLogs)
                }
            }
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }

    // Convenience methods for different log levels
    func debug(_ message: String) {
        log(message, level: .debug)
    }

    func info(_ message: String) {
        log(message, level: .info)
    }

    func success(_ message: String) {
        log(message, level: .success)
    }

    func warning(_ message: String) {
        log(message, level: .warning)
    }

    func error(_ message: String) {
        log(message, level: .error)
    }

    func thinking(_ message: String) {
        log(message, level: .thinking)
    }

    func sensing(_ message: String) {
        log(message, level: .sensing)
    }

    func acting(_ message: String) {
        log(message, level: .acting)
    }

    func goal(_ message: String) {
        log(message, level: .goal)
    }
}
