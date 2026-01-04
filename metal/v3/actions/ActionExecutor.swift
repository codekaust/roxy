import Foundation
import ApplicationServices
import AppKit
import AVFoundation
import SwiftUI

class ActionExecutor {
    private let inputManager = InputManager.shared
    private let synthesizer = AVSpeechSynthesizer()
    func execute(action: Action, screenAnalysis: ScreenAnalysis, fileSystem: FileSystem) async -> ActionResult {
        
        switch action {
        
        case .tap(let payload):
            // 1. Find the element in our map
            guard let element = screenAnalysis.elementMap[payload.index] else {
                return ActionResult(error: "Element [\(payload.index)] not found in current analysis.")
            }
            
            // 2. Direct Physical Click (No Fallback)
            if let frame = getFrame(element) {
                let center = CGPoint(x: frame.midX, y: frame.midY)
                inputManager.click(at: center)
                return ActionResult(longTermMemory: "Clicked element [\(payload.index)] at \(Int(center.x)), \(Int(center.y)).")
            }
            
            return ActionResult(error: "Could not click element [\(payload.index)]: Unable to determine screen coordinates.")

        case .type(let payload):
            // Assumes focus is already set by a previous tap
            inputManager.type(payload.text)
            inputManager.pressEnter()
            return ActionResult(longTermMemory: "Typed text: '\(payload.text)' and pressed Enter.")

        case .wait(let payload):
            let duration = Int(payload.duration) ?? 2
            try? await Task.sleep(nanoseconds: UInt64(duration) * 1_000_000_000)
            return ActionResult(longTermMemory: "Waited for \(duration) seconds.")

        case .scroll(let payload):
            inputManager.scroll(amount: payload.amount)
            return ActionResult(longTermMemory: "Scrolled \(payload.amount) pixels.")
            
        case .openApp(let payload):
            let status = AppManager.launchApp(name: payload.appName)
            if status.contains("❌") {
                return ActionResult(error: status)
            }
            return ActionResult(longTermMemory: "Opened app: \(payload.appName)")

        // --- FILE SYSTEM ---
        case .readFile(let payload):
            let content = fileSystem.readFile(fileName: payload.fileName)
            return ActionResult(
                longTermMemory: "Read file \(payload.fileName)",
                extractedContent: content,
                includeExtractedContentOnlyOnce: true
            )
            
        case .writeFile(let payload):
            let success = fileSystem.writeFile(fileName: payload.fileName, content: payload.content)
            if success {
                print("ActionExecutor: 📝 Write success for \(payload.fileName)")
                if payload.fileName == "todo.md" {
                    print("ActionExecutor: 🎯 Detected todo.md write. Updating overlay...")
                    await MainActor.run {
                        OverlayManager.shared.todoContent = payload.content
                        print("ActionExecutor: ✅ OverlayManager todoContent set.")
                    }
                }
                return ActionResult(longTermMemory: "Wrote content to file \(payload.fileName)")
            } else {
                return ActionResult(error: "Failed to write to \(payload.fileName)")
            }

        case .appendFile(let payload):
            let success = fileSystem.appendFile(fileName: payload.fileName, content: payload.content)
            if success {
                print("ActionExecutor: 📝 Append success for \(payload.fileName)")
                if payload.fileName == "todo.md" {
                     print("ActionExecutor: 🎯 Detected todo.md append. Reading full file...")
                     let fullContent = fileSystem.readFile(fileName: "todo.md")
                     await MainActor.run {
                         OverlayManager.shared.todoContent = fullContent
                         print("ActionExecutor: ✅ OverlayManager todoContent updated with \(fullContent.count) chars.")
                     }
                }
                return ActionResult(longTermMemory: "Appended content to file \(payload.fileName)")
            } else {
                return ActionResult(error: "Failed to append to \(payload.fileName)")
            }
            
        case .speak(let payload):
            await TTSManager.shared.speak(payload.message)
            return ActionResult(longTermMemory: "Spoke: \"\(payload.message)\"")
        // --- NEW: ASK ACTION ---
        case .ask(let payload):
            return await MainActor.run {
                // 1. Speak the question using AVFoundation
                Task { await TTSManager.shared.speak(payload.question) }
                // 2. Create a Native Alert
                let alert = NSAlert()
                alert.messageText = "Agent Question"
                alert.informativeText = payload.question
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Reply")
                
                // 3. Add Input Field
                let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
                input.placeholderString = "Type your answer here..."
                alert.accessoryView = input
                
                // 4. Focus the input field when window shows
                alert.window.initialFirstResponder = input
                
                // 5. Run Modal (Blocks execution until user clicks Reply)
                _ = alert.runModal()
                
                let answer = input.stringValue
                
                // 6. Return the answer as memory
                return ActionResult(longTermMemory: "Asked user: \"\(payload.question)\". User replied: \"\(answer)\"")
            }
        case .done(let payload):
            return ActionResult(
                isDone: true,
                success: payload.success,
                longTermMemory: "Task Completed: \(payload.text)",
                attachments: payload.filesToDisplay
            )
            
        case .back, .home:
             return ActionResult(longTermMemory: "System navigation command executed.")
        }
    }
    
    // Helper: Extract valid screen coordinates from the AXUIElement
    private func getFrame(_ element: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)
        
        var point = CGPoint.zero
        var size = CGSize.zero
        
        // Unpack AXValue (CoreFoundation types)
        if let pRef = positionRef, CFGetTypeID(pRef) == AXValueGetTypeID() {
            AXValueGetValue(pRef as! AXValue, .cgPoint, &point)
        } else { return nil }
        
        if let sRef = sizeRef, CFGetTypeID(sRef) == AXValueGetTypeID() {
            AXValueGetValue(sRef as! AXValue, .cgSize, &size)
        } else { return nil }
        
        return CGRect(origin: point, size: size)
    }
}
