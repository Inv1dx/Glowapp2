import SwiftUI

struct FeaturePlaceholderView: View {
    let title: String
    let message: String
    let highlights: [String]
    let buttonTitle: String
    let buttonSystemImage: String
    let onPrimaryAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlowSpacing.large) {
                header
                foundationCard

                PrimaryButton(
                    title: buttonTitle,
                    systemImage: buttonSystemImage,
                    action: onPrimaryAction
                )
            }
            .padding(GlowSpacing.screenPadding)
        }
        .background(GlowColors.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text(AppConstants.Shell.appName)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)

            Text(title)
                .font(GlowTypography.screenTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(message)
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var foundationCard: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            Text(AppConstants.Shell.foundationTitle)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            VStack(alignment: .leading, spacing: GlowSpacing.small) {
                ForEach(highlights, id: \.self) { highlight in
                    Label(highlight, systemImage: "checkmark.circle.fill")
                        .font(GlowTypography.body)
                        .foregroundStyle(GlowColors.textPrimary)
                }
            }

            Text(AppConstants.Shell.foundationMessage)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
}
