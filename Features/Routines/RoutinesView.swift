import SwiftUI

struct RoutinesView: View {
    @StateObject private var viewModel: RoutinesViewModel

    init(viewModel: RoutinesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlowSpacing.large) {
                header

                ForEach(viewModel.statuses) { status in
                    RoutineStatusCardView(
                        status: status,
                        detailText: viewModel.detailText(for: status),
                        streakText: viewModel.streakText(for: status),
                        onToggle: {
                            viewModel.toggleCompletion(for: status.template)
                        }
                    )
                }
            }
            .padding(GlowSpacing.screenPadding)
        }
        .background(GlowColors.background.ignoresSafeArea())
        .navigationTitle(viewModel.navigationTitle)
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text(viewModel.title)
                .font(GlowTypography.screenTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(viewModel.subtitle)
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
