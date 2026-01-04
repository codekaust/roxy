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
    // Sleek Futuristic Palette - Refined and sophisticated
    static let neonCyan = Color(hex: "4FC3F7")       // Soft cyan
    static let neonMagenta = Color(hex: "BA68C8")    // Soft magenta
    static let neonBlue = Color(hex: "5C6BC0")       // Deep refined blue
    static let neonGreen = Color(hex: "66BB6A")      // Soft green
    static let neonPink = Color(hex: "EC407A")       // Refined pink
    static let neonPurple = Color(hex: "9575CD")     // Soft purple
    static let neonOrange = Color(hex: "FF7043")     // Soft orange

    // Backgrounds - Dark but sophisticated
    static let pureBlack = Color(hex: "000000")      // Pure OLED black
    static let darkGray = Color(hex: "0D0D0D")       // Very dark gray for subtle contrast
    static let darkerGray = Color(hex: "1A1A1A")     // Card backgrounds
    static let surfaceGray = Color(hex: "212121")    // Surface elements

    // Text - High contrast but not harsh
    static let neonWhite = Color(hex: "FFFFFF")      // Pure white for text
    static let dimWhite = Color(hex: "B0B0B0")       // Dimmed white for secondary text
    static let mutedWhite = Color(hex: "808080")     // Very subtle text

    // Legacy colors (kept for backwards compatibility)
    static let cyan = neonCyan
    static let purple = neonPurple
    static let teal = neonBlue
    static let pink = neonPink
    static let orange = neonOrange
    static let lime = neonGreen
    static let navy = darkGray

    // Semantic Colors
    static let success = neonGreen
    static let error = neonPink
    static let warning = neonOrange
    static let info = neonCyan

    // State Colors
    static let idle = neonCyan
    static let listening = neonGreen
    static let thinking = neonPurple
    static let acting = neonMagenta

    // Glass Tints (updated for dark theme)
    static let glassCyan = neonCyan.opacity(0.2)
    static let glassPurple = neonPurple.opacity(0.2)
    static let glassPink = neonPink.opacity(0.2)
    static let glassOrange = neonOrange.opacity(0.2)
}

// MARK: - Roxy Gradients

struct RoxyGradients {
    // Background Gradients - Pure black for OLED
    static let background = Color.black

    static let backgroundAlternate = LinearGradient(
        colors: [RoxyColors.pureBlack, RoxyColors.darkGray],
        startPoint: .top,
        endPoint: .bottom
    )

