//
//  PermissionView.swift
//  metal
//
//  SwiftUI view for requesting app permissions
//

import SwiftUI

struct PermissionView: View {
    @ObservedObject var permissionManager = PermissionManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Permissions Required")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Roxy needs the following permissions to function properly:")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 32)

            // Permission List
            VStack(spacing: 16) {
                ForEach(PermissionType.allCases, id: \.self) { permission in
                    PermissionRow(
                        permission: permission,
                        permissionManager: permissionManager
                    )
                }
            }
            .padding(.horizontal, 24)

            // Important Note
            if !permissionManager.allPermissionsGranted {
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Important: Restart Required")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }

                        Text("After granting permissions in System Preferences, you must quit and restart Roxy for changes to take effect.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)

                    // Troubleshooting section
                    VStack(spacing: 8) {
                        Text("Troubleshooting: Permission Already Granted But Not Working?")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Text("1. Remove 'Roxy.app' from System Preferences → Accessibility\n2. Click 'Force Permission Prompt' below\n3. Re-grant the permission\n4. Restart Roxy")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: {
                            permissionManager.forceAccessibilityPrompt()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle")
                                Text("Force Permission Prompt")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                if !permissionManager.allPermissionsGranted {
                    Button(action: {
                        Task {
                            await requestAllPermissions()
                        }
                    }) {
                        Text("Grant Permissions")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        permissionManager.restartApp()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Restart Roxy")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        dismiss()
                    }) {
                        Text("I'll Do This Later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(width: 600, height: 750)
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }

    private func requestAllPermissions() async {
        // Request microphone first (this shows system dialog)
        await permissionManager.requestMicrophone()

        // Then request accessibility (this opens System Preferences)
        permissionManager.requestAccessibility()

        // Refresh status
        permissionManager.checkAllPermissions()
    }
}

struct PermissionRow: View {
    let permission: PermissionType
    @ObservedObject var permissionManager: PermissionManager

    private var isGranted: Bool {
        switch permission {
        case .accessibility:
            return permissionManager.accessibilityGranted
        case .microphone:
            return permissionManager.microphoneGranted
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(permission.rawValue)
                        .font(.headline)

                    Spacer()

                    Text(permissionManager.getPermissionStatus(permission))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isGranted ? .green : .orange)
                }

                Text(permission.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action Button
            if !isGranted {
                Button(action: {
                    permissionManager.openSystemPreferences(for: permission)
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Open System Preferences")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGranted ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 2)
        )
    }

    private var iconName: String {
        switch permission {
        case .accessibility:
            return isGranted ? "hand.tap.fill" : "hand.tap"
        case .microphone:
            return isGranted ? "mic.fill" : "mic"
        }
    }
}

// Preview
#Preview {
    PermissionView()
}
