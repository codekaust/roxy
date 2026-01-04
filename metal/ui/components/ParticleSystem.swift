import SwiftUI
import Vortex

// MARK: - Particle System Wrapper

struct ParticleSystem: View {
    let style: ParticleStyle
    let intensity: Double

    enum ParticleStyle {
        case fireflies
        case confetti
        case magic
        case snow
        case fire

        var vortexSystem: VortexSystem {
            switch self {
            case .fireflies: return .fireflies
            case .confetti: return .confetti
            case .magic: return .magic
            case .snow: return .snow
            case .fire: return .fire
            }
        }

        var particleColor: Color {
            switch self {
            case .fireflies: return .white
            case .confetti: return RoxyColors.cyan
            case .magic: return RoxyColors.purple
            case .snow: return .white
            case .fire: return RoxyColors.orange
            }
        }
    }

    init(style: ParticleStyle = .fireflies, intensity: Double = 0.5) {
        self.style = style
        self.intensity = intensity
    }

    var body: some View {
        VortexView(style.vortexSystem) {
            Circle()
                .fill(style.particleColor.opacity(intensity))
                .frame(width: 2 + (intensity * 2))
                .tag("particle")
        }
    }
}

// MARK: - Ambient Particles (for backgrounds)

struct AmbientParticles: View {
    let color: Color
    let density: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(color: Color = .white, density: Double = 0.3) {
        self.color = color
        self.density = density
    }

    var body: some View {
        if !reduceMotion {
            VortexView(.fireflies) {
                Circle()
                    .fill(color.opacity(density))
                    .frame(width: 2)
                    .tag("ambient")
            }
        }
    }
}

// MARK: - Thinking Particles (for AI thinking state)

struct ThinkingParticles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !reduceMotion {
            VortexView(.magic) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [RoxyColors.purple, RoxyColors.cyan.opacity(0.6)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 2
                        )
                    )
                    .frame(width: 4)
                    .tag("thinking")
            }
        }
    }
}

// MARK: - Success Particles (for success states)

struct SuccessParticles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !reduceMotion {
            VortexView(.confetti) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [RoxyColors.lime, Color.green],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .tag("success")
            }
        }
    }
}

// MARK: - Preview

#Preview("Particle Systems") {
    ZStack {
        Color.black
            .ignoresSafeArea()

        VStack(spacing: RoxySpacing.xl) {
            // Fireflies
            ZStack {
                Color.gray.opacity(0.2)
                ParticleSystem(style: .fireflies, intensity: 0.5)
                Text("Fireflies")
                    .font(RoxyFonts.title3)
                    .foregroundColor(.white)
            }
            .frame(height: 150)
            .cornerRadius(RoxyCornerRadius.lg)

            // Magic
            ZStack {
                Color.gray.opacity(0.2)
                ParticleSystem(style: .magic, intensity: 0.7)
                Text("Magic")
                    .font(RoxyFonts.title3)
                    .foregroundColor(.white)
            }
            .frame(height: 150)
            .cornerRadius(RoxyCornerRadius.lg)

            // Confetti
            ZStack {
                Color.gray.opacity(0.2)
                ParticleSystem(style: .confetti, intensity: 0.6)
                Text("Confetti")
                    .font(RoxyFonts.title3)
                    .foregroundColor(.white)
            }
            .frame(height: 150)
            .cornerRadius(RoxyCornerRadius.lg)

            // Custom particles
            ZStack {
                Color.gray.opacity(0.2)
                ThinkingParticles()
                Text("Thinking")
                    .font(RoxyFonts.title3)
                    .foregroundColor(.white)
            }
            .frame(height: 150)
            .cornerRadius(RoxyCornerRadius.lg)
        }
        .padding(RoxySpacing.lg)
    }
    .frame(width: 400, height: 800)
}