    // Neon Accent Gradients
    static let cyanPurple = LinearGradient(
        colors: [RoxyColors.neonCyan, RoxyColors.neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cyanMagenta = LinearGradient(
        colors: [RoxyColors.neonCyan, RoxyColors.neonMagenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let purpleBlue = LinearGradient(
        colors: [RoxyColors.neonPurple, RoxyColors.neonBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pinkOrange = LinearGradient(
        colors: [RoxyColors.neonPink, RoxyColors.neonOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cyanGreen = LinearGradient(
        colors: [RoxyColors.neonCyan, RoxyColors.neonGreen],
        startPoint: .bottom,
        endPoint: .top
    )

    // Neon Border Gradients (full opacity for cyberpunk look)
    static let neonBorderCyan = LinearGradient(
        colors: [RoxyColors.neonCyan, RoxyColors.neonBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let neonBorderMagenta = LinearGradient(
        colors: [RoxyColors.neonMagenta, RoxyColors.neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let neonBorderGreen = LinearGradient(
        colors: [RoxyColors.neonGreen, RoxyColors.neonCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Status Gradients
    static let listening = LinearGradient(
        colors: [RoxyColors.neonGreen, RoxyColors.neonCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let thinking = LinearGradient(
        colors: [RoxyColors.neonPurple, RoxyColors.neonBlue, RoxyColors.neonCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let acting = LinearGradient(
        colors: [RoxyColors.neonOrange, RoxyColors.neonPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Glass Border Gradients (darker for dark theme)
    static let glassBorder = LinearGradient(
        colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Shimmer Gradient (neon colors)
    static let shimmer = Gradient(
        colors: [RoxyColors.neonCyan, RoxyColors.neonPurple, RoxyColors.neonMagenta, RoxyColors.neonCyan]
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
    // Display fonts (SF Pro Display - for headlines)
    static let titleLarge = Font.system(size: 36, weight: .heavy, design: .default)
    static let title = Font.system(size: 30, weight: .bold, design: .default)
    static let title2 = Font.system(size: 24, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

    // Text fonts (SF Pro Text - for body)
    static let headline = Font.system(size: 18, weight: .semibold, design: .default)
    static let bodyLarge = Font.system(size: 19, weight: .medium, design: .default)  // Chat messages
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let caption = Font.system(size: 14, weight: .medium, design: .default)    // Timestamps
    static let caption2 = Font.system(size: 13, weight: .regular, design: .default)

    // Monospace for technical elements
    static let mono = Font.system(size: 15, weight: .medium, design: .monospaced)
}

// MARK: - Glass Effect Modifier

struct GlassEffect: ViewModifier {
    var tintColor: Color
    var opacity: Double = 0.7
    var cornerRadius: CGFloat = RoxyCornerRadius.lg

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [tintColor.opacity(0.2), tintColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    // Blur material
                    Rectangle()
                        .fill(Material.ultraThinMaterial)
                        .opacity(opacity)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        RoxyGradients.glassBorder,
                        lineWidth: 1
                    )
            )
            .cornerRadius(cornerRadius)
            .shadow(color: tintColor.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassEffect(tint: Color = RoxyColors.cyan, opacity: Double = 0.7, cornerRadius: CGFloat = RoxyCornerRadius.lg) -> some View {
        self.modifier(GlassEffect(tintColor: tint, opacity: opacity, cornerRadius: cornerRadius))
    }
}

// MARK: - Dark Glass Effect Modifier (Sleek Futuristic)

struct DarkGlassEffect: ViewModifier {
    var tintColor: Color
    var neonBorderGradient: LinearGradient
    var opacity: Double = 0.4  // Slightly more visible glass
    var cornerRadius: CGFloat = RoxyCornerRadius.lg
    var glowRadius: CGFloat = 4  // Subtle refined glow

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Dark sophisticated background
                    RoxyColors.surfaceGray

                    // Very subtle tint overlay
                    LinearGradient(
                        colors: [tintColor.opacity(0.08), tintColor.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Refined blur material
                    Rectangle()
                        .fill(Material.ultraThin)
                        .opacity(opacity)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(neonBorderGradient, lineWidth: 0.5)  // Thin refined border
            )
            .cornerRadius(cornerRadius)
            // Subtle sophisticated glow
            .shadow(color: tintColor.opacity(0.2), radius: glowRadius, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)  // Depth shadow
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

// MARK: - Glow Modifier

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius * 1.5, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius * 2, x: 0, y: 0)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        self.modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Pulsing Glow Modifier

struct PulsingGlow: ViewModifier {
    var color: Color
    var minRadius: CGFloat = 5
    var maxRadius: CGFloat = 15

    @State private var animateGlow = false

    func body(content: Content) -> some View {
        content
            .glow(color: color, radius: animateGlow ? maxRadius : minRadius)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
    }
}

extension View {
    func pulsingGlow(color: Color, minRadius: CGFloat = 5, maxRadius: CGFloat = 15) -> some View {
        self.modifier(PulsingGlow(color: color, minRadius: minRadius, maxRadius: maxRadius))
    }
}

// MARK: - Gradient Border Modifier

struct GradientBorder: ViewModifier {
    var gradient: LinearGradient
    var lineWidth: CGFloat = 2
    var cornerRadius: CGFloat = RoxyCornerRadius.lg

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(gradient, lineWidth: lineWidth)
            )
            .cornerRadius(cornerRadius)
    }
}

extension View {
    func gradientBorder(gradient: LinearGradient, lineWidth: CGFloat = 2, cornerRadius: CGFloat = RoxyCornerRadius.lg) -> some View {
        self.modifier(GradientBorder(gradient: gradient, lineWidth: lineWidth, cornerRadius: cornerRadius))
    }
}

// MARK: - Breathing Animation Modifier

struct BreathingEffect: ViewModifier {
    @State private var isAnimating = false
    var minScale: CGFloat = 1.0
    var maxScale: CGFloat = 1.1
    var duration: Double = 1.5

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? maxScale : minScale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func breathingEffect(minScale: CGFloat = 1.0, maxScale: CGFloat = 1.1, duration: Double = 1.5) -> some View {
        self.modifier(BreathingEffect(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}
