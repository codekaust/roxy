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
            .foregroundColor(isDisabled ? RoxyColors.mutedWhite : RoxyColors.neonWhite)
            .padding(RoxySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RoxyCornerRadius.lg)
                    .fill(RoxyColors.surfaceGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: RoxyCornerRadius.lg)
                            .stroke(
                                isDisabled ?
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [RoxyColors.neonCyan.opacity(0.4), RoxyColors.neonBlue.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: 0.5
                            )
                    )
            )
            .shadow(color: isDisabled ? .clear : RoxyColors.neonCyan.opacity(0.15), radius: 4, x: 0, y: 2)
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
