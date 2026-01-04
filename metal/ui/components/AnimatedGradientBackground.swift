import SwiftUI
import Vortex

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @Binding var intensity: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Base gradient
            if reduceMotion {
                // Static gradient for reduce motion
                LinearGradient(
                    colors: [RoxyColors.pureBlack, RoxyColors.darkGray.opacity(0.5), RoxyColors.pureBlack],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                // Animated gradient
                LinearGradient(
                    colors: [
                        RoxyColors.pureBlack,
                        RoxyColors.darkGray.opacity(0.5),
                        RoxyColors.pureBlack
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .onAppear {
                    withAnimation(RoxyAnimation.gradientShift) {
                        animateGradient.toggle()
                    }
                }
            }

            // Particle overlay (only if intensity > 0.3 and motion not reduced)
            if intensity > 0.3 && !reduceMotion {
                VortexView(.fireflies) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2)
                        .tag("particle")
                }
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Simple Animated Background (No Binding)

struct SimpleAnimatedBackground: View {
    let intensity: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animateGradient = false

    init(intensity: Double = 0.5) {
        self.intensity = intensity
    }

    var body: some View {
        ZStack {
            // Base gradient
            if reduceMotion {
                LinearGradient(
                    colors: [RoxyColors.pureBlack, RoxyColors.darkGray.opacity(0.5), RoxyColors.pureBlack],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        RoxyColors.pureBlack,
                        RoxyColors.darkGray.opacity(0.5),
                        RoxyColors.pureBlack
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .onAppear {
                    withAnimation(RoxyAnimation.gradientShift) {
                        animateGradient.toggle()
                    }
                }
            }

            // Particle overlay
            if intensity > 0.3 && !reduceMotion {
                VortexView(.fireflies) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2)
                        .tag("particle")
                }
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview("Animated Backgrounds") {
    VStack(spacing: 0) {
        // Low intensity
        ZStack {
            AnimatedGradientBackground(intensity: .constant(0.2))

            VStack {
                Text("Low Intensity")
                    .font(RoxyFonts.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("No particles")
                    .font(RoxyFonts.body)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(height: 300)

        // High intensity
        ZStack {
            AnimatedGradientBackground(intensity: .constant(0.8))

            VStack {
                Text("High Intensity")
                    .font(RoxyFonts.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("With particles")
                    .font(RoxyFonts.body)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(height: 300)
    }
}
