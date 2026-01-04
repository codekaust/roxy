import AppKit
import Carbon

class HotkeyManager: ObservableObject {
    private var lastCommandPressTime: TimeInterval = 0
    private let doubleTapThreshold: TimeInterval = 0.3 // 300ms window
    
    // Callback to trigger when double tap is detected
    var onDoubleTap: (() -> Void)?
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Global monitor for modifier flags (Command, Shift, Control, etc.)
        // This works even when the app is in the background, provided the app is trusted.
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        // Also add local monitor so it works when the app is focused
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        
        print("HotkeyManager: Started monitoring for Cmd Double Tap")
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        // user selected command key
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command) {
            // Key Down (Command Pressed)
            let now = Date().timeIntervalSince1970
            
            // Check time difference
            if now - lastCommandPressTime < doubleTapThreshold {
                print("HotkeyManager: Double Tap Detected!")
                onDoubleTap?()
                // Reset to avoid triple-tap triggering it twice immediately
                lastCommandPressTime = 0
            } else {
                lastCommandPressTime = now
            }
        }
        
        // --- ADDED: Fn Key Logic ---
        // Fn key usually has the .function flag.
        // Important: flagsChanged fires on both DOWN and UP.
        // We need to check if the flag is PRESENT (Down) or ABSENT (Up).
        
        if event.modifierFlags.contains(.function) {
            // Fn is currently pressed
            if !isFnPressed {
                isFnPressed = true
                print("HotkeyManager: Fn Key Down")
                onFnDown?()
            }
        } else {
            // Fn is NOT pressed (but we might have just released it)
            if isFnPressed {
                isFnPressed = false
                print("HotkeyManager: Fn Key Up") // Typo fix: "Fn Key Up"
                onFnUp?()
            }
        }
    }
    
    // Track Fn state to distinguish press vs release
    private var isFnPressed = false
    
    // Callbacks for Fn Key
    var onFnDown: (() -> Void)?
    var onFnUp: (() -> Void)?
}
