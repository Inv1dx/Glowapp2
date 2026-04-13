import SwiftUI

struct DashboardView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel
    @ObservedObject var nutritionViewModel: NutritionViewModel
    @ObservedObject var routinesViewModel: RoutinesViewModel
    @ObservedObject var glowScoreViewModel: GlowScoreViewModel
    @ObservedObject var dailyPlanViewModel: DailyPlanViewModel
    let onRefresh: () async -> Void
    let onOpenSettings: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: GlowSpacing.medium),
        GridItem(.flexible(), spacing: GlowSpacing.medium)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlowSpacing.large) {
                header
                GlowScoreSectionView(viewModel: glowScoreViewModel)
                DailyPlanSectionView(viewModel: dailyPlanViewModel)
                healthSection
                manualMetricsSection
                NutritionQuickLogCardView(viewModel: nutritionViewModel)
            }
            .padding(GlowSpacing.screenPadding)
        }
        .background(GlowColors.background.ignoresSafeArea())
        .refreshable {
            await onRefresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text(AppConstants.Shell.appName)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)

            Text(dashboardViewModel.title)
                .font(GlowTypography.screenTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(dashboardViewModel.subtitle)
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            SectionHeaderView(
                title: "Today's health data",
                subtitle: "Read-only Apple Health inputs."
            )

            if !dashboardViewModel.hasLoadedOnce {
                loadingCard
            } else {
                if dashboardViewModel.showsStatusCard {
                    statusCard
                }

                if let sourceMessage = dashboardViewModel.sourceMessage {
                    sourceBadge(message: sourceMessage)
                }

                if let limitedAccessMessage = dashboardViewModel.limitedAccessMessage {
                    noticeCard(message: limitedAccessMessage)
                }

                if dashboardViewModel.showsMetrics {
                    metricsGrid(cards: healthMetricCards)
                }
            }
        }
    }

    private var manualMetricsSection: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            SectionHeaderView(
                title: "Manual totals",
                subtitle: "Same-day nutrition, water, and routine states."
            )

            metricsGrid(cards: manualMetricCards)
        }
    }

    private var statusCard: some View {
        HealthConnectionCardView(
            title: dashboardViewModel.statusCardTitle,
            message: dashboardViewModel.statusCardMessage,
            systemImage: dashboardViewModel.statusCardSystemImage,
            primaryButtonTitle: dashboardViewModel.statusCardButtonTitle,
            isPrimaryLoading: dashboardViewModel.isRequestingAccess,
            secondaryButtonTitle: dashboardViewModel.showsSettingsAction ? "Open Settings" : nil,
            onPrimaryAction: primaryStatusAction,
            onSecondaryAction: dashboardViewModel.showsSettingsAction ? onOpenSettings : nil
        )
    }

    private func metricsGrid(cards: [DashboardCardContent]) -> some View {
        LazyVGrid(columns: columns, spacing: GlowSpacing.medium) {
            ForEach(cards) { card in
                DashboardMetricCardView(
                    title: card.title,
                    valueText: card.valueText,
                    detailText: card.detailText,
                    systemImage: card.systemImage
                )
            }
        }
    }

    private var healthMetricCards: [DashboardCardContent] {
        dashboardViewModel.metricCards.map {
            DashboardCardContent(
                id: $0.id.rawValue,
                title: $0.title,
                valueText: $0.valueText,
                detailText: $0.detailText,
                systemImage: $0.systemImage
            )
        }
    }

    private var manualMetricCards: [DashboardCardContent] {
        let nutritionCards = [
            DashboardCardContent(
                id: "manual-calories",
                title: "Calories",
                valueText: "\(nutritionViewModel.summary.totalCalories.formatted()) kcal",
                detailText: "Manual today",
                systemImage: "fork.knife"
            ),
            DashboardCardContent(
                id: "manual-protein",
                title: "Protein",
                valueText: "\(nutritionViewModel.summary.totalProteinGrams.formatted()) g",
                detailText: "Manual today",
                systemImage: "bolt.fill"
            ),
            DashboardCardContent(
                id: "manual-water",
                title: "Water",
                valueText: "\(nutritionViewModel.summary.totalWaterML.formatted()) mL",
                detailText: "Manual today",
                systemImage: "drop.fill"
            )
        ]

        let routineCards = routinesViewModel.statuses.map { status in
            DashboardCardContent(
                id: "routine-\(status.template.id)",
                title: status.template.title,
                valueText: status.isCompleted ? "Done" : "Open",
                detailText: routinesViewModel.streakText(for: status),
                systemImage: status.template.systemImage
            )
        }

        return nutritionCards + routineCards
    }

    private var loadingCard: some View {
        HStack(spacing: GlowSpacing.medium) {
            SwiftUI.ProgressView()
                .tint(GlowColors.accent)

            Text("Loading today's metrics...")
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

    private func sourceBadge(message: String) -> some View {
        Text(message)
            .font(GlowTypography.caption)
            .foregroundStyle(GlowColors.textPrimary)
            .padding(.horizontal, GlowSpacing.medium)
            .padding(.vertical, GlowSpacing.small)
            .background(GlowColors.accentMuted)
            .clipShape(Capsule())
    }

    private func noticeCard(message: String) -> some View {
        Text(message)
            .font(GlowTypography.caption)
            .foregroundStyle(GlowColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GlowSpacing.medium)
            .background(GlowColors.accentMuted)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GlowSpacing.cornerRadius,
                    style: .continuous
                )
            )
    }

    private func primaryStatusAction() {
        Task {
            switch dashboardViewModel.snapshot.connectionState {
            case .notConnected:
                await dashboardViewModel.connectAppleHealth()
            case .needsAttention:
                await dashboardViewModel.refresh()
            case .connected, .unavailable:
                break
            }
        }
    }
}

private struct DashboardCardContent: Identifiable {
    let id: String
    let title: String
    let valueText: String
    let detailText: String
    let systemImage: String
}

private struct SectionHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text(title)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(subtitle)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
        }
    }
}
