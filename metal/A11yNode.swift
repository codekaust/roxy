import Foundation

struct A11yNode: Identifiable, Codable {
    let id = UUID()
    let role: String
    let title: String
    let value: String
    let frame: CGRect // Stores (x, y, width, height)
    var children: [A11yNode]? = nil
    
    // Helper: Calculates the safe center point for clicking
    var clickPoint: CGPoint {
        return CGPoint(x: frame.midX, y: frame.midY)
    }
    
    // Helper: Formats the node for your text log (so you don't break your UI)
    func toLogString(depth: Int = 0) -> String {
        let indent = String(repeating: "  ", count: depth)
        let info = "[\(role)] T:\"\(title)\" @(\(Int(frame.origin.x)), \(Int(frame.origin.y)))"
        var output = "\(indent)\(info)\n"
        
        if let children = children {
            for child in children {
                output += child.toLogString(depth: depth + 1)
            }
        }
        return output
    }
}