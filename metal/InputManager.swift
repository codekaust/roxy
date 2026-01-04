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

    func pressKeyByName(_ keyName: String) -> Bool {
        guard let keyCode = keyNameToCode(keyName) else {
            print("InputManager: Unknown key name '\(keyName)'")
            return false
        }
        pressKey(keyCode: keyCode)
        return true
    }

    private func keyNameToCode(_ keyName: String) -> CGKeyCode? {
        let keyMap: [String: CGKeyCode] = [
            // Letters
            "a": 0x00, "b": 0x0B, "c": 0x08, "d": 0x02, "e": 0x0E, "f": 0x03,
            "g": 0x05, "h": 0x04, "i": 0x22, "j": 0x26, "k": 0x28, "l": 0x25,
            "m": 0x2E, "n": 0x2D, "o": 0x1F, "p": 0x23, "q": 0x0C, "r": 0x0F,
            "s": 0x01, "t": 0x11, "u": 0x20, "v": 0x09, "w": 0x0D, "x": 0x07,
            "y": 0x10, "z": 0x06,

            // Numbers
            "0": 0x1D, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15,
            "5": 0x17, "6": 0x16, "7": 0x1A, "8": 0x1C, "9": 0x19,

            // Special keys
            "return": 0x24, "enter": 0x24, "tab": 0x30, "space": 0x31,
            "delete": 0x33, "backspace": 0x33, "escape": 0x35, "esc": 0x35,

            // Arrow keys
            "left": 0x7B, "right": 0x7C, "down": 0x7D, "up": 0x7E,
            "arrowleft": 0x7B, "arrowright": 0x7C, "arrowdown": 0x7D, "arrowup": 0x7E,

            // Function keys
            "f1": 0x7A, "f2": 0x78, "f3": 0x63, "f4": 0x76, "f5": 0x60,
            "f6": 0x61, "f7": 0x62, "f8": 0x64, "f9": 0x65, "f10": 0x6D,
            "f11": 0x67, "f12": 0x6F,

            // Modifier keys (note: these are tricky, use with caution)
            "command": 0x37, "cmd": 0x37, "shift": 0x38, "option": 0x3A,
            "alt": 0x3A, "control": 0x3B, "ctrl": 0x3B,

            // Other keys
            "home": 0x73, "end": 0x77, "pageup": 0x74, "pagedown": 0x79,
            "forwarddelete": 0x75,
        ]

        return keyMap[keyName.lowercased()]
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