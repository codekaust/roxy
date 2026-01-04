import SwiftUI
import Vortex

// MARK: - AI Status Visualization

struct AIStatusVisualization: View {
    let state: AIState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0

    enum AIState {
        case idle
        case listening
        case thinking
        case acting
        case error

        var color: Color {
            switch self {
            case .idle: return RoxyColors.cyan
            case .listening: return Color.green
            case .thinking: return RoxyColors.purple
            case .acting: return RoxyColors.orange
            case .error: return Color.red
            }
        }

        var gradientColors: [Color] {
            switch self {
            case .idle: return [RoxyColors.cyan, RoxyColors.cyan.opacity(0.6)]
            case .listening: return [Color.green, RoxyColors.cyan]
            case .thinking: return [RoxyColors.purple, Color.blue, RoxyColors.cyan]
            case .acting: return [RoxyColors.orange, RoxyColors.pink]
            case .error: return [Color.red, RoxyColors.orange]
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .idle: return "Agent is idle"
            case .listening: return "Agent is listening"
            case .thinking: return "Agent is thinking"
            case .acting: return "Agent is acting"
            case .error: return "Agent encountered an error"
            }
        }
    }

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [state.color.opacity(0.6), .clear],
                        center: .center,
                        startRadius: 15,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(pulseScale)

            // Main orb
            Circle()
                .fill(
                    AngularGradient(
                        colors: state.gradientColors,
                        center: .center,
                        angle: .degrees(rotationAngle)
                    )
                )
                .frame(width: 50, height: 50)
                .shadow(color: state.color.opacity(0.8), radius: 15)

            // Particle overlay for thinking state
            if state == .thinking && !reduceMotion {
                VortexView(.magic) {
                    Circle()
                        .fill(RoxyColors.purple)
                        .frame(width: 4)
                        .tag("particle")
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            }
        }
        .accessibilityLabel(state.accessibilityLabel)
        .onAppear {
            startAnimations()
        }
        .onChange(of: state) { _, newState in
            startAnimations()
        }
    }

    func startAnimations() {
        if reduceMotion {
            return
        }

        // Breathing pulse
        let pulseScale: CGFloat = state == .idle ? 1.1 : 1.3
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            self.pulseScale = pulseScale
        }

        // Rotation for thinking state
        if state == .thinking {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        } else {
            rotationAngle = 0
        }
    }
}

// MARK: - Compact AI Status (for smaller spaces)

struct CompactAIStatus: View {
    let state: AIStatusVisualization.AIState
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [state.color, state.color.opacity(0.6)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 10
                )
            )
            .frame(width: 12, height: 12)
            .scaleEffect(pulseScale)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseScale = 1.3
                }
            }
            .accessibilityLabel(state.accessibilityLabel)
    }
}

// MARK: - Preview

#Preview("AI Status States") {
    ZStack {
        RoxyGradients.background
            .ignoresSafeArea()

        VStack(spacing: RoxySpacing.xl) {
            // Idle
            VStack {
                AIStatusVisualization(state: .idle)
                Text("Idle")
                    .font(RoxyFonts.caption)
                    .foregroundColor(.white)
            }

            // Listening
            VStack {
                AIStatusVisualization(state: .listening)
                Text("Listening")
                    .font(RoxyFonts.caption)
                    .foregroundColor(.white)
            }

            // Thinking
            VStack {
                AIStatusVisualization(state: .thinking)
                Text("Thinking")
                    .font(RoxyFonts.caption)
                    .foregroundColor(.white)
            }

            // Acting
            VStack {
                AIStatusVisualization(state: .acting)
                Text("Acting")
                    .font(RoxyFonts.caption)
                    .foregroundColor(.white)
            }

            // Error
            VStack {
                AIStatusVisualization(state: .error)
                Text("Error")
                    .font(RoxyFonts.caption)
                    .foregroundColor(.white)
            }

            Divider()
                .background(Color.white.opacity(0.3))

            // Compact variants
            HStack(spacing: RoxySpacing.lg) {
                CompactAIStatus(state: .idle)
                CompactAIStatus(state: .listening)
                CompactAIStatus(state: .thinking)
                CompactAIStatus(state: .acting)
                CompactAIStatus(state: .error)
            }
        }
        .padding(RoxySpacing.xl)
    }
    .frame(width: 400, height: 800)
}
