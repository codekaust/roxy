import SwiftUI

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Roxy Colors

struct RoxyColors {
    // ChatGPT-inspired clean color palette (Dark Mode)

    // Main backgrounds
    static let background = Color(hex: "212121")        // Main chat background
    static let backgroundAlt = Color(hex: "2F2F2F")     // Alternate background (user messages)
    static let surface = Color(hex: "3A3A3A")           // Surface elements (cards, inputs)

    // Sidebar
    static let sidebarBg = Color(hex: "171717")         // Sidebar background
    static let sidebarHover = Color(hex: "2A2A2A")      // Sidebar item hover
    static let sidebarActive = Color(hex: "2F2F2F")     // Sidebar active item

    // Text colors
    static let textPrimary = Color(hex: "ECECEC")       // Primary text
    static let textSecondary = Color(hex: "B4B4B4")     // Secondary text
    static let textTertiary = Color(hex: "8E8E8E")      // Tertiary/muted text

    // Accent colors (ChatGPT teal)
    static let accent = Color(hex: "10A37F")            // Primary accent
    static let accentHover = Color(hex: "1A7F64")       // Accent hover

    // Borders & dividers
    static let border = Color(hex: "4E4E4E")            // Standard border
    static let borderLight = Color(hex: "3A3A3A")       // Light border/divider

    // Status colors (subtle, not poppy)
    static let success = Color(hex: "10A37F")           // Success/green
    static let error = Color(hex: "EF4444")             // Error/red
    static let warning = Color(hex: "F59E0B")           // Warning/amber
    static let info = Color(hex: "3B82F6")              // Info/blue

    // Legacy aliases for backward compatibility
    static let neonCyan = accent
    static let neonMagenta = info
    static let neonBlue = info
    static let neonGreen = success
    static let neonPink = error
    static let neonPurple = info
    static let neonOrange = warning
    static let pureBlack = Color(hex: "000000")
    static let darkGray = sidebarBg
    static let darkerGray = sidebarBg
    static let surfaceGray = surface
    static let neonWhite = textPrimary
    static let dimWhite = textSecondary
    static let mutedWhite = textTertiary
    static let cyan = accent
    static let purple = info
    static let teal = accent
    static let pink = error
    static let orange = warning
    static let lime = success
    static let navy = sidebarBg
    static let idle = accent
    static let listening = success
    static let thinking = info
    static let acting = warning
    static let glassCyan = accent.opacity(0.1)
    static let glassPurple = info.opacity(0.1)
    static let glassPink = error.opacity(0.1)
    static let glassOrange = warning.opacity(0.1)
}

// MARK: - Roxy Gradients

struct RoxyGradients {
    // Simple, clean backgrounds (no fancy gradients)
    static let background = RoxyColors.background

    static let backgroundAlternate = LinearGradient(
        colors: [RoxyColors.background, RoxyColors.backgroundAlt],
        startPoint: .top,
        endPoint: .bottom
    )

