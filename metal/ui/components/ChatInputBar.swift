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
            .foregroundColor(isDisabled ? RoxyColors.dimWhite : RoxyColors.neonWhite)
            .padding(RoxySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RoxyCornerRadius.lg)
                    .fill(RoxyColors.darkerGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: RoxyCornerRadius.lg)
                            .stroke(
                                isDisabled ?
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    RoxyGradients.neonBorderCyan,
                                lineWidth: 2
                            )
                    )
            )
            .glow(color: isDisabled ? .clear : RoxyColors.neonCyan, radius: 10)
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
        .darkGlassEffect(
            tint: RoxyColors.neonCyan,
            neonBorder: RoxyGradients.neonBorderCyan,
            opacity: 0.2
        )
    }
}
