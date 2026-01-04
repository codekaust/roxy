import SwiftUI

struct ContentView: View {
    @State private var selectedItem: SidebarItem? = .agent
    @State private var showPermissionView: Bool = false
    @State private var backgroundIntensity: Double = 0.5
    @ObservedObject private var permissionManager = PermissionManager.shared

    var body: some View {
        ZStack {
            // Animated gradient background
            SimpleAnimatedBackground(intensity: backgroundIntensity)

            // Main content
            NavigationSplitView {
                // Sidebar with dark theme
                ZStack {
                    // Dark background for sidebar
                    Rectangle()
                        .fill(RoxyColors.darkGray)

                    List(SidebarItem.allCases, selection: $selectedItem) { item in
                        NavigationLink(value: item) {
                            Label {
                                Text(item.title)
                                    .font(RoxyFonts.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(RoxyColors.neonWhite)
                            } icon: {
                                Image(systemName: item.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(selectedItem == item ? RoxyColors.neonCyan : RoxyColors.dimWhite)
                            }
                        }
                        .listRowBackground(
                            Group {
                                if selectedItem == item {
                                    RoundedRectangle(cornerRadius: RoxyCornerRadius.md)
                                        .fill(RoxyColors.neonCyan.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: RoxyCornerRadius.md)
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [RoxyColors.neonCyan.opacity(0.4), RoxyColors.neonCyan.opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 0.5
                                                )
                                        )
                                        .shadow(color: RoxyColors.neonCyan.opacity(0.15), radius: 3, x: 0, y: 1)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.sidebar)
                }
                .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        GradientText(
                            "Roxy",
                            gradient: RoxyGradients.cyanPurple,
                            font: RoxyFonts.title2,
                            fontWeight: .bold,
                            shimmer: true,
                            shimmerDuration: 3.0
                        )
                    }
                }
            } detail: {
                if let selectedItem {
                    switch selectedItem {
                    case .agent:
                        AgentView()
                    case .settings:
                        SettingsView()
                    }
                } else {
                    ZStack {
                        GlassmorphicCard(variant: .primary) {
                            VStack(spacing: RoxySpacing.md) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(RoxyColors.neonCyan)
                                    .shadow(color: RoxyColors.neonCyan.opacity(0.3), radius: 4, x: 0, y: 2)

                                Text("Select an item")
                                    .font(RoxyFonts.title2)
                                    .foregroundColor(RoxyColors.neonWhite)
                            }
                        }
                        .frame(maxWidth: 300)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .sheet(isPresented: $showPermissionView) {
            PermissionView()
        }
        .onAppear {
            // Check permissions when the app launches
            permissionManager.checkAllPermissions()

            // Show permission view if any permissions are missing
            if !permissionManager.allPermissionsGranted {
                // Delay slightly to ensure the main window is visible first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showPermissionView = true
                }
            }
        }
        .onChange(of: permissionManager.allPermissionsGranted) { _, granted in
            // Auto-dismiss the permission view when all permissions are granted
            if granted {
                showPermissionView = false
            }
        }
    }
}
