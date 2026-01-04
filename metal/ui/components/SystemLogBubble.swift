import SwiftUI

struct SystemLogBubble: View {
    let log: LogEntry
    @State private var hasAppeared = false

    var body: some View {
        HStack(alignment: .top, spacing: RoxySpacing.xs) {
            // Icon with subtle accent
            Image(systemName: iconForLogLevel(log.level))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(colorForLogLevel(log.level))
                .frame(width: 16)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(log.formattedMessage)
                    .font(RoxyFonts.caption)
                    .foregroundColor(RoxyColors.dimWhite)
                    .lineLimit(2)

                Text(log.timestamp, style: .time)
                    .font(.system(size: 10, design: .default))
                    .foregroundColor(RoxyColors.mutedWhite)
            }
        }
        .padding(RoxySpacing.xs)
        .background(
            ZStack {
                // Dark refined base
                RoundedRectangle(cornerRadius: RoxyCornerRadius.sm)
                    .fill(RoxyColors.darkGray)

                // Very subtle colored overlay
                RoundedRectangle(cornerRadius: RoxyCornerRadius.sm)
                    .fill(Color(colorForLogLevel(log.level).opacity(0.08)))
                    .overlay(
                        RoundedRectangle(cornerRadius: RoxyCornerRadius.sm)
                            .strokeBorder(
                                colorForLogLevel(log.level).opacity(0.3),
                                lineWidth: 0.5
                            )
                    )
            }
        )
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.95)
        .onAppear {
            withAnimation(RoxyAnimation.fadeIn.delay(0.05)) {
                hasAppeared = true
            }
        }
    }

    func colorForLogLevel(_ level: LogEntry.LogLevel) -> Color {
        switch level {
        case .thinking: return RoxyColors.thinking
        case .sensing: return RoxyColors.cyan
        case .acting: return RoxyColors.acting
        case .success: return RoxyColors.success
        case .error: return RoxyColors.error
        case .warning: return RoxyColors.warning
        case .goal: return RoxyColors.lime
        default: return .secondary
        }
    }

    func iconForLogLevel(_ level: LogEntry.LogLevel) -> String {
        switch level {
        case .thinking: return "brain.head.profile"
        case .sensing: return "eye"
        case .acting: return "hand.tap"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .goal: return "flag.fill"
        default: return "circle.fill"
        }
    }
}
