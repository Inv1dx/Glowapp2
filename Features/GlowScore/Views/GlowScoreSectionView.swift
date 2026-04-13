import SwiftUI

struct GlowScoreSectionView: View {
    @ObservedObject var viewModel: GlowScoreViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            header

            if viewModel.isLoading && viewModel.score == nil {
                loadingCard
            } else if let score = viewModel.score {
                scoreCard(score)
                breakdownCard(score)
                explanationsCard(score)
            } else {
                emptyStateCard
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text(viewModel.title)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(viewModel.subtitle)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
        }
    }

    private func scoreCard(_ score: GlowScore) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            HStack(alignment: .firstTextBaseline, spacing: GlowSpacing.medium) {
                Text(score.overallScore.formatted())
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(GlowColors.textPrimary)

                VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
                    Text("Overall score")
                        .font(GlowTypography.caption.weight(.semibold))
                        .foregroundStyle(GlowColors.textSecondary)

                    Text(viewModel.availabilityText)
                        .font(GlowTypography.caption)
                        .foregroundStyle(GlowColors.textSecondary)
                }
            }

            if score.availableWeight < score.totalWeight {
                Text("Missing categories stay out of the denominator instead of counting as zero.")
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)
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

    private func breakdownCard(_ score: GlowScore) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            ForEach(score.breakdowns) { breakdown in
                GlowScoreBreakdownRow(breakdown: breakdown)
            }
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

    private func explanationsCard(_ score: GlowScore) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text("Why this score")
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.textSecondary)

            ForEach(score.explanations, id: \.self) { explanation in
                HStack(alignment: .top, spacing: GlowSpacing.small) {
                    Circle()
                        .fill(GlowColors.accent)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    Text(explanation)
                        .font(GlowTypography.body)
                        .foregroundStyle(GlowColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

    private var loadingCard: some View {
        HStack(spacing: GlowSpacing.medium) {
            SwiftUI.ProgressView()
                .tint(GlowColors.accent)

            Text("Calculating today's Glow Score...")
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
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

    private var emptyStateCard: some View {
        Text("Glow Score will appear after today's data loads.")
            .font(GlowTypography.body)
            .foregroundStyle(GlowColors.textSecondary)
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

private struct GlowScoreBreakdownRow: View {
    let breakdown: GlowScoreCategoryBreakdown

    private var scoreText: String {
        if let score = breakdown.score {
            return score.formatted()
        }

        return "--"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: GlowSpacing.small) {
                Label(breakdown.category.title, systemImage: breakdown.category.systemImage)
                    .font(GlowTypography.caption.weight(.semibold))
                    .foregroundStyle(GlowColors.textSecondary)

                Spacer(minLength: GlowSpacing.small)

                Text(scoreText)
                    .font(GlowTypography.sectionTitle)
                    .foregroundStyle(GlowColors.textPrimary)
            }

            Text(breakdown.summaryText)
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Weight \(breakdown.weight.formatted())")
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, GlowSpacing.xSmall)
    }
}
