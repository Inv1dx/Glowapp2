import SwiftUI

struct NutritionQuickLogCardView: View {
    @ObservedObject var viewModel: NutritionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            header
            totalsRow
            nutritionActions
            waterActions
            logList
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
        .sheet(item: $viewModel.editorContext) { context in
            NutritionLogEditorView(context: context) { calories, proteinGrams in
                await viewModel.saveEntry(
                    context: context,
                    calories: calories,
                    proteinGrams: proteinGrams
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text(viewModel.sectionTitle)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(viewModel.sectionSubtitle)
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(GlowTypography.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var totalsRow: some View {
        HStack(spacing: GlowSpacing.small) {
            NutritionTotalBadge(
                title: "Calories",
                value: "\(viewModel.summary.totalCalories.formatted()) kcal"
            )
            NutritionTotalBadge(
                title: "Protein",
                value: "\(viewModel.summary.totalProteinGrams.formatted()) g"
            )
            NutritionTotalBadge(
                title: "Water",
                value: "\(viewModel.summary.totalWaterML.formatted()) mL"
            )
        }
    }

    private var nutritionActions: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text("Quick add")
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.textSecondary)

            HStack(spacing: GlowSpacing.small) {
                QuickActionButton(
                    title: "Calories",
                    systemImage: "fork.knife",
                    action: viewModel.presentQuickCaloriesEditor
                )
                QuickActionButton(
                    title: "Protein",
                    systemImage: "bolt.fill",
                    action: viewModel.presentQuickProteinEditor
                )
                QuickActionButton(
                    title: "Entry",
                    systemImage: "plus.circle.fill",
                    action: viewModel.presentNutritionEditor
                )
            }
        }
    }

    private var waterActions: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text("Water increments")
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.textSecondary)

            HStack(spacing: GlowSpacing.small) {
                WaterIncrementButton(amountML: 250) {
                    viewModel.addWater(amountML: 250)
                }
                WaterIncrementButton(amountML: 500) {
                    viewModel.addWater(amountML: 500)
                }
                WaterIncrementButton(amountML: 750) {
                    viewModel.addWater(amountML: 750)
                }
            }
        }
    }

    private var logList: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text("Today's entries")
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.textSecondary)

            if viewModel.entries.isEmpty {
                Text(viewModel.emptyStateMessage)
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)
                    .padding(.vertical, GlowSpacing.small)
            } else {
                ForEach(viewModel.entries) { log in
                    NutritionLogRowView(
                        title: viewModel.title(for: log),
                        detail: viewModel.detail(for: log),
                        isEditable: log.hasNutritionContent,
                        onSelect: {
                            viewModel.presentEditor(for: log)
                        },
                        onDelete: {
                            viewModel.delete(log)
                        }
                    )
                }
            }
        }
    }
}

private struct NutritionTotalBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)

            Text(value)
                .font(GlowTypography.body.weight(.semibold))
                .foregroundStyle(GlowColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowSpacing.small)
        .background(GlowColors.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: GlowSpacing.medium,
                style: .continuous
            )
        )
    }
}

private struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GlowSpacing.small)
                .padding(.horizontal, GlowSpacing.small)
                .background(GlowColors.accentMuted)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: GlowSpacing.medium,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct WaterIncrementButton: View {
    let amountML: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+\(amountML.formatted()) mL")
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GlowSpacing.small)
                .padding(.horizontal, GlowSpacing.small)
                .background(GlowColors.background)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: GlowSpacing.medium,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct NutritionLogRowView: View {
    let title: String
    let detail: String
    let isEditable: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: GlowSpacing.small) {
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(GlowTypography.body.weight(.semibold))
                        .foregroundStyle(GlowColors.textPrimary)

                    Text(detail)
                        .font(GlowTypography.caption)
                        .foregroundStyle(GlowColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isEditable)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(GlowSpacing.small)
                    .background(GlowColors.background)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, GlowSpacing.xSmall)
    }
}
