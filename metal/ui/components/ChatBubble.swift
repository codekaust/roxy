import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.type == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.type == .user ? .trailing : .leading, spacing: RoxySpacing.xs) {
                // Main message bubble
                Text(message.content)
                    .font(RoxyFonts.bodyLarge)
                    .foregroundColor(RoxyColors.neonWhite)
                    .padding(RoxySpacing.md)
                    .background(
                        ZStack {
                            // Dark base background
                            RoundedRectangle(cornerRadius: RoxyCornerRadius.lg)
                                .fill(RoxyColors.darkerGray)

                            // Neon gradient overlay
                            RoundedRectangle(cornerRadius: RoxyCornerRadius.lg)
                                .fill(bubbleGradient)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: RoxyCornerRadius.lg)
                            .strokeBorder(borderGradient, lineWidth: 2)
                    )
                    // Double shadow for aggressive neon glow
                    .shadow(color: shadowColor, radius: 15, x: 0, y: 0)
                    .shadow(color: shadowColor.opacity(0.5), radius: 20, x: 0, y: 0)

                // Status indicator for in-progress messages
                if message.status == .inProgress {
                    HStack(spacing: 4) {
                        ThinkingDotsAnimation()
                        Text("Processing...")
                            .font(RoxyFonts.caption)
                            .foregroundColor(RoxyColors.dimWhite)
                    }
                }

                // System logs (nested under AI responses)
                if message.type == .aiResponse && !message.systemLogs.isEmpty {
                    VStack(alignment: .leading, spacing: RoxySpacing.xs) {
                        ForEach(message.systemLogs) { log in
                            SystemLogBubble(log: log)
                        }
                    }
                    .padding(.leading, RoxySpacing.md)
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(RoxyFonts.caption2)
                    .foregroundColor(RoxyColors.dimWhite.opacity(0.7))
            }

            if message.type == .aiResponse {
                Spacer(minLength: 60)
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(x: hasAppeared ? 0 : (message.type == .user ? 20 : -20))
        .onAppear {
            if !reduceMotion {
                withAnimation(RoxyAnimation.slideIn.delay(0.1)) {
                    hasAppeared = true
                }
            } else {
                hasAppeared = true
            }
        }
    }

    // MARK: - Styling

    var bubbleGradient: LinearGradient {
        switch message.type {
        case .user:
            return LinearGradient(
                colors: [
                    RoxyColors.neonCyan.opacity(0.3),
                    RoxyColors.neonCyan.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .aiResponse:
            return LinearGradient(
                colors: [
                    RoxyColors.neonPurple.opacity(0.3),
                    RoxyColors.neonMagenta.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .system:
            return LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var borderGradient: LinearGradient {
        switch message.type {
        case .user:
            return LinearGradient(
                colors: [RoxyColors.neonCyan, RoxyColors.neonBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .aiResponse:
            return LinearGradient(
                colors: [RoxyColors.neonMagenta, RoxyColors.neonPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .system:
            return LinearGradient(
                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var shadowColor: Color {
        switch message.type {
        case .user: return RoxyColors.neonCyan.opacity(0.7)
        case .aiResponse: return RoxyColors.neonMagenta.opacity(0.7)
        case .system: return Color.clear
        }
    }
}
