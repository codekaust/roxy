import SwiftUI

struct ThinkingDotsAnimation: View {
    @State private var animationPhase = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(RoxyColors.neonMagenta)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.5 : 1.0)
                    .opacity(animationPhase == index ? 1.0 : 0.3)
                    .glow(color: RoxyColors.neonMagenta, radius: animationPhase == index ? 10 : 3)
            }
        }
        .onAppear {
            if !reduceMotion {
                startAnimation()
            }
        }
    }

    func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}
