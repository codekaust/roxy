import SwiftUI

struct SettingsView: View {
    @AppStorage("showDebugOverlay") private var showDebugOverlay = true
    @AppStorage("autoRefreshOverlay") private var autoRefreshOverlay = false
    @AppStorage("enableWebServer") private var enableWebServer = false
    @AppStorage("preferenceLearningEnabled") private var preferenceLearningEnabled = true
    @ObservedObject private var ttsManager = TTSManager.shared
    @ObservedObject private var permissionManager = PermissionManager.shared
    @ObservedObject private var configManager = ConfigurationManager.shared
    @ObservedObject private var webServer = WebServer.shared
    @State private var showPermissionView = false

    @State private var geminiAPIKey: String = ""
    @State private var ttsAPIKey: String = ""
    @State private var sttAPIKey: String = ""
    @State private var showAPIKeys: Bool = false
    @State private var saveStatus: String = ""

    var body: some View {
        Form {
            Section(header: Text("API Keys")
                .foregroundColor(RoxyColors.neonCyan)
                .font(RoxyFonts.headline)) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configure your API keys for different services")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(configManager.hasGeminiKey ? .green : .orange)
                            Text("Gemini LLM API Key")
                            Spacer()
                            Text(configManager.hasGeminiKey ? "✓ Configured" : "✗ Required")
                                .font(.caption)
                                .foregroundColor(configManager.hasGeminiKey ? .green : .orange)
                        }

                        HStack {
                            if showAPIKeys {
                                SecureField("Enter Gemini API Key", text: $geminiAPIKey)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Text(configManager.hasGeminiKey ? "••••••••••••••••" : "Not configured")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Spacer()
                            }

                            Button(showAPIKeys ? "Hide" : "Edit") {
                                showAPIKeys.toggle()
                                if showAPIKeys {
                                    geminiAPIKey = configManager.getAPIKey(for: .geminiLLM) ?? ""
                                }
                            }
                            .buttonStyle(.bordered)

                            if showAPIKeys && !geminiAPIKey.isEmpty {
                                Button("Save") {
                                    if configManager.setAPIKey(geminiAPIKey, for: .geminiLLM) {
                                        saveStatus = "Gemini API key saved"
                                        showAPIKeys = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(configManager.hasTTSKey ? .green : .gray)
                            Text("Google TTS API Key")
                            Spacer()
                            Text(configManager.hasTTSKey ? "✓ Configured" : "Optional")
                                .font(.caption)
                                .foregroundColor(configManager.hasTTSKey ? .green : .gray)
                        }

                        HStack {
                            if showAPIKeys {
                                SecureField("Enter Google TTS API Key", text: $ttsAPIKey)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Text(configManager.hasTTSKey ? "••••••••••••••••" : "Not configured")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Spacer()
                            }

                            if showAPIKeys && !ttsAPIKey.isEmpty {
                                Button("Save") {
                                    if configManager.setAPIKey(ttsAPIKey, for: .googleTTS) {
                                        saveStatus = "TTS API key saved"
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mic")
                                .foregroundColor(configManager.hasSTTKey ? .green : .gray)
                            Text("Google STT API Key")
                            Spacer()
                            Text(configManager.hasSTTKey ? "✓ Configured" : "Optional")
                                .font(.caption)
                                .foregroundColor(configManager.hasSTTKey ? .green : .gray)
                        }

                        HStack {
                            if showAPIKeys {
                                SecureField("Enter Google STT API Key", text: $sttAPIKey)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Text(configManager.hasSTTKey ? "••••••••••••••••" : "Not configured")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Spacer()
                            }

                            if showAPIKeys && !sttAPIKey.isEmpty {
                                Button("Save") {
                                    if configManager.setAPIKey(sttAPIKey, for: .googleSTT) {
                                        saveStatus = "STT API key saved"
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    if !saveStatus.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(saveStatus)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 4)
                    }

                    Text("You can also configure API keys in a .env file at the project root")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }

            Section(header: Text("Permissions")
                .foregroundColor(RoxyColors.neonPurple)
                .font(RoxyFonts.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(permissionManager.accessibilityGranted ? .green : .orange)
                        Text("Accessibility")
                        Spacer()
                        Text(permissionManager.accessibilityGranted ? "✓ Granted" : "✗ Required")
                            .font(.caption)
                            .foregroundColor(permissionManager.accessibilityGranted ? .green : .orange)
                        if !permissionManager.accessibilityGranted {
                            Button("Grant") {
                                permissionManager.openSystemPreferences(for: .accessibility)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundColor(permissionManager.microphoneGranted ? .green : .orange)
                        Text("Microphone")
                        Spacer()
                        Text(permissionManager.microphoneGranted ? "✓ Granted" : "✗ Required")
                            .font(.caption)
                            .foregroundColor(permissionManager.microphoneGranted ? .green : .orange)
                        if !permissionManager.microphoneGranted {
                            Button("Grant") {
                                Task {
                                    await permissionManager.requestMicrophone()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Divider()

                    if !permissionManager.allPermissionsGranted {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Restart required after granting permissions")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }

                            HStack(spacing: 12) {
                                Button("Open Permission Manager") {
                                    showPermissionView = true
                                }
                                .buttonStyle(.bordered)

                                Button(action: {
                                    permissionManager.restartApp()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Restart App")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                            }
                        }
                        .padding(.top, 8)
                    } else {
                        Button("Open Permission Manager") {
                            showPermissionView = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Section(header: Text("Developer Tools")
                .foregroundColor(RoxyColors.neonOrange)
                .font(RoxyFonts.headline)) {
                Toggle(isOn: $showDebugOverlay) {
                    VStack(alignment: .leading) {
                        Text("Enable Debug Overlay")
                            .font(.headline)
                        Text("Draws red boxes around detected interactive elements.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                
                if showDebugOverlay {
                    Toggle("Auto-refresh every 5s", isOn: $autoRefreshOverlay)
                        .font(.subheadline)
                }
            }
            Section(header: Text("Voice Settings")
                .foregroundColor(RoxyColors.neonGreen)
                .font(RoxyFonts.headline)) {
                Toggle(isOn: $ttsManager.useCloudTTS) {
                    VStack(alignment: .leading) {
                        Text("Use Cloud TTS")
                            .font(.headline)
                        Text("High quality voice using Google Cloud Text-to-Speech (requires internet).")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Web Remote Control")
                .foregroundColor(RoxyColors.neonMagenta)
                .font(RoxyFonts.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    // Enable/Disable Toggle
                    Toggle(isOn: $enableWebServer) {
                        VStack(alignment: .leading) {
                            Text("Enable Web Remote Control")
                                .font(.headline)
                            Text("Access Roxy from any device via web browser")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: enableWebServer) { newValue in
                        if newValue {
                            Task {
                                do {
                                    try await webServer.start(port: 8080)
                                } catch {
                                    LogManager.shared.error("Failed to start web server: \(error)")
                                }
                            }
                        } else {
                            webServer.stop()
                        }
                    }

                    // Status indicator (only shown when enabled)
                    if enableWebServer {
                        Divider()

                        HStack {
                            Image(systemName: webServer.isRunning ? "network" : "network.slash")
                                .foregroundColor(webServer.isRunning ? RoxyColors.success : .gray)
                            Text("Server Status")
                            Spacer()
                            Text(webServer.isRunning ? "Running" : "Stopped")
                                .font(.caption)
                                .foregroundColor(webServer.isRunning ? RoxyColors.success : .gray)
                        }

                        // Local URL
                        if webServer.isRunning && !webServer.localURL.isEmpty {
                            HStack {
                                Text("Local:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(webServer.localURL)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                                Spacer()
                                Button("Copy") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(webServer.localURL, forType: .string)
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        // Public URL with Copy button
                        if !webServer.publicURL.isEmpty {
                            HStack {
                                Text("Public:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(webServer.publicURL)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button("Copy Webapp URL") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(webServer.publicURL, forType: .string)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        // Error display
                        if let error = webServer.error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(RoxyColors.warning)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(RoxyColors.warning)
                            }
                        }
                    }
                }
            }

            Section(header: Text("User Preferences")
                .foregroundColor(RoxyColors.neonCyan)
                .font(RoxyFonts.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $preferenceLearningEnabled) {
                        VStack(alignment: .leading) {
                            Text("Enable Preference Learning")
                                .font(.headline)
                            Text("Automatically learn and remember your preferences (contacts, apps, workflow) from completed tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)

                    if preferenceLearningEnabled {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "brain")
                                    .foregroundColor(RoxyColors.neonPurple)
                                Text("Learning Status")
                                    .font(.subheadline)
                                Spacer()
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(RoxyColors.success)
                            }

                            Text("Roxy will analyze completed tasks to learn your preferences and use them in future tasks for faster execution.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        HStack {
                            Button("View Preferences File") {
                                let path = PreferenceManager.shared.getPreferencesPath()
                                NSWorkspace.shared.selectFile(path.path, inFileViewerRootedAtPath: path.deletingLastPathComponent().path)
                            }
                            .buttonStyle(.bordered)

                            Button("Clear All Preferences") {
                                if PreferenceManager.shared.clearAllPreferences() {
                                    LogManager.shared.info("Preferences cleared successfully")
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                }
            }

        }
        .scrollContentBackground(.hidden)
        .background(RoxyColors.background)
        .padding()
        .navigationTitle("Settings")
        .sheet(isPresented: $showPermissionView) {
            PermissionView()
        }
        .onAppear {
            permissionManager.checkAllPermissions()
            configManager.updateKeyStatus()
            if showAPIKeys {
                geminiAPIKey = configManager.getAPIKey(for: .geminiLLM) ?? ""
                ttsAPIKey = configManager.getAPIKey(for: .googleTTS) ?? ""
                sttAPIKey = configManager.getAPIKey(for: .googleSTT) ?? ""
            }
        }
        .onChange(of: showDebugOverlay) { newValue in
            OverlayManager.shared.showDebugOverlay = newValue
        }
        .onChange(of: autoRefreshOverlay) { newValue in
            OverlayManager.shared.autoRefreshOverlay = newValue
        }
        .onChange(of: showAPIKeys) { newValue in
            if newValue {
                geminiAPIKey = configManager.getAPIKey(for: .geminiLLM) ?? ""
                ttsAPIKey = configManager.getAPIKey(for: .googleTTS) ?? ""
                sttAPIKey = configManager.getAPIKey(for: .googleSTT) ?? ""
            } else {
                saveStatus = ""
            }
        }
    }
}
