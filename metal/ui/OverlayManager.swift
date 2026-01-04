//
//  OverlayManager.swift
//  metal
//
//  Created by Ayush on 22/12/25.
//

import SwiftUI
import AppKit
import Combine

public class OverlayManager: ObservableObject {
    public static let shared = OverlayManager()
    
    // The Overlay Window (NSPanel for non-activating behavior)
    private var overlayWindow: NSPanel?
    
    // MARK: - Reactive Properties
    @Published public var elements: [DetectedElement] = []
    
    @Published public var currentCaption: String? = nil {
        didSet {
            DispatchQueue.main.async { self.updateState() }
        }
    }
    
    @Published public var todoContent: String? = nil {
        didSet {
            DispatchQueue.main.async { self.updateState() }
        }
    }
    
    // Holds the safe distance from the bottom. Default to 20.
    @Published public var bottomPadding: CGFloat = 20
    
    // MARK: - Internal Logic
    private let perception = Perception()
    private var debugRefreshTimer: Timer?
    private var layoutTimer: Timer? // Separate timer for layout updates
    
    @Published public var showDebugOverlay: Bool {
        didSet {
            UserDefaults.standard.set(showDebugOverlay, forKey: "showDebugOverlay")
            updateState()
        }
    }
    
    @Published public var autoRefreshOverlay: Bool {
        didSet {
            UserDefaults.standard.set(autoRefreshOverlay, forKey: "autoRefreshOverlay")
            updateState()
        }
    }

    private init() {
        self.showDebugOverlay = UserDefaults.standard.bool(forKey: "showDebugOverlay")
        self.autoRefreshOverlay = UserDefaults.standard.bool(forKey: "autoRefreshOverlay")
        
        setupWindow()
        setupScreenObserver()
        updateState()
    }
    
    // MARK: - Window Setup
    private func setupWindow() {
        // Prefer the main screen, but fallback if needed
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let window = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        
        // FIX: Use maximumWindow level to ensure it stays above Full Screen apps and Dock
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)))
        
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        window.isFloatingPanel = true
        
        let rootView = OverlayView()
            .environmentObject(self)
        
        window.contentView = NSHostingView(rootView: rootView)
        self.overlayWindow = window
        
        // Initial layout check
        updateScreenLayout()
    }
    
    // MARK: - Screen & Dock Detection
    private func setupScreenObserver() {
        // 1. Listen for major screen changes (resolution, monitors)
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateScreenLayout()
        }
        
        // 2. Fast Timer for Dock Animation & Full Screen Transitions
        layoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateScreenLayout()
        }
    }
    
    private func updateScreenLayout() {
        // Use the screen that our overlay is actually on, or fallback to main
        guard let window = self.overlayWindow,
              let screen = NSScreen.main else { return } // Force track Main Screen
        
        // FIX: Ensure the window frame always matches the current screen.
        // This fixes the issue where the overlay "fails" or disappears when switching to Full Screen apps.
        if window.frame != screen.frame {
            window.setFrame(screen.frame, display: true)
        }

        // visibleFrame = The part of the screen NOT covered by the Dock or Menu Bar.
        // visibleFrame.origin.y tells us how high the Dock is from the bottom.
        let dockHeight = screen.visibleFrame.origin.y
        
        // Add base padding (20) + Dock Height
        let newPadding = dockHeight + 20
        
        // Only update if changed to avoid unnecessary UI redraws
        if abs(self.bottomPadding - newPadding) > 1.0 {
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.bottomPadding = newPadding
                }
            }
        }
    }
    
    // MARK: - State Management
    private func updateState() {
        let shouldShow = showDebugOverlay || (currentCaption != nil) || (todoContent != nil)
        
        if shouldShow {
            overlayWindow?.orderFrontRegardless()
        } else {
            overlayWindow?.orderOut(nil)
        }
        
        // Handle Debug Auto-Refresh
        debugRefreshTimer?.invalidate()
        debugRefreshTimer = nil
        
        if showDebugOverlay && autoRefreshOverlay {
            debugRefreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                self?.performRefresh()
            }
            performRefresh()
        }
    }
    
    private func performRefresh() {
        Task {
            let analysis = await perception.analyze()
            await self.update(elements: analysis.elements)
        }
    }
    
    @MainActor
    public func update(elements: [DetectedElement]) {
        guard showDebugOverlay else { return }
        self.elements = elements
    }
    
    @MainActor
    public func clear() {
        self.elements = []
        self.todoContent = nil
    }
    
    @MainActor
    public func showCaption(text: String) -> UUID {
        let id = UUID()
        withAnimation { self.currentCaption = text }
        return id
    }
    
    @MainActor
    public func hideCaption(id: UUID) {
        withAnimation { self.currentCaption = nil }
    }
}

// MARK: - View
struct OverlayView: View {
    @EnvironmentObject var manager: OverlayManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // 1. Debug Boxes
                ForEach(manager.elements) { element in
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: element.frame.width, height: element.frame.height)
                        .position(x: element.frame.midX, y: element.frame.midY)
                    
                    Text("[\(element.id)] \(element.label)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .cornerRadius(4)
                        .position(x: element.frame.origin.x + element.frame.width + 20, y: element.frame.origin.y)
                }
                
                // 2. Captions (Bottom)
                if let caption = manager.currentCaption {
                    VStack {
                        Spacer()
                        Text(caption)
                            .multilineTextAlignment(.center)
                            // FIX: Reduced font size from 24 to 14
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Material.ultraThinMaterial)
                                    .opacity(0.5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                                    .shadow(radius: 10)
                            )
                            // DYNAMIC PADDING APPLIED HERE
                            .padding(.bottom, manager.bottomPadding)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 3. Todo List (Top Right)
                if let todo = manager.todoContent {
                    VStack {
                        HStack {
                            Spacer()
                            Text(todo)
                                .font(.system(size: 14, weight: .medium)) // Slightly smaller font for Todo as well
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.85))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.5)))
                                )
                                .padding(.top, 50)
                                .padding(.trailing, 50)
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}