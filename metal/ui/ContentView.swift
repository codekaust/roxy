import SwiftUI

struct ContentView: View {
    @State private var selectedItem: SidebarItem? = .agent
    @State private var showPermissionView: Bool = false
    @ObservedObject private var permissionManager = PermissionManager.shared

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.title, systemImage: item.icon)
                }
            }
            .navigationTitle("Roxy")
            .listStyle(.sidebar)
        } detail: {
            if let selectedItem {
                switch selectedItem {
                case .agent:
                    AgentView()
                case .settings:
                    SettingsView()
                }
            } else {
                Text("Select an item")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 500) // Increased default size for better layout
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
