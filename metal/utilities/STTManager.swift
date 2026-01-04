import Foundation
import Speech
import AVFoundation
import SwiftUI
import AudioToolbox 

@MainActor
class STTManager: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var errorMsg: String? = nil
    @Published var permissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        requestPermission()
    }
    
    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.permissionStatus = authStatus
            }
        }
    }
    private func playListeningChime(chimeId: SystemSoundID = 1113) {
        AudioServicesPlaySystemSound(chimeId)
    }
    func startRecording() {
            // 1. Reset context
            errorMsg = nil
            transcribedText = ""
            
            // 2. Check availability
            guard let recognizer = speechRecognizer, recognizer.isAvailable else {
                self.errorMsg = "Speech recognizer is not available."
                return
            }
            
            // 3. Cancel previous
            if recognitionTask != nil {
                recognitionTask?.cancel()
                recognitionTask = nil
            }
            
            // 4. Create Request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                self.errorMsg = "Unable to create recognition request."
                return
            }
            recognitionRequest.shouldReportPartialResults = true
            
            // --- FORCE ON-DEVICE RECOGNITION ---
            if #available(macOS 10.15, *) {
                recognitionRequest.requiresOnDeviceRecognition = true
            }
            // -----------------------------------
            
            // 5. Configure Audio
            let inputNode = audioEngine.inputNode
            
            // 6. Start Task
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    DispatchQueue.main.async {
                        self.transcribedText = result.bestTranscription.formattedString
                    }
                }
                
                if let error = error {
                    print("STT Error: \(error.localizedDescription)")
                    self.stopRecording()
                }
            }
            
            // 7. Install Tap
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }
            
            // 8. Start Engine
            audioEngine.prepare()
            
            do {
                try audioEngine.start()
                self.playListeningChime()
                self.isRecording = true
            } catch {
                self.errorMsg = "Audio Engine Error: \(error.localizedDescription)"
            }
        }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        self.isRecording = false
        self.playListeningChime(chimeId: 1114)
    }
    
    func toggle() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
}
