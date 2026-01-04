import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isDisabled: Bool
    let onSubmit: () -> Void
    let onVoiceToggle: () -> Void
    let isVoiceActive: Bool

    var body: some View {
        HStack(spacing: RoxySpacing.sm) {
            // Text Input
            TextField(
                isDisabled ? "Processing..." : "Type your message...",
                text: $text
            )
            .font(RoxyFonts.bodyLarge)
            .foregroundColor(isDisabled ? RoxyColors.textTertiary : RoxyColors.textPrimary)
            .padding(RoxySpacing.md)
            .background(RoxyColors.surface)
            .cornerRadius(RoxyCornerRadius.lg)
            .disabled(isDisabled)
            .onSubmit {
                if !isDisabled {
                    onSubmit()
                }
            }

            // Voice Button
            VoiceButton(isListening: Binding(
                get: { isVoiceActive },
                set: { _ in }
            )) {
                if !isDisabled {
                    onVoiceToggle()
                }
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)

            // Send Button
            FuturisticButton(
                icon: "arrow.up.circle.fill",
                variant: .primary,
                size: .medium
            ) {
                onSubmit()
            }
            .disabled(isDisabled || text.isEmpty)
            .opacity(isDisabled || text.isEmpty ? 0.5 : 1.0)
        }
        .padding(RoxySpacing.md)
        .background(RoxyColors.background)
    }
}
