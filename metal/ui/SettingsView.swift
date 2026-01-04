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
    var body: some View {
        Form {
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
        .onChange(of: showDebugOverlay) { newValue in
            OverlayManager.shared.showDebugOverlay = newValue
        }
        .onChange(of: autoRefreshOverlay) { newValue in
            OverlayManager.shared.autoRefreshOverlay = newValue
        }
    }
}
