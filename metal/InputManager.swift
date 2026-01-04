// FILE: metal/InputManager.swift

import Foundation
import ApplicationServices

class InputManager {
    static let shared = InputManager()
    private init() {}

    func click(at point: CGPoint) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        let mouseDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)
        let mouseUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)
        
        mouseDown?.post(tap: .cghidEventTap)
        usleep(50000) // 50ms hold
        mouseUp?.post(tap: .cghidEventTap)
    }
    
    // Added: Right click context
    func rightClick(at point: CGPoint) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        let mouseDown = CGEvent(mouseEventSource: source, mouseType: .rightMouseDown, mouseCursorPosition: point, mouseButton: .right)
        let mouseUp = CGEvent(mouseEventSource: source, mouseType: .rightMouseUp, mouseCursorPosition: point, mouseButton: .right)
        
        mouseDown?.post(tap: .cghidEventTap)
        usleep(50000)
        mouseUp?.post(tap: .cghidEventTap)
    }

    func type(_ text: String) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        // Simple string typing
        // Note: For special keys (Enter), we handle them separately usually, 
        // but this works for general text.
        for char in text {
            var charBuffer = [UniChar(String(char).utf16.first!)]
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            
            keyDown?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &charBuffer)
            keyUp?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &charBuffer)
            
            keyDown?.post(tap: .cghidEventTap)
            usleep(10000) // Fast typing
            keyUp?.post(tap: .cghidEventTap)
        }
    }
    
    func pressEnter() {
        pressKey(keyCode: 36)
    }
    
    private func pressKey(keyCode: CGKeyCode) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        usleep(50000)
        keyUp?.post(tap: .cghidEventTap)
    }

    // Added: Scroll
    func scroll(amount: Int) {
        // macOS scroll events are different than Android swipes.
        // amount > 0 = Scroll Down (Content moves up)
        // amount < 0 = Scroll Up (Content moves down)
        // We scale 'amount' down because pixels vs scroll lines differ.
        let scrollY = Int32(amount / 10) 
        
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let scroll = CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 1, wheel1: scrollY, wheel2: 0, wheel3: 0)
        scroll?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Focus Detection
    func isTextFieldFocused() -> Bool {
        // 1. Get the system-wide accessibility element
        let systemWideElement = AXUIElementCreateSystemWide()
        
        // 2. Get the focused element
        var focusedElementRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRef)
        
        guard result == .success, let focusedElement = focusedElementRef else {
            return false
        }
        
        let axElement = focusedElement as! AXUIElement
        
        // 3. Get the Role of the focused element
        var roleRef: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &roleRef)
        
        guard roleResult == .success, let role = roleRef as? String else {
            return false
        }
        
        print("InputManager: Focused Element Role -> \(role)")
        
        // 4. Check if it's a text entry role
        // Common roles: AXTextField, AXTextArea
        let textRoles = ["AXTextField", "AXTextArea", "AXComboBox"]
        if textRoles.contains(role) {
            return true
        }
        
        return false
    }
    
    // MARK: - Deletion
    func delete(count: Int) {
        guard count > 0 else { return }
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        // kVK_Delete = 0x33
        // We can just loop.
        for _ in 0..<count {
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false)
            keyDown?.post(tap: .cghidEventTap)
            usleep(1000) // Very fast backspace
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}