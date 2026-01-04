import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case agent
    case settings
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .agent: return "Agent"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .agent: return "brain.head.profile"
        case .settings: return "gear"
        }
    }
}
