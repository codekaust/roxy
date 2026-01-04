import SwiftUI

struct SystemLogBubble: View {
    let log: LogEntry
    @State private var hasAppeared = false

    var body: some View {
        HStack(alignment: .top, spacing: RoxySpacing.xs) {
            // Simple icon
            Image(systemName: iconForLogLevel(log.level))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(colorForLogLevel(log.level))
                .frame(width: 16)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(log.formattedMessage)
                    .font(RoxyFonts.caption)
                    .foregroundColor(RoxyColors.textSecondary)
                    .lineLimit(2)

                Text(log.timestamp, style: .time)
                    .font(.system(size: 10, design: .default))
                    .foregroundColor(RoxyColors.textTertiary)
            }
        }
        .padding(RoxySpacing.xs)
        .background(RoxyColors.surface)
        .cornerRadius(RoxyCornerRadius.sm)
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                hasAppeared = true
            }
        }
    }

    func colorForLogLevel(_ level: LogEntry.LogLevel) -> Color {
        switch level {
        case .thinking: return RoxyColors.info
        case .sensing: return RoxyColors.accent
        case .acting: return RoxyColors.warning
        case .success: return RoxyColors.success
        case .error: return RoxyColors.error
        case .warning: return RoxyColors.warning
        case .goal: return RoxyColors.success
        default: return RoxyColors.textSecondary
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
