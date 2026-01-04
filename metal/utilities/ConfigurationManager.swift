import Foundation
import Security

enum APIKeyType: String {
    case geminiLLM = "gemini_llm_api_key"
    case googleTTS = "google_tts_api_key"
    case googleSTT = "google_stt_api_key"
}

class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()

    private let keychainService = "com.roxy.metal"

    @Published var hasGeminiKey: Bool = false
    @Published var hasTTSKey: Bool = false
    @Published var hasSTTKey: Bool = false

    private init() {
        updateKeyStatus()
    }

    // MARK: - Public API

    func getAPIKey(for type: APIKeyType) -> String? {
        // Priority: Keychain > .env file > empty
        if let keychainKey = getFromKeychain(type: type), !keychainKey.isEmpty {
            return keychainKey
        }

        if let envKey = getFromEnvFile(type: type), !envKey.isEmpty {
            return envKey
        }

        return nil
    }

    func setAPIKey(_ key: String, for type: APIKeyType) -> Bool {
        let success = saveToKeychain(key: key, type: type)
        updateKeyStatus()
        return success
    }

    func deleteAPIKey(for type: APIKeyType) -> Bool {
        let success = deleteFromKeychain(type: type)
        updateKeyStatus()
        return success
    }

    func updateKeyStatus() {
        hasGeminiKey = getAPIKey(for: .geminiLLM) != nil
        hasTTSKey = getAPIKey(for: .googleTTS) != nil
        hasSTTKey = getAPIKey(for: .googleSTT) != nil
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(key: String, type: APIKeyType) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }

        // Delete existing key first
        _ = deleteFromKeychain(type: type)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: type.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            LogManager.shared.info("ConfigurationManager: Successfully saved \(type.rawValue) to Keychain")
            return true
        } else {
            LogManager.shared.error("ConfigurationManager: Failed to save \(type.rawValue) to Keychain: \(status)")
            return false
        }
    }

    private func getFromKeychain(type: APIKeyType) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: type.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    private func deleteFromKeychain(type: APIKeyType) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: type.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - .env File Operations

    private func getFromEnvFile(type: APIKeyType) -> String? {
        guard let projectPath = findProjectRoot() else { return nil }
        let envPath = projectPath.appendingPathComponent(".env")

        guard FileManager.default.fileExists(atPath: envPath.path),
              let contents = try? String(contentsOf: envPath, encoding: .utf8) else {
            return nil
        }

        let envVarName: String
        switch type {
        case .geminiLLM:
            envVarName = "GEMINI_API_KEY"
        case .googleTTS:
            envVarName = "GOOGLE_TTS_API_KEY"
        case .googleSTT:
            envVarName = "GOOGLE_STT_API_KEY"
        }

        // Parse .env file
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") || trimmed.isEmpty { continue }

            let parts = trimmed.components(separatedBy: "=")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1...].joined(separator: "=")
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

                if key == envVarName {
                    return value
                }
            }
        }

        return nil
    }

    private func findProjectRoot() -> URL? {
        let currentPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        // Try to find .env file in common locations
        let searchPaths = [
            currentPath,
            URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
            Bundle.main.bundleURL.deletingLastPathComponent()
        ]

        for path in searchPaths {
            let envPath = path.appendingPathComponent(".env")
            if FileManager.default.fileExists(atPath: envPath.path) {
                return path
            }
        }

        return searchPaths.first
    }
}
