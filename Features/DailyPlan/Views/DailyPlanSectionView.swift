import SwiftUI

struct DailyPlanSectionView: View {
    @ObservedObject var viewModel: DailyPlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            header

            if viewModel.isLoading && viewModel.plan == nil {
                loadingCard
            } else if let plan = viewModel.plan {
                planCard(plan)
            } else {
                emptyStateCard
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text(viewModel.title)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(viewModel.subtitle)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)

            if let completionText = viewModel.completionText {
                Text(completionText)
                    .font(GlowTypography.caption.weight(.semibold))
                    .foregroundStyle(GlowColors.textSecondary)
            }
        }
    }

    private func planCard(_ plan: GlowPlan) -> some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            ForEach(plan.actions) { action in
                DailyPlanActionRow(
                    action: action,
                    onToggle: {
                        viewModel.toggleCompletion(for: action)
                    }
                )
            }
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

    private var loadingCard: some View {
        HStack(spacing: GlowSpacing.medium) {
            SwiftUI.ProgressView()
                .tint(GlowColors.accent)

            Text("Building today's plan...")
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
        Text("Your plan will show up once today's score and manual totals are ready.")
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
}

private struct DailyPlanActionRow: View {
    let action: GlowPlanAction
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: GlowSpacing.small) {
                Image(systemName: action.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(action.isCompleted ? GlowColors.accent : GlowColors.textSecondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(GlowTypography.body.weight(.semibold))
                        .foregroundStyle(GlowColors.textPrimary)
                        .strikethrough(action.isCompleted, color: GlowColors.textSecondary)
                        .multilineTextAlignment(.leading)

                    if let detail = action.detail {
                        Text(detail)
                            .font(GlowTypography.caption)
                            .foregroundStyle(GlowColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: GlowSpacing.small)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, GlowSpacing.small)
            .padding(.horizontal, GlowSpacing.medium)
            .background(action.isCompleted ? GlowColors.accentMuted : GlowColors.background)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GlowSpacing.medium,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
        .accessibilityValue(action.isCompleted ? "Completed" : "Not completed")
    }
}
