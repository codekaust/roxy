import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        // ChatGPT-style: full-width with alternating backgrounds
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: RoxySpacing.md) {
                // Message content
                VStack(alignment: .leading, spacing: RoxySpacing.xs) {
                    Text(message.content)
                        .font(RoxyFonts.bodyLarge)
                        .foregroundColor(RoxyColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)

                    // Status indicator for in-progress messages
                    if message.status == .inProgress {
                        HStack(spacing: 4) {
                            ThinkingDotsAnimation()
                            Text("Processing...")
                                .font(RoxyFonts.caption)
                                .foregroundColor(RoxyColors.textSecondary)
                        }
                        .padding(.top, RoxySpacing.xs)
                    }

                    // System logs (nested under AI responses)
                    if message.type == .aiResponse && !message.systemLogs.isEmpty {
                        VStack(alignment: .leading, spacing: RoxySpacing.xs) {
                            ForEach(message.systemLogs) { log in
                                SystemLogBubble(log: log)
                            }
                        }
                        .padding(.top, RoxySpacing.sm)
                    }

                    // Timestamp
                    Text(message.timestamp, style: .time)
                        .font(RoxyFonts.caption2)
                        .foregroundColor(RoxyColors.textTertiary)
                        .padding(.top, RoxySpacing.xxs)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, RoxySpacing.lg)
            .padding(.vertical, RoxySpacing.lg)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
        }
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.2)) {
                    hasAppeared = true
                }
            } else {
                hasAppeared = true
            }
        }
    }

    // MARK: - Styling

    var backgroundColor: Color {
        switch message.type {
        case .user:
            return RoxyColors.backgroundAlt  // Slightly lighter for user messages
        case .aiResponse:
            return RoxyColors.background     // Main background for AI
        case .system:
            return RoxyColors.background
        }
    }
}
