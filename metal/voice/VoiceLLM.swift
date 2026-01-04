import Foundation

// MARK: - Gemini API Request Models (Voice)
private struct VoiceGeminiRequestPart: Codable {
    let text: String
}

private struct VoiceGeminiRequestContent: Codable {
    let role: String
    let parts: [VoiceGeminiRequestPart]
}

private struct VoiceGeminiRequestBody: Codable {
    let contents: [VoiceGeminiRequestContent]
}

// MARK: - Gemini API Response Models (Voice)
private struct VoiceGeminiCandidate: Codable {
    let content: VoiceGeminiContent
}

private struct VoiceGeminiContent: Codable {
    let parts: [VoiceGeminiPart]
}

private struct VoiceGeminiPart: Codable {
    let text: String?
}

private struct VoiceGeminiResponse: Codable {
    let candidates: [VoiceGeminiCandidate]?
}

// MARK: - Voice API Client
class VoiceGeminiApi {
    private let modelName: String
    private let maxRetry: Int
    private let apiKey: String

    private let session: URLSession
    private let decoder: JSONDecoder

    init(modelName: String = "gemini-3-flash-preview", apiKey: String, maxRetry: Int = 3) {
        self.modelName = modelName
        self.apiKey = apiKey
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
            return try await self.performGeminiApiCall(messages: messages)
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
    private func performGeminiApiCall(messages: [GeminiMessage]) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        // Map to Gemini API Format
        let geminiContents = messages.map { msg in
            return VoiceGeminiRequestContent(
                role: msg.role.rawValue,
                parts: msg.parts.compactMap { part in
                    switch part {
                    case .text(let t): return VoiceGeminiRequestPart(text: t)
                    }
                }
            )
        }

        let payload = VoiceGeminiRequestBody(contents: geminiContents)
        let jsonData = try JSONEncoder().encode(payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No body"
            print("VoiceGeminiApi: API Error \(httpResponse.statusCode): \(errorBody)")
            throw URLError(.badServerResponse)
        }

        // Parse Gemini Response
        let geminiResponse = try decoder.decode(VoiceGeminiResponse.self, from: data)

        guard let candidate = geminiResponse.candidates?.first,
              let textPart = candidate.content.parts.first?.text else {
            throw URLError(.cannotDecodeContentData)
        }

        return textPart
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
