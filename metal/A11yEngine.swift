import Foundation
import ApplicationServices
import AppKit

class A11yEngine {
    
    // Scan the system and return a list of App Nodes
    func scanSystem() -> [A11yNode] {
        var appNodes: [A11yNode] = []
        let apps = NSWorkspace.shared.runningApplications
        
        for app in apps {
            // Filter out background apps to keep it fast
            if app.activationPolicy != .regular { continue }
            // Skip ourself
            if app.processIdentifier == NSRunningApplication.current.processIdentifier { continue }
            
            let pid = app.processIdentifier
            let appElement = AXUIElementCreateApplication(pid)
            
            // Create the Root Node for the App
            var rootNode = buildNode(from: appElement)
            
            // Manually override the title for the App Root because AX often returns empty for the process itself
            let appName = app.localizedName ?? "Unknown App"
            rootNode = A11yNode(
                role: "AXApplication",
                title: appName,
                value: "PID: \(pid)",
                frame: rootNode.frame,
                children: rootNode.children
            )
            
            appNodes.append(rootNode)
        }
        return appNodes
    }
    
    // Recursive function that returns a Node (and its children)
    private func buildNode(from element: AXUIElement, depth: Int = 0) -> A11yNode {
        // Safety break for recursion (Electron apps can be infinite)
        if depth > 50 { 
            return A11yNode(role: "MAX_DEPTH", title: "", value: "", frame: .zero)
        }
        
        // 1. Fetch Attributes
        var roleRef: CFTypeRef?
        var titleRef: CFTypeRef?
        var valueRef: CFTypeRef?
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        // Batch fetching is possible but complex; let's do individual fetches for clarity
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef)
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)
        
        let role = (roleRef as? String) ?? "Unknown"
        let title = (titleRef as? String) ?? ""
        let value = (valueRef as? String) ?? ""
        
        // 2. Decode Geometry (Position & Size)
        var point = CGPoint.zero
        var size = CGSize.zero
        
        // AXValueGetValue is a low-level CoreFoundation function
        if let pRef = positionRef, CFGetTypeID(pRef) == AXValueGetTypeID() {
            AXValueGetValue(pRef as! AXValue, .cgPoint, &point)
        }
        if let sRef = sizeRef, CFGetTypeID(sRef) == AXValueGetTypeID() {
            AXValueGetValue(sRef as! AXValue, .cgSize, &size)
        }
        
        let frame = CGRect(origin: point, size: size)
        
        // 3. Process Children
        var childNodes: [A11yNode] = []
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                childNodes.append(buildNode(from: child, depth: depth + 1))
            }
        }
        
        // 4. Return the structured node
        return A11yNode(role: role, title: title, value: value, frame: frame, children: childNodes.isEmpty ? nil : childNodes)
    }
}