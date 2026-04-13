import SwiftUI

struct HealthConnectionCardView: View {
    let title: String
    let message: String
    let systemImage: String
    var primaryButtonTitle: String? = nil
    var isPrimaryLoading = false
    var secondaryButtonTitle: String? = nil
    var onPrimaryAction: (() -> Void)? = nil
    var onSecondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            icon

            VStack(alignment: .leading, spacing: GlowSpacing.small) {
                Text(title)
                    .font(GlowTypography.sectionTitle)
                    .foregroundStyle(GlowColors.textPrimary)

                Text(message)
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let primaryButtonTitle, let onPrimaryAction {
                PrimaryButton(
                    title: primaryButtonTitle,
                    systemImage: "heart.fill",
                    isLoading: isPrimaryLoading,
                    action: onPrimaryAction
                )
            }

            if let secondaryButtonTitle, let onSecondaryAction {
                Button(secondaryButtonTitle, action: onSecondaryAction)
                    .buttonStyle(.plain)
                    .font(GlowTypography.caption.weight(.semibold))
                    .foregroundStyle(GlowColors.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowSpacing.cardPadding)
        .background(GlowColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: GlowSpacing.cornerRadius,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: GlowSpacing.cornerRadius,
                style: .continuous
            )
            .stroke(GlowColors.border, lineWidth: 1)
        )
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(GlowColors.accent)
            .frame(width: 48, height: 48)
            .background(GlowColors.accentMuted)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
