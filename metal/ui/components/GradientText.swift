import SwiftUI
import Shimmer

// MARK: - Gradient Text

struct GradientText: View {
    let text: String
    let gradient: LinearGradient
    let font: Font
    let fontWeight: Font.Weight
    let shimmer: Bool
    let shimmerDuration: Double

    init(
        _ text: String,
        gradient: LinearGradient = RoxyGradients.cyanPurple,
        font: Font = RoxyFonts.title,
        fontWeight: Font.Weight = .bold,
        shimmer: Bool = false,
        shimmerDuration: Double = 2.0
    ) {
        self.text = text
        self.gradient = gradient
        self.font = font
        self.fontWeight = fontWeight
        self.shimmer = shimmer
        self.shimmerDuration = shimmerDuration
    }

    var body: some View {
        if shimmer {
            Text(text)
                .font(font)
                .fontWeight(fontWeight)
                .shimmering(
                    animation: .linear(duration: shimmerDuration).repeatForever(autoreverses: false),
                    gradient: RoxyGradients.shimmer
                )
        } else {
            Text(text)
                .font(font)
                .fontWeight(fontWeight)
                .foregroundStyle(gradient)
        }
    }
}

// MARK: - Animated Gradient Text (Without Shimmer Library)

struct AnimatedGradientText: View {
    let text: String
    let colors: [Color]
    let font: Font
    let fontWeight: Font.Weight

    @State private var animateGradient = false

    init(
        _ text: String,
        colors: [Color] = [RoxyColors.neonCyan, RoxyColors.neonPurple, RoxyColors.neonPink],
        font: Font = RoxyFonts.title,
        fontWeight: Font.Weight = .bold
    ) {
        self.text = text
        self.colors = colors
        self.font = font
        self.fontWeight = fontWeight
    }

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(fontWeight)
            .foregroundStyle(
                LinearGradient(
                    colors: colors,
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
            )
            .onAppear {
                withAnimation(RoxyAnimation.gradientShift) {
                    animateGradient.toggle()
                }
            }
    }
}

// MARK: - Glowing Text

struct GlowingText: View {
    let text: String
    let color: Color
    let font: Font
    let fontWeight: Font.Weight
    let glowRadius: CGFloat

    init(
        _ text: String,
        color: Color = RoxyColors.neonCyan,
        font: Font = RoxyFonts.title,
        fontWeight: Font.Weight = .bold,
        glowRadius: CGFloat = 4
    ) {
        self.text = text
        self.color = color
        self.font = font
        self.fontWeight = fontWeight
        self.glowRadius = glowRadius
    }

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(fontWeight)
            .foregroundColor(color)
            .glow(color: color, radius: glowRadius)
    }
}

// MARK: - Pulsing Glow Text

struct PulsingGlowText: View {
    let text: String
    let color: Color
    let font: Font
    let fontWeight: Font.Weight
    let minRadius: CGFloat
    let maxRadius: CGFloat

    init(
        _ text: String,
        color: Color = RoxyColors.neonCyan,
        font: Font = RoxyFonts.title,
        fontWeight: Font.Weight = .bold,
        minRadius: CGFloat = 2,
        maxRadius: CGFloat = 5
    ) {
        self.text = text
        self.color = color
        self.font = font
        self.fontWeight = fontWeight
        self.minRadius = minRadius
        self.maxRadius = maxRadius
    }

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(fontWeight)
            .foregroundColor(color)
            .pulsingGlow(color: color, minRadius: minRadius, maxRadius: maxRadius)
    }
}

// MARK: - Text with Gradient Background

struct TextWithGradientBackground: View {
    let text: String
    let gradient: LinearGradient
    let textColor: Color
    let font: Font
    let fontWeight: Font.Weight
    let padding: CGFloat
    let cornerRadius: CGFloat

    init(
        _ text: String,
        gradient: LinearGradient = RoxyGradients.cyanPurple,
        textColor: Color = .white,
        font: Font = RoxyFonts.body,
        fontWeight: Font.Weight = .semibold,
        padding: CGFloat = RoxySpacing.sm,
        cornerRadius: CGFloat = RoxyCornerRadius.sm
    ) {
        self.text = text
        self.gradient = gradient
        self.textColor = textColor
        self.font = font
        self.fontWeight = fontWeight
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(fontWeight)
            .foregroundColor(textColor)
            .padding(.horizontal, padding * 1.5)
            .padding(.vertical, padding)
            .background(gradient)
            .cornerRadius(cornerRadius)
    }
}

// MARK: - View Extension for Easy Gradient Text

extension View {
    func gradientForeground(gradient: LinearGradient) -> some View {
        self.overlay(gradient)
            .mask(self)
    }

    func shimmeringText(
        duration: Double = 2.0,
        gradient: Gradient = RoxyGradients.shimmer
    ) -> some View {
        self.shimmering(
            animation: .linear(duration: duration).repeatForever(autoreverses: false),
            gradient: gradient
        )
    }
}

// MARK: - Preview

#Preview("Gradient Text Variants") {
    ZStack {
        RoxyGradients.background
            .ignoresSafeArea()

        VStack(spacing: RoxySpacing.xl) {
            // Basic gradient text
            GradientText(
                "Roxy",
                gradient: RoxyGradients.cyanPurple,
                font: .system(.largeTitle, design: .rounded, weight: .bold)
            )

            // Shimmering text
            GradientText(
                "Shimmering",
                gradient: RoxyGradients.cyanPurple,
                font: RoxyFonts.title,
                shimmer: true
            )

            // Animated gradient text
            AnimatedGradientText(
                "Animated",
                colors: [RoxyColors.cyan, RoxyColors.purple, RoxyColors.pink],
                font: RoxyFonts.title
            )

            // Glowing text
            GlowingText(
                "Glowing",
                color: RoxyColors.cyan,
                font: RoxyFonts.title
            )

            // Pulsing glow text
            PulsingGlowText(
                "Pulsing",
                color: RoxyColors.purple,
                font: RoxyFonts.title
            )

            // Text with gradient background
            TextWithGradientBackground(
                "Badge Style",
                gradient: RoxyGradients.thinking,
                textColor: .white,
                font: RoxyFonts.caption
            )

            // Custom styled text
            Text("Custom Style")
                .font(RoxyFonts.title2)
                .fontWeight(.bold)
                .gradientForeground(gradient: RoxyGradients.acting)
                .glow(color: RoxyColors.orange, radius: 8)
        }
        .padding(RoxySpacing.xl)
    }
    .frame(width: 400, height: 700)
}
