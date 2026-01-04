import SwiftUI

// MARK: - Roxy Animation Presets

struct RoxyAnimation {
    // Standard spring animation for most UI interactions
    static let spring = Animation.spring(response: 0.6, dampingFraction: 0.7)

    // Smoother spring for transitions and page changes
    static let smoothSpring = Animation.spring(response: 0.8, dampingFraction: 0.75)

    // Quick spring for button presses and micro-interactions
    static let quickSpring = Animation.spring(response: 0.4, dampingFraction: 0.6)

    // Playful bounce for emphasis
    static let bounce = Animation.spring(response: 0.5, dampingFraction: 0.5)

    // Breathing/pulsing animation (auto-reversing)
    static let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)

    // Fast pulse for active states
    static let fastPulse = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)

    // Slow pulse for idle/subtle effects
    static let slowPulse = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)

    // Fade in with scale
    static let fadeIn = Animation.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)

    // Slide in animation
    static let slideIn = Animation.spring(response: 0.5, dampingFraction: 0.8)

    // Smooth rotation
    static let rotate = Animation.linear(duration: 3).repeatForever(autoreverses: false)

    // Gradient animation (for backgrounds)
    static let gradientShift = Animation.linear(duration: 8).repeatForever(autoreverses: true)

    // Shimmer animation
    static let shimmer = Animation.linear(duration: 2).repeatForever(autoreverses: false)

    // Button press animation
    static let buttonPress = Animation.spring(response: 0.3, dampingFraction: 0.6)

    // Modal presentation
    static let modal = Animation.spring(response: 0.6, dampingFraction: 0.85)
}

// MARK: - Animation Timing Functions

struct RoxyTiming {
    static let instant: Double = 0.0
    static let veryFast: Double = 0.15
    static let fast: Double = 0.25
    static let normal: Double = 0.4
    static let slow: Double = 0.6
    static let verySlow: Double = 1.0
}

// MARK: - Stagger Animation Helper

struct StaggeredAnimation {
    static func delay(for index: Int, baseDelay: Double = 0.05) -> Double {
        return Double(index) * baseDelay
    }

    static func animation(for index: Int, baseAnimation: Animation = RoxyAnimation.spring, baseDelay: Double = 0.05) -> Animation {
        return baseAnimation.delay(delay(for: index, baseDelay: baseDelay))
    }
}

// MARK: - Custom Animation Curves

extension Animation {
    // Custom cubic bezier curves for specific effects
    static let roxyEaseOut = Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: RoxyTiming.normal)
    static let roxyEaseIn = Animation.timingCurve(0.42, 0.0, 1.0, 1.0, duration: RoxyTiming.normal)
    static let roxyEaseInOut = Animation.timingCurve(0.42, 0.0, 0.58, 1.0, duration: RoxyTiming.normal)

    // Smooth deceleration
    static let roxyDecelerate = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: RoxyTiming.slow)

    // Quick acceleration
    static let roxyAccelerate = Animation.timingCurve(0.4, 0.0, 1.0, 1.0, duration: RoxyTiming.fast)
}

// MARK: - Transition Presets

struct RoxyTransition {
    // Fade with scale
    static let fadeScale = AnyTransition.scale.combined(with: .opacity)

    // Slide from right
    static let slideFromRight = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )

    // Slide from bottom
    static let slideFromBottom = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )

    // Slide from top
    static let slideFromTop = AnyTransition.asymmetric(
        insertion: .move(edge: .top).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity)
    )

    // Scale and fade (for modals)
    static let modal = AnyTransition.scale(scale: 0.95).combined(with: .opacity)

    // Push (like navigation)
    static let push = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )
}

// MARK: - Animation State Manager

class AnimationStateManager: ObservableObject {
    @Published var reduceMotion: Bool = false

    init() {
        // Check system preference for reduce motion
        #if os(macOS)
        self.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #endif
    }

    // Get animation with reduce motion consideration
    func animation(_ animation: Animation) -> Animation? {
        return reduceMotion ? nil : animation
    }

    // Get transition with reduce motion consideration
    func transition(_ transition: AnyTransition) -> AnyTransition {
        return reduceMotion ? .opacity : transition
    }
}

// MARK: - Animated Number Modifier

struct AnimatedNumber: ViewModifier {
    let value: Double
    @State private var displayValue: Double = 0

    func body(content: Content) -> some View {
        content
            .onAppear {
                withAnimation(RoxyAnimation.smoothSpring) {
                    displayValue = value
                }
            }
            .onChange(of: value) { oldValue, newValue in
                withAnimation(RoxyAnimation.smoothSpring) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Shake Animation Modifier

struct ShakeEffect: ViewModifier {
    @Binding var shakes: Int

    func body(content: Content) -> some View {
        content
            .offset(x: shakes > 0 ? CGFloat(sin(Double(shakes) * .pi * 2) * 5) : 0)
            .onChange(of: shakes) { oldValue, newValue in
                if newValue > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shakes = 0
                    }
                }
            }
    }
}

extension View {
    func shake(count: Binding<Int>) -> some View {
        self.modifier(ShakeEffect(shakes: count))
    }
}

// MARK: - Pulsing Scale Effect

struct PulsingScale: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double

    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? maxScale : minScale)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func pulsingScale(from minScale: CGFloat = 1.0, to maxScale: CGFloat = 1.1, duration: Double = 1.5) -> some View {
        self.modifier(PulsingScale(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Rotation Effect

struct RotationEffect: ViewModifier {
    let duration: Double
    let clockwise: Bool

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = clockwise ? 360 : -360
                }
            }
    }
}

extension View {
    func continuousRotation(duration: Double = 3.0, clockwise: Bool = true) -> some View {
        self.modifier(RotationEffect(duration: duration, clockwise: clockwise))
    }
}
