import SwiftUI

// MARK: - Glassmorphic Card Component

struct GlassmorphicCard<Content: View>: View {
    let content: Content
    let variant: Variant
    let padding: CGFloat
    let cornerRadius: CGFloat

    enum Variant {
        case primary
        case secondary
        case accent
        case success
        case warning
        case error

        var tintColor: Color {
            switch self {
            case .primary:
                return RoxyColors.cyan
            case .secondary:
                return RoxyColors.purple
            case .accent:
                return RoxyColors.pink
            case .success:
                return RoxyColors.lime
            case .warning:
                return RoxyColors.orange
            case .error:
                return RoxyColors.pink
            }
        }
    }

    init(
        variant: Variant = .primary,
        padding: CGFloat = RoxySpacing.md,
        cornerRadius: CGFloat = RoxyCornerRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .glassEffect(tint: variant.tintColor, cornerRadius: cornerRadius)
    }
}

// MARK: - Glassmorphic Card with Header

struct GlassmorphicCardWithHeader<HeaderContent: View, Content: View>: View {
    let headerContent: HeaderContent
    let content: Content
    let variant: GlassmorphicCard<Content>.Variant
    let padding: CGFloat
    let cornerRadius: CGFloat

    init(
        variant: GlassmorphicCard<Content>.Variant = .primary,
        padding: CGFloat = RoxySpacing.md,
        cornerRadius: CGFloat = RoxyCornerRadius.lg,
        @ViewBuilder header: () -> HeaderContent,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.headerContent = header()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerContent
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    variant.tintColor.opacity(0.15)
                )

            Divider()
                .overlay(
                    LinearGradient(
                        colors: [variant.tintColor.opacity(0.4), variant.tintColor.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Content
            content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassEffect(tint: variant.tintColor, cornerRadius: cornerRadius)
    }
}

// MARK: - Glassmorphic Container

struct GlassmorphicContainer<Content: View>: View {
    let content: Content
    let tintColor: Color
    let opacity: Double
    let cornerRadius: CGFloat
    let showBorder: Bool

    init(
        tintColor: Color = RoxyColors.cyan,
        opacity: Double = 0.7,
        cornerRadius: CGFloat = RoxyCornerRadius.lg,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.tintColor = tintColor
        self.opacity = opacity
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
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
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                RoxyGradients.glassBorder,
                                lineWidth: 1
                            )
                    }
                }
            )
            .cornerRadius(cornerRadius)
            .shadow(color: tintColor.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview

#Preview("Glassmorphic Cards") {
    ZStack {
        RoxyGradients.background
            .ignoresSafeArea()

        VStack(spacing: RoxySpacing.lg) {
            GlassmorphicCard(variant: .primary) {
                VStack(alignment: .leading, spacing: RoxySpacing.xs) {
                    Text("Primary Card")
                        .font(RoxyFonts.title3)
                        .fontWeight(.bold)
                    Text("This is a primary glassmorphic card with cyan tint")
                        .font(RoxyFonts.body)
                        .foregroundColor(.secondary)
                }
            }

            GlassmorphicCard(variant: .secondary) {
                VStack(alignment: .leading, spacing: RoxySpacing.xs) {
                    Text("Secondary Card")
                        .font(RoxyFonts.title3)
                        .fontWeight(.bold)
                    Text("This is a secondary glassmorphic card with purple tint")
                        .font(RoxyFonts.body)
                        .foregroundColor(.secondary)
                }
            }

            GlassmorphicCardWithHeader(variant: .accent) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Card with Header")
                        .font(RoxyFonts.headline)
                }
            } content: {
                Text("This card has a separate header section with a divider")
                    .font(RoxyFonts.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(RoxySpacing.lg)
    }
    .frame(width: 400, height: 600)
}
