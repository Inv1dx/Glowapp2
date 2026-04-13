import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onOpenSettings: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: GlowSpacing.medium),
        GridItem(.flexible(), spacing: GlowSpacing.medium)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlowSpacing.large) {
                header

                if !viewModel.hasLoadedOnce {
                    loadingCard
                } else {
                    if viewModel.showsStatusCard {
                        statusCard
                    }

                    if let sourceMessage = viewModel.sourceMessage {
                        sourceBadge(message: sourceMessage)
                    }

                    if let limitedAccessMessage = viewModel.limitedAccessMessage {
                        noticeCard(message: limitedAccessMessage)
                    }

                    if viewModel.showsMetrics {
                        metricsGrid
                    }
                }
            }
            .padding(GlowSpacing.screenPadding)
        }
        .background(GlowColors.background.ignoresSafeArea())
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text(AppConstants.Shell.appName)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)

            Text(viewModel.title)
                .font(GlowTypography.screenTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(viewModel.subtitle)
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusCard: some View {
        HealthConnectionCardView(
            title: viewModel.statusCardTitle,
            message: viewModel.statusCardMessage,
            systemImage: viewModel.statusCardSystemImage,
            primaryButtonTitle: viewModel.statusCardButtonTitle,
            isPrimaryLoading: viewModel.isRequestingAccess,
            secondaryButtonTitle: viewModel.showsSettingsAction ? "Open Settings" : nil,
            onPrimaryAction: primaryStatusAction,
            onSecondaryAction: viewModel.showsSettingsAction ? onOpenSettings : nil
        )
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: columns, spacing: GlowSpacing.medium) {
            ForEach(viewModel.metricCards) { card in
                DashboardMetricCardView(
                    title: card.title,
                    valueText: card.valueText,
                    detailText: card.detailText,
                    systemImage: card.systemImage
                )
            }
        }
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
            switch viewModel.snapshot.connectionState {
            case .notConnected:
                await viewModel.connectAppleHealth()
            case .needsAttention:
                await viewModel.refresh()
            case .connected, .unavailable:
                break
            }
        }
    }
}
