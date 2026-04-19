import SwiftUI

struct GlowScoreBreakdownCardView: View {
    let score: GlowScore

    var body: some View {
        GlowScoreSurfaceCard {
            VStack(alignment: .leading, spacing: GlowSpacing.medium) {
                Text("Input readout")
                    .font(GlowTypography.caption.weight(.semibold))
                    .foregroundStyle(GlowColors.textSecondary)

                ForEach(Array(score.orderedBreakdowns.enumerated()), id: \.element.id) { index, breakdown in
                    GlowScoreBreakdownRowView(breakdown: breakdown)

                    if index < score.orderedBreakdowns.count - 1 {
                        Divider()
                            .overlay(GlowColors.border)
                    }
                }
            }
        }
    }
}

private struct GlowScoreBreakdownRowView: View {
    let breakdown: GlowScoreCategoryBreakdown

    private var iconTint: Color {
        breakdown.status == .available ? GlowColors.accent : GlowColors.textSecondary
    }

    private var iconBackground: Color {
        breakdown.status == .available ? GlowColors.accentMuted : GlowColors.background
    }

    var body: some View {
        HStack(alignment: .top, spacing: GlowSpacing.medium) {
            Image(systemName: breakdown.category.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(iconTint)
                .frame(width: 36, height: 36)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(breakdown.category.title)
                    .font(GlowTypography.body.weight(.semibold))
                    .foregroundStyle(GlowColors.textPrimary)

                Text(breakdown.summaryText)
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: GlowSpacing.small)

            trailingValue
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var trailingValue: some View {
        if let score = breakdown.score {
            Text(score.formatted())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(GlowColors.textPrimary)
                .accessibilityHidden(true)
        } else {
            Text(statusTitle)
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(statusForeground)
                .padding(.horizontal, GlowSpacing.small)
                .padding(.vertical, GlowSpacing.xSmall)
                .background(statusBackground)
                .clipShape(Capsule())
        }
    }

    private var statusTitle: String {
        switch breakdown.dataState {
        case .missing:
            "Missing"
        case .unavailable:
            breakdown.connectsAppleHealth ? "Connect" : "Unavailable"
        case .available:
            "Ready"
        }
    }

    private var statusForeground: Color {
        switch breakdown.dataState {
        case .missing:
            GlowColors.textPrimary
        case .unavailable:
            breakdown.connectsAppleHealth ? GlowColors.accent : GlowColors.textSecondary
        case .available:
            GlowColors.accent
        }
    }

    private var statusBackground: Color {
        switch breakdown.dataState {
        case .missing:
            GlowColors.background
        case .unavailable:
            breakdown.connectsAppleHealth ? GlowColors.accentMuted : GlowColors.background
        case .available:
            GlowColors.accentMuted
        }
    }
}
