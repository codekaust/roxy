import SwiftUI

struct ContentView: View {
    @State private var selectedItem: SidebarItem? = .agent
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.title, systemImage: item.icon)
                }
            }
            .navigationTitle("Metal")
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
    }
}
