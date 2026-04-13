import SwiftUI

struct DashboardMetricCardView: View {
    let title: String
    let valueText: String
    let detailText: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Label(title, systemImage: systemImage)
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.textSecondary)

            Text(valueText)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(detailText)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
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
