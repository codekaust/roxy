//
//  GeminiApi.swift
//  metal
//
//  Created by Ayush on 22/12/25.
//

import Foundation

// MARK: - Proxy Request Models (Internal)
// These match the JSON structure your Cloud Function expects
private struct ProxyRequestPart: Codable {
    let text: String
}

private struct ProxyRequestMessage: Codable {
    let role: String
    let parts: [ProxyRequestPart]
}

private struct ProxyRequestBody: Codable {
    let modelName: String
    let messages: [ProxyRequestMessage]
}

// MARK: - Gemini API Client
class GeminiApi {
    private let modelName: String
    private let maxRetry: Int
    
    // Hardcoded for now, or load from a Config/plist
    private let proxyUrl = "https://us-central1-panda-465116.cloudfunctions.net/gemini-proxy-service"
    private let proxyKey = "ayushissupercoolpersonandifyouknowthiskeyyouareabeliever"
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(modelName: String, maxRetry: Int = 3) {
        self.modelName = modelName
        self.maxRetry = maxRetry
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60 // 60 seconds
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        // Allow flexible JSON parsing similar to Kotlin's 'ignoreUnknownKeys'
        // Swift ignores unknown keys by default unless you explicitly define them in CodingKeys
    }
    
    /// Primary Entry Point: Generates AgentOutput from the Proxy
    func generateAgentOutput(messages: [GeminiMessage]) async -> AgentOutput? {
        // Retry Wrapper
        let jsonResponse = await retryWithBackoff(times: maxRetry) {
            return try await self.performProxyApiCall(messages: messages)
        }
        
        guard let jsonString = jsonResponse else {
            print("GeminiApi: Failed to get response after \(maxRetry) retries.")
            return nil
        }
        
        // Parse the JSON String into AgentOutput
        do {
            print("GeminiApi: Received JSON length: \(jsonString.count)")
            
            // The proxy returns a String body. We need to convert that String -> Data -> Object
            guard let data = jsonString.data(using: .utf8) else { return nil }
            
            let output = try decoder.decode(AgentOutput.self, from: data)
            return output
            
        } catch {
            print("GeminiApi: JSON Parsing Error: \(error)")
            print("GeminiApi: Raw Response: \(jsonString)")
            return nil
        }
    }
    
    /// Performs the actual Network Request
    private func performProxyApiCall(messages: [GeminiMessage]) async throws -> String {
        guard let url = URL(string: proxyUrl) else {
            throw URLError(.badURL)
        }
        
        // 1. Map Internal Messages -> Proxy DTOs
        let proxyMessages = messages.map { msg in
            ProxyRequestMessage(
                role: msg.role.rawValue,
                parts: msg.parts.compactMap { part in
                    switch part {
                    case .text(let t): return ProxyRequestPart(text: t)
                    }
                }
            )
        }
        
        // 2. Build Request Body
        let payload = ProxyRequestBody(modelName: modelName, messages: proxyMessages)
        let jsonData = try JSONEncoder().encode(payload)
        
        // 3. Configure Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(proxyKey, forHTTPHeaderField: "X-API-Key")
        
        // 4. Execute
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No body"
            print("GeminiApi: Proxy Error \(httpResponse.statusCode): \(errorBody)")
            throw URLError(.badServerResponse)
        }
        
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return responseString
    }
    
    /// Exponential Backoff Retry Logic
    private func retryWithBackoff<T>(
        times: Int,
        initialDelay: UInt64 = 1_000_000_000, // 1 second
        maxDelay: UInt64 = 16_000_000_000,   // 16 seconds
        factor: Double = 2.0,
        operation: () async throws -> T
    ) async -> T? {
        
        var currentDelay = initialDelay
        
        for attempt in 1...times {
            do {
                return try await operation()
            } catch {
                print("GeminiApi: Attempt \(attempt)/\(times) failed: \(error.localizedDescription)")
                
                if attempt == times {
                    return nil // All retries failed
                }
                
                // Wait
                try? await Task.sleep(nanoseconds: currentDelay)
                
                // Calculate next delay
                let next = Double(currentDelay) * factor
                currentDelay = min(UInt64(next), maxDelay)
            }
        }
        return nil
    }
}
