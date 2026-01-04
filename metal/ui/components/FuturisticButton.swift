import SwiftUI

// MARK: - Futuristic Button

struct FuturisticButton: View {
    let title: String?
    let icon: String?
    let action: () -> Void
    let variant: Variant
    let size: Size
    let isActive: Bool

    @State private var isPressed = false
    @State private var isHovered = false

    enum Variant {
        case primary
        case secondary
        case iconOnly
        case voice
        case success
        case danger

        var gradient: LinearGradient {
            switch self {
            case .primary:
                return RoxyGradients.cyanPurple
            case .secondary:
                return RoxyGradients.backgroundAlternate
            case .iconOnly, .voice:
                return RoxyGradients.cyanPurple
            case .success:
                return LinearGradient(
                    colors: [RoxyColors.neonGreen, RoxyColors.success],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .danger:
                return LinearGradient(
                    colors: [RoxyColors.error, RoxyColors.neonPink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        var glowColor: Color {
            switch self {
            case .primary, .iconOnly, .voice:
                return RoxyColors.neonCyan
            case .secondary:
                return RoxyColors.neonPurple
            case .success:
                return RoxyColors.neonGreen
            case .danger:
                return RoxyColors.error
            }
        }

        var shouldUseGlass: Bool {
            switch self {
            case .secondary, .iconOnly:
                return true
            case .primary, .voice, .success, .danger:
                return false
            }
        }
    }

    enum Size {
        case small
        case medium
        case large
        case icon

        var height: CGFloat {
            switch self {
            case .small:
                return 32
            case .medium:
                return 40
            case .large:
                return 48
            case .icon:
                return 48
            }
        }

        var fontSize: Font {
            switch self {
            case .small:
                return RoxyFonts.caption
            case .medium:
                return RoxyFonts.body
            case .large:
                return RoxyFonts.headline
            case .icon:
                return RoxyFonts.title3
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small:
                return 16
            case .medium:
                return 20
            case .large:
                return 24
            case .icon:
                return 24
            }
        }

        var padding: CGFloat {
            switch self {
            case .small:
                return RoxySpacing.xs
            case .medium:
                return RoxySpacing.sm
            case .large:
                return RoxySpacing.md
            case .icon:
                return RoxySpacing.sm
            }
        }
    }

    init(
        title: String? = nil,
        icon: String? = nil,
        variant: Variant = .primary,
        size: Size = .medium,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: {
            withAnimation(RoxyAnimation.buttonPress) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(RoxyAnimation.buttonPress) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: RoxySpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }
                if let title = title {
                    Text(title)
                        .font(size.fontSize)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, variant == .iconOnly || size == .icon ? 0 : size.padding * 1.5)
            .padding(.vertical, size.padding)
            .frame(minWidth: variant == .iconOnly || size == .icon ? size.height : nil)
            .frame(height: size.height)
            .background(
                Group {
                    if variant.shouldUseGlass {
                        ZStack {
                            RoxyColors.surfaceGray
                            LinearGradient(
                                colors: [variant.glowColor.opacity(0.08), variant.glowColor.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Rectangle()
                                .fill(Material.ultraThin)
                                .opacity(0.4)
                        }
                    } else {
                        variant.gradient
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: variant == .iconOnly || size == .icon ? RoxyCornerRadius.full : RoxyCornerRadius.md)
                    .stroke(
                        RoxyGradients.glassBorder,
                        lineWidth: variant.shouldUseGlass ? 0.5 : 0
                    )
            )
            .cornerRadius(variant == .iconOnly || size == .icon ? RoxyCornerRadius.full : RoxyCornerRadius.md)
            .shadow(color: variant.glowColor.opacity(isHovered ? 0.25 : 0.15), radius: isHovered ? 5 : 3, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(RoxyAnimation.quickSpring) {
                isHovered = hovering
            }
        }
        .overlay(
            Group {
                if isActive && variant == .voice {
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                        .scaleEffect(isActive ? 1.2 : 1.0)
                        .opacity(isActive ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: isActive
                        )
                        .padding(-8)
                }
            }
        )
    }
}

// MARK: - Voice Button Variant

struct VoiceButton: View {
    @Binding var isListening: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulsing ring when active
                if isListening {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.red.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 64, height: 64)
                        .scaleEffect(pulseScale)
                        .opacity(2 - pulseScale)
                        .onAppear {
                            withAnimation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                            ) {
                                pulseScale = 1.8
                            }
                        }
                        .onDisappear {
                            pulseScale = 1.0
                        }
                }

                // Main button
                Circle()
                    .fill(
                        isListening
                            ? LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [RoxyColors.neonCyan.opacity(0.15), RoxyColors.neonPurple.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                RoxyGradients.glassBorder,
                                lineWidth: 0.5
                            )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(
                        color: isListening ? Color.red.opacity(0.3) : RoxyColors.neonCyan.opacity(0.15),
                        radius: isListening ? 6 : 3,
                        x: 0,
                        y: 2
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

                // Icon
                Image(systemName: isListening ? "mic.fill" : "mic.slash.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isListening ? "Stop listening" : "Start listening")
    }
}

// MARK: - Preview

#Preview("Futuristic Buttons") {
    ZStack {
        RoxyGradients.background
            .ignoresSafeArea()

        VStack(spacing: RoxySpacing.lg) {
            // Primary button
            FuturisticButton(
                title: "Primary Button",
                icon: "sparkles",
                variant: .primary
            ) {
                print("Primary tapped")
            }

            // Secondary button
            FuturisticButton(
                title: "Secondary Button",
                icon: "gear",
                variant: .secondary
            ) {
                print("Secondary tapped")
            }

            // Success button
            FuturisticButton(
                title: "Success",
                icon: "checkmark.circle.fill",
                variant: .success
            ) {
                print("Success tapped")
            }

            // Danger button
            FuturisticButton(
                title: "Danger",
                icon: "xmark.circle.fill",
                variant: .danger
            ) {
                print("Danger tapped")
            }

            // Icon only buttons
            HStack(spacing: RoxySpacing.sm) {
                FuturisticButton(
                    icon: "trash",
                    variant: .iconOnly,
                    size: .icon
                ) {
                    print("Delete tapped")
                }

                FuturisticButton(
                    icon: "plus",
                    variant: .iconOnly,
                    size: .icon
                ) {
                    print("Add tapped")
                }

                FuturisticButton(
                    icon: "arrow.clockwise",
                    variant: .iconOnly,
                    size: .icon
                ) {
                    print("Refresh tapped")
                }
            }

            // Voice button
            VoiceButton(isListening: .constant(true)) {
                print("Voice tapped")
            }

            VoiceButton(isListening: .constant(false)) {
                print("Voice tapped")
            }
        }
        .padding(RoxySpacing.lg)
    }
    .frame(width: 400, height: 700)
}
