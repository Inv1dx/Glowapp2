import SwiftUI

struct RecapView: View {
    @ObservedObject var viewModel: RecapViewModel

    private let columns = [
        GridItem(.flexible(), spacing: GlowSpacing.medium),
        GridItem(.flexible(), spacing: GlowSpacing.medium)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlowSpacing.large) {
                header

                if viewModel.isLoading && viewModel.recap == nil {
                    loadingCard
                } else if let recap = viewModel.recap {
                    summaryCard(recap)
                    metricsSection(recap)
                    energySection(recap)
                    routinesSection(recap)
                    glowScoreSection(recap)
                    recommendationCard(recap)
                } else {
                    emptyStateCard
                }
            }
            .padding(GlowSpacing.screenPadding)
        }
        .background(GlowColors.background.ignoresSafeArea())
        .navigationTitle(viewModel.navigationTitle)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text(viewModel.title)
                .font(GlowTypography.screenTitle)
                .foregroundStyle(GlowColors.textPrimary)

            if let recap = viewModel.recap {
                Text(viewModel.formattedDate(for: recap.date))
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textSecondary)
            } else {
                Text("Tonight's snapshot")
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textSecondary)
            }
        }
    }

    private func summaryCard(_ recap: DailyRecap) -> some View {
        Text(recap.summaryMessage)
            .font(GlowTypography.sectionTitle)
            .foregroundStyle(GlowColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GlowSpacing.cardPadding)
            .background(GlowColors.accentMuted)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GlowSpacing.cornerRadius,
                    style: .continuous
                )
            )
    }

    private func metricsSection(_ recap: DailyRecap) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            sectionHeader(
                title: "Key metrics",
                subtitle: "The core outputs from today."
            )

            LazyVGrid(columns: columns, spacing: GlowSpacing.medium) {
                RecapMetricCardView(
                    title: "Calories in",
                    valueText: caloriesInValueText(for: recap),
                    detailText: caloriesInDetailText(for: recap),
                    systemImage: "fork.knife"
                )
                RecapMetricCardView(
                    title: "Steps",
                    valueText: stepsValueText(for: recap),
                    detailText: stepsDetailText(for: recap),
                    systemImage: "figure.walk"
                )
                RecapMetricCardView(
                    title: "Routines",
                    valueText: routinesValueText(for: recap),
                    detailText: "Completed today",
                    systemImage: "checklist"
                )
                RecapMetricCardView(
                    title: "Glow Score",
                    valueText: glowScoreValueText(for: recap),
                    detailText: glowScoreDetailText(for: recap),
                    systemImage: "sparkles"
                )
            }
        }
    }

    private func energySection(_ recap: DailyRecap) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            sectionHeader(
                title: "Estimated energy balance",
                subtitle: "Simple end-of-day estimates, not exact metabolism."
            )

            VStack(alignment: .leading, spacing: GlowSpacing.medium) {
                RecapStatRow(
                    title: "Calories in",
                    valueText: caloriesInValueText(for: recap),
                    detailText: caloriesInDetailText(for: recap)
                )
                RecapStatRow(
                    title: "Calories out (estimate)",
                    valueText: caloriesOutValueText(for: recap),
                    detailText: recap.energyBalance.caloriesOutExplanation
                )
                RecapStatRow(
                    title: "Deficit / surplus (estimate)",
                    valueText: balanceValueText(for: recap),
                    detailText: recap.energyBalance.balanceExplanation
                )
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

    private func routinesSection(_ recap: DailyRecap) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            sectionHeader(
                title: "Routines completed",
                subtitle: "The repeatables that stayed closed today."
            )

            VStack(alignment: .leading, spacing: GlowSpacing.medium) {
                HStack(spacing: GlowSpacing.small) {
                    ForEach(recap.routineSummary.statuses) { status in
                        RoutineStatusBadge(status: status)
                    }
                }

                Text("\(recap.routineSummary.statuses.filter(\.isCompleted).count.formatted()) of \(recap.routineSummary.statuses.count.formatted()) routines completed")
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textPrimary)
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

    private func glowScoreSection(_ recap: DailyRecap) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            sectionHeader(
                title: "Today's Glow Score",
                subtitle: "The recap still works even when parts of the score are missing."
            )

            VStack(alignment: .leading, spacing: GlowSpacing.small) {
                HStack(alignment: .firstTextBaseline, spacing: GlowSpacing.medium) {
                    Text(glowScoreValueText(for: recap))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(GlowColors.textPrimary)

                    Text(glowScoreDetailText(for: recap))
                        .font(GlowTypography.caption)
                        .foregroundStyle(GlowColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let weakestArea = recap.weakestArea {
                    Text("Softest area: \(weakestArea.title)")
                        .font(GlowTypography.caption.weight(.semibold))
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
    }

    private func recommendationCard(_ recap: DailyRecap) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text("For tomorrow")
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.textSecondary)

            Text(recap.recommendationText)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowSpacing.cardPadding)
        .background(GlowColors.accentMuted)
        .clipShape(
            RoundedRectangle(
                cornerRadius: GlowSpacing.cornerRadius,
                style: .continuous
            )
        )
    }

    private var loadingCard: some View {
        HStack(spacing: GlowSpacing.medium) {
            SwiftUI.ProgressView()
                .tint(GlowColors.accent)

            Text("Building tonight's recap...")
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
        Text("The recap will appear once today's dashboard, nutrition, and routine data finish loading.")
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

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text(title)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(subtitle)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
        }
    }

    private func caloriesInValueText(for recap: DailyRecap) -> String {
        if let caloriesIn = recap.energyBalance.caloriesIn {
            return "\(caloriesIn.formatted()) kcal"
        }

        return "Not logged"
    }

    private func caloriesInDetailText(for recap: DailyRecap) -> String {
        if recap.energyBalance.caloriesIn != nil {
            return "Logged today"
        }

        return "No calorie entries"
    }

    private func stepsValueText(for recap: DailyRecap) -> String {
        if recap.unsupportedHealthFields.contains(.steps) {
            return "Unavailable"
        }

        if recap.limitedHealthFields.contains(.steps) {
            return "Check access"
        }

        guard let metrics = recap.metrics else {
            switch recap.metricsConnectionState {
            case .notConnected:
                return "Connect Health"
            case .needsAttention:
                return "Need access"
            case .unavailable:
                return "Unavailable"
            case .connected:
                return "No data"
            }
        }

        return metrics.steps.formatted()
    }

    private func stepsDetailText(for recap: DailyRecap) -> String {
        if recap.metrics != nil, !recap.limitedHealthFields.contains(.steps), !recap.unsupportedHealthFields.contains(.steps) {
            return "Today"
        }

        switch recap.metricsConnectionState {
        case .connected:
            return "Step data missing"
        case .notConnected:
            return "Health data not connected"
        case .needsAttention:
            return "Health data limited"
        case .unavailable:
            return "Apple Health unavailable"
        }
    }

    private func routinesValueText(for recap: DailyRecap) -> String {
        let completed = recap.routineSummary.statuses.filter(\.isCompleted).count
        return "\(completed.formatted()) / \(recap.routineSummary.statuses.count.formatted())"
    }

    private func glowScoreValueText(for recap: DailyRecap) -> String {
        if let glowScore = recap.glowScore {
            return glowScore.overallScore.formatted()
        }

        return "--"
    }

    private func glowScoreDetailText(for recap: DailyRecap) -> String {
        if let glowScore = recap.glowScore {
            return "\(glowScore.availableCategoriesCount.formatted()) of \(GlowScoreCategory.allCases.count.formatted()) categories available"
        }

        return "Glow Score unavailable. Recap uses the data that did load."
    }

    private func caloriesOutValueText(for recap: DailyRecap) -> String {
        if let caloriesOut = recap.energyBalance.estimatedCaloriesOut {
            return "\(caloriesOut.formatted()) kcal"
        }

        return "Unavailable"
    }

    private func balanceValueText(for recap: DailyRecap) -> String {
        switch recap.energyBalance.balanceState {
        case .deficit:
            return "Deficit \(recap.energyBalance.balanceAmount?.formatted() ?? "--") kcal"
        case .surplus:
            return "Surplus \(recap.energyBalance.balanceAmount?.formatted() ?? "--") kcal"
        case .neutral:
            return "Neutral"
        case .unavailable:
            return "Unavailable"
        }
    }
}

private struct RecapMetricCardView: View {
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

private struct RecapStatRow: View {
    let title: String
    let valueText: String
    let detailText: String

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: GlowSpacing.small) {
                Text(title)
                    .font(GlowTypography.caption.weight(.semibold))
                    .foregroundStyle(GlowColors.textSecondary)

                Spacer(minLength: GlowSpacing.small)

                Text(valueText)
                    .font(GlowTypography.body.weight(.semibold))
                    .foregroundStyle(GlowColors.textPrimary)
                    .multilineTextAlignment(.trailing)
            }

            Text(detailText)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct RoutineStatusBadge: View {
    let status: RoutineDaySummary.Status

    var body: some View {
        Text(status.template.shortTitle)
            .font(GlowTypography.caption.weight(.semibold))
            .foregroundStyle(status.isCompleted ? GlowColors.accent : GlowColors.textSecondary)
            .padding(.horizontal, GlowSpacing.medium)
            .padding(.vertical, GlowSpacing.xSmall)
            .background(status.isCompleted ? GlowColors.accentMuted : GlowColors.background)
            .clipShape(Capsule())
    }
}
