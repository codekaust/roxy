import Foundation

// MARK: - Gemini API Request Models
private struct GeminiRequestPart: Codable {
    let text: String
}

private struct GeminiRequestContent: Codable {
    let role: String
    let parts: [GeminiRequestPart]
}

private struct GeminiRequestBody: Codable {
    let contents: [GeminiRequestContent]
}

// MARK: - Gemini API Response Models
private struct GeminiCandidate: Codable {
    let content: GeminiContent
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String?
}

private struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
}

// MARK: - Gemini API Client
class GeminiApi {
    private let modelName: String
    private let maxRetry: Int
    private let apiKey: String

    private let session: URLSession
    private let decoder: JSONDecoder

    init(modelName: String, apiKey: String, maxRetry: Int = 3) {
        self.modelName = modelName
        self.apiKey = apiKey
        self.maxRetry = maxRetry

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60 // 60 seconds
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
    }

    /// Primary Entry Point: Generates AgentOutput from Gemini API
    func generateAgentOutput(messages: [GeminiMessage]) async -> AgentOutput? {
        // Retry Wrapper
        let jsonResponse = await retryWithBackoff(times: maxRetry) {
            return try await self.performGeminiApiCall(messages: messages)
        }

        guard let jsonString = jsonResponse else {
            LogManager.shared.error("GeminiApi: Failed to get response after \(maxRetry) retries.")
            return nil
        }

        // Parse the JSON String into AgentOutput
        do {
            LogManager.shared.debug("GeminiApi: Received JSON length: \(jsonString.count)")

            guard let data = jsonString.data(using: .utf8) else { return nil }

            let output = try decoder.decode(AgentOutput.self, from: data)
            return output

        } catch {
            LogManager.shared.error("GeminiApi: JSON Parsing Error: \(error)")
            LogManager.shared.debug("GeminiApi: Raw Response: \(jsonString)")
            return nil
        }
    }

    /// Performs the actual Network Request to Gemini API
    private func performGeminiApiCall(messages: [GeminiMessage]) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        // 1. Map Internal Messages -> Gemini API Format
        let geminiContents = messages.map { msg in
            return GeminiRequestContent(
                role: msg.role.rawValue,
                parts: msg.parts.compactMap { part in
                    switch part {
                    case .text(let t): return GeminiRequestPart(text: t)
                    }
                }
            )
        }

        // 2. Build Request Body
        let payload = GeminiRequestBody(contents: geminiContents)
        let jsonData = try JSONEncoder().encode(payload)

        // 3. Configure Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // 4. Execute
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No body"
            LogManager.shared.error("GeminiApi: API Error \(httpResponse.statusCode): \(errorBody)")
            throw URLError(.badServerResponse)
        }

        // 5. Parse Gemini Response
        let geminiResponse = try decoder.decode(GeminiResponse.self, from: data)

        guard let candidate = geminiResponse.candidates?.first,
              let textPart = candidate.content.parts.first?.text else {
            throw URLError(.cannotDecodeContentData)
        }

        return textPart
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
                LogManager.shared.warning("GeminiApi: Attempt \(attempt)/\(times) failed: \(error.localizedDescription)")

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
