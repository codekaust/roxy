//
//  TTSManager.swift
//  metal
//
//  Created by Ayush on 23/12/25.
//

import Foundation
import AVFoundation // Replaces AppKit for TTS
import CryptoKit

class TTSManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    
    static let shared = TTSManager()
    private let defaultApiKey = "AIzaSyBNbLbAEiBwJ5wUAroXJAAN0lhoHicVYjs"
    // --- Configuration ---
    @Published var useCloudTTS: Bool {
        didSet { UserDefaults.standard.set(useCloudTTS, forKey: "useCloudTTS") }
    }
    @Published var googleApiKey: String {
        didSet { UserDefaults.standard.set(googleApiKey, forKey: "googleApiKey") }
    }
    
    private var speechContinuation: CheckedContinuation<Void, Never>?

    // --- Native Engine (Modern) ---
    private let nativeSynth = AVSpeechSynthesizer()
    
    // --- Cloud / Audio Engine ---
    private var audioPlayer: AVAudioPlayer?
    
    // --- State Management ---
    private var stopRequested = false
    private var currentCaptionId: UUID?
    
    // --- Caching ---
    private let fileManager = FileManager.default
    private var cacheDirectory: URL?
    
    override init() {
        self.useCloudTTS = UserDefaults.standard.object(forKey: "useCloudTTS") == nil ? true : UserDefaults.standard.bool(forKey: "useCloudTTS")
        let savedKey = UserDefaults.standard.string(forKey: "googleApiKey")
        // self.googleApiKey = UserDefaults.standard.string(forKey: "googleApiKey") ?? ""
        if let key = savedKey, !key.isEmpty {
            // User has manually entered a key previously
            self.googleApiKey = key
        } else {
            // First run (or user cleared it): Use your hardcoded default
            self.googleApiKey = defaultApiKey
        }
        super.init()
        nativeSynth.delegate = self
        setupCache()
    }
    
    // MARK: - Public API
    
    func speak(_ text: String) async {
        stop() // Stop existing playback
        stopRequested = false
        // --- 🔍 DEBUG START 🔍 ---
        print("--------------------------------------------------")
        print("TTS DEBUG: Cloud Enabled = \(useCloudTTS)")
        print("TTS DEBUG: API Key Length = \(googleApiKey.count)")
        print("TTS DEBUG: API Key Start  = \(googleApiKey.prefix(6))...")
        // -------------------------------------------------------
        if useCloudTTS && !googleApiKey.isEmpty {
            print("Speaking using the clouf TTS engine...")
            await speakCloud(text)
        } else {
            print("Speaking natibly... using the built-in macOS TTS engine...")
            await speakNative(text)
        }
    }
    // MARK: - Audio Helpers
    private func addWavHeader(to pcmData: Data, sampleRate: Int32 = 24000) -> Data {
        let headerSize = 44
        let dataSize = Int32(pcmData.count)
        let fileSize = dataSize + Int32(headerSize) - 8
        
        var header = Data()
        
        // 1. RIFF chunk descriptor
        header.append(contentsOf: "RIFF".utf8)
        header.append(withUnsafeBytes(of: fileSize) { Data($0) })
        header.append(contentsOf: "WAVE".utf8)
        
        // 2. fmt sub-chunk
        header.append(contentsOf: "fmt ".utf8)
        header.append(withUnsafeBytes(of: Int32(16)) { Data($0) }) // Subchunk1Size (16 for PCM)
        header.append(withUnsafeBytes(of: Int16(1)) { Data($0) })  // AudioFormat (1 = PCM)
        header.append(withUnsafeBytes(of: Int16(1)) { Data($0) })  // NumChannels (1 = Mono)
        header.append(withUnsafeBytes(of: sampleRate) { Data($0) }) // SampleRate
        
        let byteRate = sampleRate * 1 * 16 / 8 // SampleRate * NumChannels * BitsPerSample / 8
        header.append(withUnsafeBytes(of: byteRate) { Data($0) })
        
        let blockAlign = Int16(1 * 16 / 8) // NumChannels * BitsPerSample / 8
        header.append(withUnsafeBytes(of: blockAlign) { Data($0) })
        
        header.append(withUnsafeBytes(of: Int16(16)) { Data($0) }) // BitsPerSample
        
        // 3. data sub-chunk
        header.append(contentsOf: "data".utf8)
        header.append(withUnsafeBytes(of: dataSize) { Data($0) })
        
        return header + pcmData
    }
    func stop() {
        stopRequested = true
        
        // Stop Cloud
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        
        // Stop Native (Immediate)
        if nativeSynth.isSpeaking {
            nativeSynth.stopSpeaking(at: .immediate)
        }
        
        // Clear Caption
        if let id = currentCaptionId {
            Task { @MainActor in
                OverlayManager.shared.hideCaption(id: id)
            }
        }
        speechContinuation?.resume() 
        speechContinuation = nil
    }
    
    // MARK: - Native Logic (AVSpeechSynthesizer)
    
    private func speakNative(_ text: String) async {
        // Show Caption
        await MainActor.run {
            self.currentCaptionId = OverlayManager.shared.showCaption(text: text)
        }
        
        await withCheckedContinuation { continuation in
            self.speechContinuation = continuation
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = 0.5 // Standard rate
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            nativeSynth.speak(utterance)
        }
    }
    
    // AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if let id = currentCaptionId {
            Task { @MainActor in
                OverlayManager.shared.hideCaption(id: id)
            }
        }
        // --- NEW: Unlock the waiter ---
        speechContinuation?.resume()
        speechContinuation = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if let id = currentCaptionId {
            Task { @MainActor in
                OverlayManager.shared.hideCaption(id: id)
            }
        }
        // --- NEW: Unlock the waiter ---
        speechContinuation?.resume()
        speechContinuation = nil
    }
    
    // MARK: - Cloud Logic (Smart Queue)
    
    private func speakCloud(_ text: String) async {
        let chunks = chunkTextIntoSentences(text: text, maxWordsPerChunk: 50)
        if chunks.isEmpty { return }
        print("TTS: (speakCloud) Chunks Count = \(chunks.count)")
        // 1. Process First Chunk Immediately
        let firstChunk = chunks[0]
        
        await MainActor.run {
            self.currentCaptionId = OverlayManager.shared.showCaption(text: firstChunk)
        }
        
        guard let firstAudio = await getAudioData(text: firstChunk) else {
            print("TTS: Failed to get first chunk, falling back to native.")
            await speakNative(text)
            return
        }
        
        // 2. Start Background Prefetch
        let queue = AsyncQueue<Data>()
        Task.detached { [weak self] in
            for i in 1..<chunks.count {
                if self?.stopRequested == true { break }
                if let audio = await self?.getAudioData(text: chunks[i]) {
                    await queue.enqueue(audio)
                }
            }
            await queue.finish()
        }
        
        // 3. Play First Chunk
        await playAudioData(firstAudio)
        
        // 4. Play Remaining Queue
        var chunkIndex = 1
        for await audioData in queue {
            if stopRequested { break }
            
            if chunkIndex < chunks.count {
                let nextText = chunks[chunkIndex]
                await MainActor.run {
                    if let oldId = self.currentCaptionId { OverlayManager.shared.hideCaption(id: oldId) }
                    self.currentCaptionId = OverlayManager.shared.showCaption(text: nextText)
                }
            }
            
            await playAudioData(audioData)
            chunkIndex += 1
        }
        
        await MainActor.run {
            if let id = self.currentCaptionId { OverlayManager.shared.hideCaption(id: id) }
        }
    }
    
    // MARK: - Audio Playback
    
    private func playAudioData(_ data: Data) async {
        return await withCheckedContinuation { continuation in
            do {
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                
                Task {
                    while self.audioPlayer?.isPlaying == true {
                        if self.stopRequested {
                            self.audioPlayer?.stop()
                            break
                        }
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    continuation.resume()
                }
            } catch {
                print("TTS: Audio Player Error: \(error)")
                continuation.resume()
            }
        }
    }
    
    // MARK: - Networking & Caching
    
    private func getAudioData(text: String) async -> Data? {
        if let cached = loadFromCache(text: text) { return cached }
        guard let data = await fetchGoogleTTS(text: text) else { return nil }
        saveToCache(text: text, data: data)
        return data
    }
    
    private func fetchGoogleTTS(text: String) async -> Data? {
        let urlString = "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(googleApiKey)"
        guard let url = URL(string: urlString) else { return nil }
        print("TTS: (fetchGoogleTTS) URL = \(urlString)")
        
        let json: [String: Any] = [
            "input": ["text": text],
            "voice": [
                "languageCode": "en-US",
                "name": "en-US-Journey-F"
            ],
            "audioConfig": [
                "audioEncoding": "LINEAR16",
                "sampleRateHertz": 24000
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let audioContent = jsonResponse["audioContent"] as? String,
               let rawPcmData = Data(base64Encoded: audioContent) {
                let wavData = addWavHeader(to: rawPcmData, sampleRate: 24000)
                return wavData
            }
        } catch {
            print("TTS: Network error: \(error)")
        }
        return nil
    }
    
    // MARK: - Cache Helpers
    
    private func setupCache() {
        if let cache = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDirectory = cache.appendingPathComponent("tts_cache")
            try? fileManager.createDirectory(at: cacheDirectory!, withIntermediateDirectories: true)
        }
    }
    
    private func getCacheURL(text: String) -> URL? {
        guard let dir = cacheDirectory else { return nil }
        let filename = SHA256.hash(data: text.data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined() + ".mp3"
        return dir.appendingPathComponent(filename)
    }
    
    private func loadFromCache(text: String) -> Data? {
        guard let url = getCacheURL(text: text) else { return nil }
        return try? Data(contentsOf: url)
    }
    
    private func saveToCache(text: String, data: Data) {
        guard let url = getCacheURL(text: text) else { return }
        try? data.write(to: url)
    }
    
    // MARK: - Chunking
    private func chunkTextIntoSentences(text: String, maxWordsPerChunk: Int) -> [String] {
        if text.count <= 250 { return [text] }
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var chunks: [String] = []
        var currentChunk = ""
        var currentWordCount = 0
        
        for sentence in sentences {
            let words = sentence.components(separatedBy: .whitespaces)
            let count = words.count
            if currentWordCount + count > maxWordsPerChunk && !currentChunk.isEmpty {
                chunks.append(currentChunk.trimmingCharacters(in: .whitespaces))
                currentChunk = ""
                currentWordCount = 0
            }
            currentChunk += sentence + ". "
            currentWordCount += count
        }
        if !currentChunk.isEmpty { chunks.append(currentChunk.trimmingCharacters(in: .whitespaces)) }
        return chunks
    }
}

// MARK: - Async Queue Helper
actor AsyncQueue<Element>: AsyncSequence, AsyncIteratorProtocol {
    private var elements: [Element] = []
    private var continuations: [CheckedContinuation<Element?, Never>] = []
    private var isFinished = false
    
    func enqueue(_ element: Element) {
        if !continuations.isEmpty {
            continuations.removeFirst().resume(returning: element)
        } else {
            elements.append(element)
        }
    }
    
    func finish() {
        isFinished = true
        continuations.forEach { $0.resume(returning: nil) }
        continuations.removeAll()
    }
    
    // MARK: - AsyncSequence Conformance
    
    // This must be nonisolated to satisfy the synchronous protocol requirement
    nonisolated func makeAsyncIterator() -> AsyncQueue {
        return self
    }
    
    // This satisfies AsyncIteratorProtocol
    func next() async -> Element? {
        if !elements.isEmpty {
            return elements.removeFirst()
        }
        if isFinished {
            return nil
        }
        return await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }
}
