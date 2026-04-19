import SwiftUI

struct GlowScoreSectionView: View {
    @ObservedObject var viewModel: GlowScoreViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            header

            if viewModel.isLoading && viewModel.score == nil {
                GlowScoreLoadingCardView()
            } else if let score = viewModel.score {
                GlowScoreHeroCardView(score: score)
                GlowScoreBreakdownCardView(score: score)
            } else {
                GlowScoreEmptyStateCardView()
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
}

struct GlowScoreSurfaceCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
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

private struct GlowScoreLoadingCardView: View {
    var body: some View {
        GlowScoreSurfaceCard {
            HStack(spacing: GlowSpacing.medium) {
                SwiftUI.ProgressView()
                    .tint(GlowColors.accent)

                Text("Calculating today's Glow Score...")
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textSecondary)
            }
        }
    }
}

private struct GlowScoreEmptyStateCardView: View {
    var body: some View {
        GlowScoreSurfaceCard {
            Text("Glow Score appears as today's inputs arrive.")
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
        }
    }
}
