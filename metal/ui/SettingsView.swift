//
//  SettingsView.swift
//  metal
//
//  Created by Ayush on 22/12/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("showDebugOverlay") private var showDebugOverlay = true
    @AppStorage("autoRefreshOverlay") private var autoRefreshOverlay = false
    @ObservedObject private var ttsManager = TTSManager.shared
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var showPermissionView = false

    var body: some View {
        Form {
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
                                    Text("High quality, requires internet & API Key.")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                            
                            if ttsManager.useCloudTTS {
                                SecureField("Google Cloud API Key", text: $ttsManager.googleApiKey)
                                    .textFieldStyle(.roundedBorder)
                                
                                Text("Requires Cloud Text-to-Speech API enabled.")
                                    .font(.caption2).foregroundColor(.gray)
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
        }
        .onChange(of: showDebugOverlay) { newValue in
            OverlayManager.shared.showDebugOverlay = newValue
        }
        .onChange(of: autoRefreshOverlay) { newValue in
            OverlayManager.shared.autoRefreshOverlay = newValue
        }
    }
}
