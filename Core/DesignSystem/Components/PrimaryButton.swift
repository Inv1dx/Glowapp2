import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GlowSpacing.xSmall) {
                if isLoading {
                    SwiftUI.ProgressView()
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(title)
                    .font(GlowTypography.button)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, GlowSpacing.small)
            .padding(.horizontal, GlowSpacing.medium)
            .background(isEnabled ? GlowColors.accent : GlowColors.textSecondary.opacity(0.35))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GlowSpacing.cornerRadius,
                    style: .continuous
                )
            )
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.75)
    }
}
