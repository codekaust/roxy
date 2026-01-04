import SwiftUI

struct SettingsView: View {
    @AppStorage("showDebugOverlay") private var showDebugOverlay = true
    @AppStorage("autoRefreshOverlay") private var autoRefreshOverlay = false
    @ObservedObject private var ttsManager = TTSManager.shared
    @ObservedObject private var permissionManager = PermissionManager.shared
    @ObservedObject private var configManager = ConfigurationManager.shared
    @State private var showPermissionView = false

    @State private var geminiAPIKey: String = ""
    @State private var ttsAPIKey: String = ""
    @State private var sttAPIKey: String = ""
    @State private var showAPIKeys: Bool = false
    @State private var saveStatus: String = ""

    var body: some View {
        Form {
            Section(header: Text("API Keys")) {
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

            Section(header: Text("Permissions")) {
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

            Section(header: Text("Developer Tools")) {
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
            Section(header: Text("Voice Settings")) {
                Toggle(isOn: $ttsManager.useCloudTTS) {
                    VStack(alignment: .leading) {
                        Text("Use Cloud TTS")
                            .font(.headline)
                        Text("High quality voice using Google Cloud Text-to-Speech (requires internet).")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            
        }
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