    // Simple accent gradients (for buttons only)
    static let cyanPurple = LinearGradient(
        colors: [RoxyColors.accent, RoxyColors.accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cyanMagenta = LinearGradient(
        colors: [RoxyColors.accent, RoxyColors.accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let purpleBlue = LinearGradient(
        colors: [RoxyColors.info, RoxyColors.info],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pinkOrange = LinearGradient(
        colors: [RoxyColors.error, RoxyColors.error],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cyanGreen = LinearGradient(
        colors: [RoxyColors.accent, RoxyColors.success],
        startPoint: .bottom,
        endPoint: .top
    )

    // Simple border gradients (minimal)
    static let neonBorderCyan = LinearGradient(
        colors: [RoxyColors.border, RoxyColors.border],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let neonBorderMagenta = LinearGradient(
        colors: [RoxyColors.border, RoxyColors.border],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let neonBorderGreen = LinearGradient(
        colors: [RoxyColors.border, RoxyColors.border],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Status gradients (simple, single color)
    static let listening = LinearGradient(
        colors: [RoxyColors.success, RoxyColors.success],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let thinking = LinearGradient(
        colors: [RoxyColors.info, RoxyColors.info],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let acting = LinearGradient(
        colors: [RoxyColors.warning, RoxyColors.warning],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Simple border (no gradient)
    static let glassBorder = LinearGradient(
        colors: [RoxyColors.border, RoxyColors.border],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Simple shimmer (just accent color)
    static let shimmer = Gradient(
        colors: [RoxyColors.accent, RoxyColors.accent, RoxyColors.accent, RoxyColors.accent]
    )
}

// MARK: - Roxy Spacing

struct RoxySpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Roxy Corner Radius

struct RoxyCornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Roxy Fonts

struct RoxyFonts {
    // Clean, readable fonts (ChatGPT style - simpler weights)
    static let titleLarge = Font.system(size: 28, weight: .semibold, design: .default)
    static let title = Font.system(size: 24, weight: .semibold, design: .default)
    static let title2 = Font.system(size: 20, weight: .semibold, design: .default)
    static let title3 = Font.system(size: 18, weight: .medium, design: .default)

    // Body text (clean and readable)
    static let headline = Font.system(size: 16, weight: .medium, design: .default)
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)  // Chat messages
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)    // Timestamps
    static let caption2 = Font.system(size: 12, weight: .regular, design: .default)

    // Monospace for code/technical
    static let mono = Font.system(size: 14, weight: .regular, design: .monospaced)
}

// MARK: - Glass Effect Modifier (Simplified - no fancy effects)

struct GlassEffect: ViewModifier {
    var tintColor: Color
    var opacity: Double = 0.7
    var cornerRadius: CGFloat = RoxyCornerRadius.lg

    func body(content: Content) -> some View {
        content
            .background(RoxyColors.surface)
            .cornerRadius(cornerRadius)
    }
}

extension View {
    func glassEffect(tint: Color = RoxyColors.accent, opacity: Double = 0.7, cornerRadius: CGFloat = RoxyCornerRadius.lg) -> some View {
        self.modifier(GlassEffect(tintColor: tint, opacity: opacity, cornerRadius: cornerRadius))
    }
}

// MARK: - Dark Glass Effect Modifier (Simplified)

struct DarkGlassEffect: ViewModifier {
    var tintColor: Color
    var neonBorderGradient: LinearGradient
    var opacity: Double = 0.4
    var cornerRadius: CGFloat = RoxyCornerRadius.lg
    var glowRadius: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .background(RoxyColors.surface)
            .cornerRadius(cornerRadius)
    }
}

extension View {
    func darkGlassEffect(
        tint: Color,
        neonBorder: LinearGradient,
        opacity: Double = 0.4,
        cornerRadius: CGFloat = RoxyCornerRadius.lg,
        glowRadius: CGFloat = 4
    ) -> some View {
        self.modifier(DarkGlassEffect(
            tintColor: tint,
            neonBorderGradient: neonBorder,
            opacity: opacity,
            cornerRadius: cornerRadius,
            glowRadius: glowRadius
        ))
    }
}

// MARK: - Glow Modifier (Removed - no glows in clean design)

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 10

    func body(content: Content) -> some View {
        content  // No glow effect
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        self.modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Pulsing Glow Modifier (Removed - no animations)

struct PulsingGlow: ViewModifier {
    var color: Color
    var minRadius: CGFloat = 5
    var maxRadius: CGFloat = 15

    @State private var animateGlow = false

    func body(content: Content) -> some View {
        content  // No pulsing glow
    }
}

extension View {
    func pulsingGlow(color: Color, minRadius: CGFloat = 5, maxRadius: CGFloat = 15) -> some View {
        self.modifier(PulsingGlow(color: color, minRadius: minRadius, maxRadius: maxRadius))
    }
}

// MARK: - Gradient Border Modifier (Simplified - solid border)

struct GradientBorder: ViewModifier {
    var gradient: LinearGradient
    var lineWidth: CGFloat = 1
    var cornerRadius: CGFloat = RoxyCornerRadius.lg

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(RoxyColors.border, lineWidth: lineWidth)
            )
            .cornerRadius(cornerRadius)
    }
}

extension View {
    func gradientBorder(gradient: LinearGradient, lineWidth: CGFloat = 1, cornerRadius: CGFloat = RoxyCornerRadius.lg) -> some View {
        self.modifier(GradientBorder(gradient: gradient, lineWidth: lineWidth, cornerRadius: cornerRadius))
    }
}

// MARK: - Breathing Animation Modifier (Removed - no animations)

struct BreathingEffect: ViewModifier {
    @State private var isAnimating = false
    var minScale: CGFloat = 1.0
    var maxScale: CGFloat = 1.1
    var duration: Double = 1.5

    func body(content: Content) -> some View {
        content  // No breathing effect
    }
}

extension View {
    func breathingEffect(minScale: CGFloat = 1.0, maxScale: CGFloat = 1.1, duration: Double = 1.5) -> some View {
        self.modifier(BreathingEffect(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}
