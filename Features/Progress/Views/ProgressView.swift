import SwiftUI

struct ProgressView: View {
    @StateObject private var viewModel: ProgressViewModel

    private let summaryColumns = [
        GridItem(.flexible(), spacing: GlowSpacing.medium),
        GridItem(.flexible(), spacing: GlowSpacing.medium)
    ]

    init(viewModel: ProgressViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlowSpacing.large) {
                header

                PrimaryButton(
                    title: viewModel.addButtonTitle,
                    systemImage: "plus"
                ) {
                    viewModel.presentAddEntry()
                }

                if !viewModel.hasLoadedOnce {
                    loadingCard
                } else if viewModel.entries.isEmpty {
                    emptyStateCard
                } else {
                    summarySection
                    trendSection
                    historySection
                }
            }
            .padding(GlowSpacing.screenPadding)
        }
        .background(GlowColors.background.ignoresSafeArea())
        .navigationTitle(viewModel.navigationTitle)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(item: $viewModel.editorContext) { context in
            ProgressEntryEditorView(
                viewModel: viewModel.makeEditorViewModel(for: context)
            )
        }
        .alert(
            "Delete this check-in?",
            isPresented: deleteAlertBinding
        ) {
            Button("Delete", role: .destructive) {
                viewModel.confirmDeletion()
            }

            Button("Cancel", role: .cancel) {
                viewModel.deleteRequest = nil
            }
        } message: {
            Text("This removes the saved entry and any local progress photos attached to it.")
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

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            ProgressSectionHeaderView(
                title: "Snapshot",
                subtitle: "Small summaries to show whether the weekly check-ins are stacking up."
            )

            LazyVGrid(columns: summaryColumns, spacing: GlowSpacing.medium) {
                ForEach(viewModel.insights.summaryMetrics) { metric in
                    ProgressSummaryMetricCardView(metric: metric)
                }
            }
        }
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            ProgressSectionHeaderView(
                title: "Trends",
                subtitle: "Simple movement over time for weight, waist, and Glow Score."
            )

            ProgressTrendCardView(
                title: "Weight",
                subtitle: "Saved check-ins only",
                points: viewModel.insights.weightSeries,
                accentColor: GlowColors.accent,
                emptyMessage: "Add at least one weight entry to start the trend.",
                valueFormatter: { value in
                    "\(value.formatted(.number.precision(.fractionLength(0...1)))) kg"
                }
            )

            ProgressTrendCardView(
                title: "Waist",
                subtitle: "Saved check-ins only",
                points: viewModel.insights.waistSeries,
                accentColor: .orange,
                emptyMessage: "Add a waist entry to start the trend.",
                valueFormatter: { value in
                    "\(value.formatted(.number.precision(.fractionLength(0...1)))) cm"
                }
            )

            ProgressTrendCardView(
                title: "Glow Score",
                subtitle: "Reusing saved daily score history",
                points: viewModel.insights.glowScoreSeries,
                accentColor: .blue,
                emptyMessage: "Glow Score history will appear when saved daily scores are available.",
                valueFormatter: { value in
                    Int(value.rounded()).formatted()
                }
            )
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            ProgressSectionHeaderView(
                title: "History",
                subtitle: "Newest first so past check-ins stay easy to scan."
            )

            ForEach(viewModel.entries) { entry in
                ProgressEntryCardView(
                    entry: entry,
                    photoStorageService: viewModel.photoStorage,
                    onEdit: {
                        viewModel.presentEditEntry(entry)
                    },
                    onDelete: {
                        viewModel.requestDelete(entry)
                    }
                )
            }
        }
    }

    private var emptyStateCard: some View {
        ProgressCardContainer {
            VStack(alignment: .leading, spacing: GlowSpacing.medium) {
                Image(systemName: "camera.metering.center.weighted")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(GlowColors.accent)

                Text("No progress check-ins yet")
                    .font(GlowTypography.sectionTitle)
                    .foregroundStyle(GlowColors.textPrimary)

                Text("Start with weight, waist, a front photo, or any mix that makes weekly progress feel tangible.")
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var loadingCard: some View {
        ProgressCardContainer {
            HStack(spacing: GlowSpacing.medium) {
                SwiftUI.ProgressView()
                    .tint(GlowColors.accent)

                Text("Loading progress history...")
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textSecondary)
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.deleteRequest != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.deleteRequest = nil
                }
            }
        )
    }
}
