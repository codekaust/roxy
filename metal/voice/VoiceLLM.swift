//
//  VoiceGeminiApi.swift
//  metal
//
//  Created by Ayush on 26/12/25.
//

import Foundation

// MARK: - Voice Proxy Models (Private & Separate)
// We duplicate these so this file is fully independent of the main GeminiApi.
private struct VoiceProxyRequestPart: Codable {
    let text: String
}

private struct VoiceProxyRequestMessage: Codable {
    let role: String
    let parts: [VoiceProxyRequestPart]
}

private struct VoiceProxyRequestBody: Codable {
    let modelName: String
    let messages: [VoiceProxyRequestMessage]
}

// MARK: - Voice API Client
class VoiceGeminiApi {
    private let modelName: String
    private let maxRetry: Int
    
    // --- CONFIGURATION FOR VOICE ---
    // You can change these independently of the main agent
    private let proxyUrl = "https://us-central1-panda-465116.cloudfunctions.net/gemini-proxy-service"
    private let proxyKey = "ayushissupercoolpersonandifyouknowthiskeyyouareabeliever"
    // -------------------------------
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(modelName: String = "gemini-2.5-flash", maxRetry: Int = 2) {
        self.modelName = modelName
        self.maxRetry = maxRetry
        
        let config = URLSessionConfiguration.default
        // Voice needs to be snappy; we set a shorter timeout than the main agent
        config.timeoutIntervalForRequest = 15 // 15 seconds limit for voice
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
    }
    
    /// Generic Generation Function
    func generate<T: Codable>(messages: [GeminiMessage]) async -> T? {
        let jsonResponse = await retryWithBackoff(times: maxRetry) {
            return try await self.performProxyApiCall(messages: messages)
        }
        
        guard let jsonString = jsonResponse else {
            print("VoiceGeminiApi: Failed to get response after \(maxRetry) retries.")
            return nil
        }
        
        do {
            guard let data = jsonString.data(using: .utf8) else { return nil }
            return try decoder.decode(T.self, from: data)
        } catch {
            print("VoiceGeminiApi: JSON Parsing Error: \(error)")
            // print("Raw: \(jsonString)")
            return nil
        }
    }
    
    // MARK: - Network Logic
    private func performProxyApiCall(messages: [GeminiMessage]) async throws -> String {
        guard let url = URL(string: proxyUrl) else { throw URLError(.badURL) }
        
        // Map to Voice DTOs
        let proxyMessages = messages.map { msg in
            VoiceProxyRequestMessage(
                role: msg.role.rawValue,
                parts: msg.parts.compactMap { part in
                    switch part {
                    case .text(let t): return VoiceProxyRequestPart(text: t)
                    }
                }
            )
        }
        
        let payload = VoiceProxyRequestBody(modelName: modelName, messages: proxyMessages)
        let jsonData = try JSONEncoder().encode(payload)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(proxyKey, forHTTPHeaderField: "X-API-Key")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return responseString
    }
    
    private func retryWithBackoff<T>(times: Int, operation: () async throws -> T) async -> T? {
        var currentDelay: UInt64 = 500_000_000 // Start with 0.5s for voice
        
        for attempt in 1...times {
            do {
                return try await operation()
            } catch {
                print("VoiceGeminiApi: Attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt == times { return nil }
                try? await Task.sleep(nanoseconds: currentDelay)
                currentDelay *= 2
            }
        }
        return nil
    }
}
