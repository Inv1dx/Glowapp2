import SwiftUI

struct GlowScoreHeroCardView: View {
    let score: GlowScore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var scoreFontSize = 56

    private var heroState: GlowScoreHeroState {
        GlowScoreHeroState(score: score)
    }

    private var radialSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 192 : 216
    }

    private var ringSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 160 : 180
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.large) {
            HStack(alignment: .top, spacing: GlowSpacing.medium) {
                Text("Glow Score")
                    .font(GlowTypography.caption.weight(.semibold))
                    .foregroundStyle(GlowColors.textSecondary)

                Spacer(minLength: GlowSpacing.small)

                GlowScoreAvailabilityBadge(score: score)
            }

            GlowScoreRadialHeroView(
                score: score,
                heroState: heroState,
                scoreFontSize: scoreFontSize,
                radialSize: radialSize,
                ringSize: ringSize
            )

            Text(score.availabilityDetailText)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            GlowScoreCategoryStatusStrip(breakdowns: score.orderedBreakdowns)
            GlowScoreInsightRow(text: score.biggestLeverText)
        }
        .padding(GlowSpacing.xLarge)
        .background(GlowScoreHeroBackground())
    }
}

private struct GlowScoreAvailabilityBadge: View {
    let score: GlowScore

    private var foregroundColor: Color {
        switch score.availabilityKind {
        case .complete:
            GlowColors.accent
        case .partial:
            GlowColors.textPrimary
        case .empty:
            GlowColors.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch score.availabilityKind {
        case .complete:
            GlowColors.accentMuted
        case .partial:
            GlowColors.surface.opacity(0.85)
        case .empty:
            GlowColors.background
        }
    }

    var body: some View {
        Text(score.availabilityBadgeTitle)
            .font(GlowTypography.caption.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, GlowSpacing.medium)
            .padding(.vertical, GlowSpacing.xSmall)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(GlowColors.border, lineWidth: 1)
            )
    }
}

private struct GlowScoreRadialHeroView: View {
    let score: GlowScore
    let heroState: GlowScoreHeroState
    let scoreFontSize: CGFloat
    let radialSize: CGFloat
    let ringSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(GlowColors.surface.opacity(0.94))
                .frame(width: radialSize, height: radialSize)
                .overlay(
                    Circle()
                        .stroke(GlowColors.border, lineWidth: 1)
                )

            GlowScoreSegmentedRingView(breakdowns: score.orderedBreakdowns)
                .frame(width: ringSize, height: ringSize)

            VStack(spacing: GlowSpacing.xSmall) {
                Text(score.displayScoreText)
                    .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(GlowColors.textPrimary)
                    .minimumScaleFactor(0.6)

                Text(heroState.label)
                    .font(GlowTypography.body.weight(.semibold))
                    .foregroundStyle(heroState.labelColor)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, GlowSpacing.medium)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's Glow Score")
        .accessibilityValue(score.accessibilitySummary(stateLabel: heroState.label))
    }
}
