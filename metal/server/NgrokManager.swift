import Foundation

// MARK: - ngrok Manager

/// Manages ngrok subprocess for creating public tunnel
class NgrokManager {
    private var process: Process?
    private var outputPipe: Pipe?
    private var outputHandle: FileHandle?

    /// Start ngrok tunnel on specified port
    /// - Parameters:
    ///   - port: Local port to tunnel
    ///   - completion: Callback with public URL or error
    func start(port: UInt16, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if ngrok is installed
        let ngrokPath = findNgrokPath()
        guard let path = ngrokPath else {
            completion(.failure(NgrokError.notInstalled))
            return
        }

        // Setup process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["http", "\(port)", "--log=stdout"]

        // Setup output pipe
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        self.process = process
        self.outputPipe = pipe
        self.outputHandle = pipe.fileHandleForReading

        // Read output asynchronously
        var outputBuffer = ""
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            if let output = String(data: data, encoding: .utf8) {
                outputBuffer += output

                // Try to parse URL from output
                if let url = self?.parseNgrokURL(from: outputBuffer) {
                    LogManager.shared.info("ngrok tunnel established: \(url)")
                    completion(.success(url))

                    // Stop reading once we have the URL
                    handle.readabilityHandler = nil
                }
            }
        }

        // Handle process termination
        process.terminationHandler = { process in
            LogManager.shared.warning("ngrok process terminated with code: \(process.terminationStatus)")
        }

        // Start process
        do {
            try process.run()
            LogManager.shared.info("Starting ngrok on port \(port)...")

            // Timeout after 10 seconds if URL not found
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                if self.process?.isRunning == true && outputBuffer.isEmpty {
                    LogManager.shared.warning("ngrok timeout - no URL found after 10 seconds")
                    completion(.failure(NgrokError.timeout))
                }
            }
        } catch {
            LogManager.shared.error("Failed to start ngrok: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    /// Stop ngrok process
    func stop() {
        outputHandle?.readabilityHandler = nil
        process?.terminate()
        process = nil
        outputPipe = nil
        outputHandle = nil
        LogManager.shared.info("ngrok stopped")
    }

    // MARK: - Private Helpers

    /// Find ngrok executable path
    private func findNgrokPath() -> String? {
        let possiblePaths = [
            "/usr/local/bin/ngrok",
            "/opt/homebrew/bin/ngrok",
            "/usr/bin/ngrok",
            ProcessInfo.processInfo.environment["HOME"]?.appending("/.local/bin/ngrok")
        ].compactMap { $0 }

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        return nil
    }

    /// Parse ngrok public URL from output
    /// Handles both text and JSON output formats
    private func parseNgrokURL(from output: String) -> String? {
        // Try to find URL in various formats
        // Format 1: "url=https://abc123.ngrok.io"
        if let urlMatch = output.range(of: #"url=https://[^\s]+"#, options: .regularExpression) {
            let urlString = String(output[urlMatch])
            return urlString.replacingOccurrences(of: "url=", with: "")
        }

        // Format 2: JSON with "public_url" field
        if let jsonMatch = output.range(of: #""public_url":"https://[^"]+""#, options: .regularExpression) {
            let jsonString = String(output[jsonMatch])
            if let url = jsonString.components(separatedBy: "\":\"").last?.replacingOccurrences(of: "\"", with: "") {
                return url
            }
        }

        // Format 3: Simple text "Forwarding  https://abc123.ngrok.io"
        if let forwardMatch = output.range(of: #"Forwarding\s+https://[^\s]+"#, options: .regularExpression) {
            let forwardString = String(output[forwardMatch])
            if let url = forwardString.components(separatedBy: .whitespaces).last {
                return url
            }
        }

        return nil
    }
}

// MARK: - Errors

enum NgrokError: LocalizedError {
    case notInstalled
    case timeout
    case authFailed

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "ngrok not found. Install with: brew install ngrok"
        case .timeout:
            return "ngrok tunnel timeout - check your internet connection"
        case .authFailed:
            return "ngrok authentication failed. Run: ngrok authtoken YOUR_TOKEN"
        }
    }
}
