//
//  Perception.swift
//  metal
//
//  Created by Ayush on 22/12/25.
//
import Foundation
import ApplicationServices
import AppKit

public struct DetectedElement: Identifiable {
    public let id: Int
    public let frame: CGRect
    public let label: String
    public let info: String
}

public struct ScreenAnalysis {
    public let uiRepresentation: String
    public let elementMap: [Int: AXUIElement]
    public let activeAppName: String
    public let elements: [DetectedElement] 
}

public class Perception {
    
    // 1. Force execution on a background thread to avoid Main Thread checker crashes
    public func analyze() async -> ScreenAnalysis {
        return await Task.detached(priority: .userInitiated) {
            
            // 2. Safely get Frontmost App (AppKit calls are generally safe, but we double check)
            let frontApp = NSWorkspace.shared.frontmostApplication
            guard let app = frontApp else {
                return ScreenAnalysis(uiRepresentation: "No active application.", elementMap: [:], activeAppName: "None", elements: [])
            }
            
            let pid = app.processIdentifier
            
            // 3. Prevent self-inspection loops
            if pid == NSRunningApplication.current.processIdentifier {
                return ScreenAnalysis(
                    uiRepresentation: "[Agent is active. Switch to another app.]",
                    elementMap: [:],
                    activeAppName: "Metal Agent",
                    elements: []
                )
            }
            
            // 4. Create the element and scan
            let appElement = AXUIElementCreateApplication(pid)
            
            var localMap: [Int: AXUIElement] = [:]
            var localElements: [DetectedElement] = []
            var localCounter = 0
            
            let uiString = Perception.parseNodeTree(root: appElement, depth: 0, counter: &localCounter, map: &localMap, elements: &localElements)
            return ScreenAnalysis(
                uiRepresentation: uiString,
                elementMap: localMap,
                activeAppName: app.localizedName ?? "Unknown",
                elements: localElements
            )
        }.value
    }
    
    // Static helper to be safe for detached tasks
    private static func parseNodeTree(root: AXUIElement, depth: Int, counter: inout Int, map: inout [Int: AXUIElement], elements: inout [DetectedElement]) -> String {
        if depth > 50 { return "" }
        
        // 5. Get Role Safely
        guard let role = getAttribute(root, kAXRoleAttribute) as? String else { return "" }
        
        // 6. Filter dangerous or noisy elements
        if role == "AXMenuBar" || role == "AXMenu" || role == "AXMenuItem" {
            return ""
        }
        
        let title = getAttribute(root, kAXTitleAttribute) as? String ?? ""
        let value = getAttribute(root, kAXValueAttribute) as? String ?? ""
        let description = getAttribute(root, kAXDescriptionAttribute) as? String ?? ""
        
        var visibleText = title
        if visibleText.isEmpty { visibleText = value }
        if visibleText.isEmpty { visibleText = description }
        
        let isInteractive = isRoleInteractive(role)
        // let isInteractive = true
        let isSemanticallyImportant = !visibleText.isEmpty || isInteractive
        
        var output = ""
        
        if isSemanticallyImportant {
            let indent = String(repeating: "\t", count: depth)
            let cleanRole = role.replacingOccurrences(of: "AX", with: "")
            let cleanText = visibleText.replacingOccurrences(of: "\n", with: " ").prefix(50)
            
            if isInteractive {
                counter += 1
                map[counter] = root
                if let frame = getFrame(root) {
                    elements.append(DetectedElement(id: counter, frame: frame, label: cleanRole, info: String(cleanText)))
                }
                output += "\(indent)*[\(counter)]<\(cleanRole)>\(cleanText)</\(cleanRole)>\n"
            } else {
                output += "\(indent)\(cleanText) <\(cleanRole)>\n"
            }
        }
        
        if let children = getAttribute(root, kAXChildrenAttribute) as? [AXUIElement] {
            let nextDepth = isSemanticallyImportant ? depth + 1 : depth
            for child in children {
                output += parseNodeTree(root: child, depth: nextDepth, counter: &counter, map: &map, elements: &elements)
            }
        }
        
        return output
    }
    private static func getFrame(_ element: AXUIElement) -> CGRect? {
            var positionRef: CFTypeRef?
            var sizeRef: CFTypeRef?
            
            AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef)
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)
            
            var point = CGPoint.zero
            var size = CGSize.zero
            
            if let pRef = positionRef, CFGetTypeID(pRef) == AXValueGetTypeID() {
                AXValueGetValue(pRef as! AXValue, .cgPoint, &point)
            } else { return nil }
            
            if let sRef = sizeRef, CFGetTypeID(sRef) == AXValueGetTypeID() {
                AXValueGetValue(sRef as! AXValue, .cgSize, &size)
            } else { return nil }
            
            return CGRect(origin: point, size: size)
        }
    
    private static func getAttribute(_ element: AXUIElement, _ attribute: String) -> Any? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        if result == .success {
            return value
        }
        return nil
    }
    
    private static func isRoleInteractive(_ role: String) -> Bool {
        let interactiveRoles = [
            "AXButton", "AXRadioButton", "AXCheckBox", "AXTextField", "AXTextArea",
            "AXLink", "AXPopUpButton", "AXSlider", "AXComboBox", "AXTabGroup", "AXStaticText",
            "AXImage"
        ]
        return interactiveRoles.contains(role)
    }
}
