import Charts
import SwiftUI

struct ProgressTrendCardView: View {
    let title: String
    let subtitle: String
    let points: [ProgressTrendPoint]
    let accentColor: Color
    let emptyMessage: String
    let valueFormatter: (Double) -> String

    var body: some View {
        ProgressCardContainer {
            VStack(alignment: .leading, spacing: GlowSpacing.medium) {
                HStack(alignment: .firstTextBaseline, spacing: GlowSpacing.medium) {
                    VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
                        Text(title)
                            .font(GlowTypography.sectionTitle)
                            .foregroundStyle(GlowColors.textPrimary)

                        Text(subtitle)
                            .font(GlowTypography.caption)
                            .foregroundStyle(GlowColors.textSecondary)
                    }

                    Spacer(minLength: GlowSpacing.small)

                    if let latestValue = points.last?.value {
                        Text(valueFormatter(latestValue))
                            .font(GlowTypography.body.weight(.semibold))
                            .foregroundStyle(accentColor)
                    }
                }

                if points.count >= 2 {
                    Chart(points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(accentColor)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.22),
                                    accentColor.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(accentColor)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 3))
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 180)
                } else if let point = points.last {
                    VStack(alignment: .leading, spacing: GlowSpacing.small) {
                        Text(valueFormatter(point.value))
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(GlowColors.textPrimary)

                        Text("One saved point so far. Add another check-in to see the trend line.")
                            .font(GlowTypography.caption)
                            .foregroundStyle(GlowColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(emptyMessage)
                        .font(GlowTypography.body)
                        .foregroundStyle(GlowColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
