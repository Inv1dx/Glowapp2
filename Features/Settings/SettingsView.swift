import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: SettingsViewModel())
    }

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlowSpacing.large) {
                header

                VStack(spacing: GlowSpacing.medium) {
                    SettingsStatusRow(
                        title: viewModel.accountTitle,
                        detail: viewModel.accountDetail,
                        systemImage: viewModel.accountSystemImage
                    )

                    SettingsStatusRow(
                        title: viewModel.syncTitle,
                        detail: viewModel.syncDetail,
                        systemImage: viewModel.syncSystemImage
                    )
                }
            }
            .padding(GlowSpacing.screenPadding)
        }
        .background(GlowColors.background.ignoresSafeArea())
        .navigationTitle(viewModel.navigationTitle)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text("Account")
                .font(GlowTypography.screenTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text("Backend status and the current MVP account identifier.")
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SettingsStatusRow: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: GlowSpacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(GlowColors.accent)
                .frame(width: 44, height: 44)
                .background(GlowColors.accentMuted)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
                Text(title)
                    .font(GlowTypography.sectionTitle)
                    .foregroundStyle(GlowColors.textPrimary)

                Text(detail)
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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
