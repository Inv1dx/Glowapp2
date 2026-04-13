import SwiftUI

struct RecapEntryCardView: View {
    @ObservedObject var viewModel: RecapViewModel

    var body: some View {
        HStack(alignment: .top, spacing: GlowSpacing.medium) {
            VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
                Text(viewModel.entryTitle)
                    .font(GlowTypography.sectionTitle)
                    .foregroundStyle(GlowColors.textPrimary)

                Text(viewModel.entrySubtitle)
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.entryDetail)
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: GlowSpacing.small)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GlowColors.textSecondary)
                .padding(.top, 4)
        }
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
