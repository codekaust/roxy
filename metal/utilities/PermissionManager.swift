//
//  PermissionManager.swift
//  metal
//
//  Manages system permissions required by the app
//

import Foundation
import Speech
import AppKit
import ApplicationServices

enum PermissionType: String, CaseIterable {
    case accessibility = "Accessibility"
    case microphone = "Microphone & Speech Recognition"

    var description: String {
        switch self {
        case .accessibility:
            return "Required to control applications and interact with UI elements"
        case .microphone:
            return "Required for voice commands and dictation"
        }
    }

    var settingsPath: String {
        switch self {
        case .accessibility:
            return "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        case .microphone:
            return "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        }
    }
}

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var accessibilityGranted: Bool = false
    @Published var microphoneGranted: Bool = false
    @Published var allPermissionsGranted: Bool = false
    @Published var needsRestart: Bool = false

    private var checkTimer: Timer?

    private init() {
        checkAllPermissions()
        startPeriodicCheck()
    }

    // MARK: - Periodic Check

    private func startPeriodicCheck() {
        // Check permissions every 2 seconds to detect changes from System Preferences
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAllPermissions()
            }
        }
    }

    // MARK: - Check Permissions

    func checkAllPermissions() {
        let previousAccessibility = accessibilityGranted

        checkAccessibility()
        checkMicrophone()

        // If accessibility was just granted, we might need a restart
        if !previousAccessibility && accessibilityGranted {
            print("PermissionManager: Accessibility permission detected!")
        }

        updateAllPermissionsStatus()
    }

    func checkAccessibility() {
        let result = AXIsProcessTrusted()

        // Debug: Print app location and bundle info
        let bundlePath = Bundle.main.bundlePath
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let executablePath = Bundle.main.executablePath ?? "unknown"

        print("=== ACCESSIBILITY DEBUG ===")
        print("AXIsProcessTrusted result: \(result)")
        print("Bundle Path: \(bundlePath)")
        print("Bundle ID: \(bundleID)")
        print("Executable Path: \(executablePath)")
        print("========================")

        accessibilityGranted = result
    }

    func checkMicrophone() {
        let status = SFSpeechRecognizer.authorizationStatus()
        microphoneGranted = (status == .authorized)
    }

    private func updateAllPermissionsStatus() {
        allPermissionsGranted = accessibilityGranted && microphoneGranted
    }

    // MARK: - Request Permissions

    func requestAccessibility() {
        print("PermissionManager: Requesting accessibility permission...")

        // For accessibility, we need to prompt the user to open System Preferences
        // macOS doesn't allow programmatic granting of accessibility permissions
        // IMPORTANT: Use the prompt option to ensure System Preferences opens
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let resultWithPrompt = AXIsProcessTrustedWithOptions(options)

        print("PermissionManager: Prompt shown. Result: \(resultWithPrompt)")

        // Check again after a short delay
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            checkAccessibility()
        }
    }

    // MARK: - Reset and Re-request (for debugging)

    func forceAccessibilityPrompt() {
        // This will always show the system prompt
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func requestMicrophone() async {
        // Request speech recognition permission
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                continuation.resume(returning: authStatus)
            }
        }

        microphoneGranted = (status == .authorized)
        updateAllPermissionsStatus()
    }

    // MARK: - Open System Preferences

    func openSystemPreferences(for permission: PermissionType) {
        if let url = URL(string: permission.settingsPath) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Get Missing Permissions

    func getMissingPermissions() -> [PermissionType] {
        var missing: [PermissionType] = []

        if !accessibilityGranted {
            missing.append(.accessibility)
        }
        if !microphoneGranted {
            missing.append(.microphone)
        }

        return missing
    }

    // MARK: - Permission Status Text

    func getPermissionStatus(_ type: PermissionType) -> String {
        switch type {
        case .accessibility:
            return accessibilityGranted ? "✓ Granted" : "✗ Required"
        case .microphone:
            return microphoneGranted ? "✓ Granted" : "✗ Required"
        }
    }

    // MARK: - Restart App

    func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        exit(0)
    }
}
