//
//  metalApp.swift
//  metal
//
//  Created by Ayush on 20/12/25.
//

import SwiftUI
import AudioToolbox
import Combine


@MainActor
class AppState: ObservableObject {
    let voiceAgent = ConversationalAgent()
    let hotkeyManager = HotkeyManager()
    
    // Dedicated STT for holding Fn to talk
    let dictationSTT = STTManager()
    
    // Live Typing State
    private var liveTypingCancellable: AnyCancellable?
    private var previousText: String = ""
    
    init() {
        print("AppState: Initializing...")
        
        // 1. Double Tap Cmd -> Toggle Voice Agent
        hotkeyManager.onDoubleTap = { [weak self] in
            print("AppState: Double tap detected, toggling session")
            DispatchQueue.main.async {
                self?.voiceAgent.toggleSession()
            }
        }
        
        // 2. Hold Fn -> Dictation
        hotkeyManager.onFnDown = { [weak self] in
            print("AppState: Fn Down -> Start Dictation")
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Reset state
                self.previousText = ""
                
                // Start Recording
                self.dictationSTT.startRecording()
                
                // Start Observing for Live Typing
                self.liveTypingCancellable = self.dictationSTT.$transcribedText
                    .dropFirst() // Drop initial empty
                    .removeDuplicates()
                    .sink { [weak self] newText in
                        guard let self = self else { return }
                        self.handleLiveTyping(newText: newText)
                    }
            }
        }
        
        hotkeyManager.onFnUp = { [weak self] in
            print("AppState: Fn Up -> Schedule Stop")
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Wait 300ms
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                // Stop Recording (Silent)
                self.dictationSTT.stopRecording() // Suppress "End" chime
                
                // Cleanup
                self.liveTypingCancellable?.cancel()
                self.liveTypingCancellable = nil
                
                // If NO text was typed (e.g. silence), maybe play error?
                // But if we were live typing, we already typed.
                // We should check if we typed anything.
                if self.previousText.isEmpty {
                    print("AppState: No text detected during dictation. Error Chime.")
                    // Play error sound (SystemSoundID 1053)
                    AudioServicesPlaySystemSound(1053)
                }
            }
        }
        
        // Ensure voice agent is ready
        print("AppState: Voice Agent ready")
    }
    
    // MARK: - Live Typing Logic
    private func handleLiveTyping(newText: String) {
        // Ensure we are focused
        guard InputManager.shared.isTextFieldFocused() else {
            // If lost focus, maybe stop? Or just ignore?
            return
        }
        
        // Calculate Diff
        // We have 'previousText' (what is currently on screen from us)
        // We have 'newText' (what STT thinks the WHOLE phrase is now)
        
        // 1. Find common prefix
        let commonPrefix = newText.commonPrefix(with: previousText)
        
        // 2. Determine how much to delete
        // If previousText was "Hello World" and now is "Hello", delete 6 chars (" World")
        let deleteCount = previousText.count - commonPrefix.count
        
        if deleteCount > 0 {
            InputManager.shared.delete(count: deleteCount)
        }
        
        // 3. Determine what to append
        let appendText = String(newText.dropFirst(commonPrefix.count))
        
        if !appendText.isEmpty {
            InputManager.shared.type(appendText)
        }
        
        // 4. Update state
        self.previousText = newText
    }
}

@main
struct metalApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState.voiceAgent)
        }
    }
}
