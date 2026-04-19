import SwiftUI

struct GlowScoreSegmentedRingView: View {
    let breakdowns: [GlowScoreCategoryBreakdown]

    private let lineWidth: CGFloat = 14
    private let gapFraction: Double = 0.02

    var body: some View {
        ZStack {
            ForEach(Array(breakdowns.enumerated()), id: \.element.id) { index, breakdown in
                let segment = segmentRange(for: index, count: breakdowns.count)

                Circle()
                    .trim(from: segment.lowerBound, to: segment.upperBound)
                    .stroke(
                        trackColor(for: breakdown),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                if let progressEnd = progressEnd(for: breakdown, in: segment) {
                    Circle()
                        .trim(from: segment.lowerBound, to: progressEnd)
                        .stroke(
                            progressColor(for: breakdown),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }

    private func segmentRange(for index: Int, count: Int) -> ClosedRange<Double> {
        let span = 1 / Double(max(count, 1))
        let start = (Double(index) * span) + (gapFraction / 2)
        let end = (Double(index + 1) * span) - (gapFraction / 2)
        return start...end
    }

    private func progressEnd(
        for breakdown: GlowScoreCategoryBreakdown,
        in segment: ClosedRange<Double>
    ) -> Double? {
        guard breakdown.status == .available, let score = breakdown.score else {
            return nil
        }

        let progress = min(max(Double(score) / 100, 0), 1)
        guard progress > 0 else {
            return nil
        }

        return segment.lowerBound + ((segment.upperBound - segment.lowerBound) * progress)
    }

    private func trackColor(for breakdown: GlowScoreCategoryBreakdown) -> Color {
        switch breakdown.dataState {
        case .available:
            return GlowColors.accent.opacity(0.14)
        case .missing:
            return GlowColors.textSecondary.opacity(0.12)
        case .unavailable:
            return GlowColors.textSecondary.opacity(0.08)
        }
    }

    private func progressColor(for breakdown: GlowScoreCategoryBreakdown) -> Color {
        let score = breakdown.score ?? 0

        switch score {
        case 80...:
            return GlowColors.accent
        case 60..<80:
            return GlowColors.accent.opacity(0.9)
        case 40..<60:
            return GlowColors.accent.opacity(0.72)
        default:
            return GlowColors.textSecondary.opacity(0.45)
        }
    }
}

struct GlowScoreCategoryStatusStrip: View {
    let breakdowns: [GlowScoreCategoryBreakdown]

    private let wrappedColumns = [
        GridItem(.adaptive(minimum: 108), spacing: GlowSpacing.xSmall)
    ]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: GlowSpacing.xSmall) {
                ForEach(breakdowns) { breakdown in
                    GlowScoreCategoryStatusChip(breakdown: breakdown)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: wrappedColumns, alignment: .leading, spacing: GlowSpacing.xSmall) {
                ForEach(breakdowns) { breakdown in
                    GlowScoreCategoryStatusChip(breakdown: breakdown)
                }
            }
        }
    }
}

private struct GlowScoreCategoryStatusChip: View {
    let breakdown: GlowScoreCategoryBreakdown

    private var textColor: Color {
        breakdown.status == .available ? GlowColors.textPrimary : GlowColors.textSecondary
    }

    private var dotColor: Color {
        if breakdown.status == .available {
            let score = breakdown.score ?? 0

            switch score {
            case 80...:
                return GlowColors.accent
            case 60..<80:
                return GlowColors.accent.opacity(0.85)
            default:
                return GlowColors.textPrimary.opacity(0.55)
            }
        }

        if breakdown.dataState == .missing {
            return GlowColors.textSecondary.opacity(0.22)
        }

        return GlowColors.textSecondary.opacity(0.14)
    }

    private var backgroundColor: Color {
        breakdown.status == .available ? GlowColors.accentMuted.opacity(0.72) : GlowColors.surface.opacity(0.74)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: breakdown.category.systemImage)
                .font(.system(size: 11, weight: .semibold))

            Text(breakdown.category.shortTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
        }
        .font(GlowTypography.caption.weight(.semibold))
        .foregroundStyle(textColor)
        .padding(.horizontal, GlowSpacing.small)
        .padding(.vertical, GlowSpacing.xSmall + 1)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(GlowColors.border, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(breakdown.category.title), \(breakdown.accessibilityStatusLabel)")
    }
}

struct GlowScoreInsightRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: GlowSpacing.medium) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GlowColors.accent)
                .frame(width: 34, height: 34)
                .background(GlowColors.accentMuted)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Biggest lever")
                    .font(GlowTypography.caption.weight(.semibold))
                    .foregroundStyle(GlowColors.textSecondary)

                Text(text)
                    .font(GlowTypography.body.weight(.semibold))
                    .foregroundStyle(GlowColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: GlowSpacing.small)
        }
        .padding(GlowSpacing.medium)
        .background(GlowColors.surface.opacity(0.84))
        .clipShape(
            RoundedRectangle(
                cornerRadius: GlowSpacing.cornerRadius - 4,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: GlowSpacing.cornerRadius - 4,
                style: .continuous
            )
            .stroke(GlowColors.border, lineWidth: 1)
        )
    }
}

struct GlowScoreHeroBackground: View {
    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: GlowSpacing.cornerRadius,
            style: .continuous
        )

        shape
            .fill(
                LinearGradient(
                    colors: [
                        GlowColors.surface,
                        GlowColors.background.opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(GlowColors.accentMuted.opacity(0.92))
                    .frame(width: 190, height: 190)
                    .blur(radius: 12)
                    .offset(x: 56, y: -84)
            }
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(GlowColors.accent.opacity(0.07))
                    .frame(width: 144, height: 144)
                    .blur(radius: 14)
                    .offset(x: -54, y: 72)
            }
            .clipShape(shape)
            .overlay(
                shape
                    .stroke(GlowColors.border, lineWidth: 1)
            )
    }
}
