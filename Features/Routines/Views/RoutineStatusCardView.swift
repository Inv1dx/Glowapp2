import SwiftUI

struct RoutineStatusCardView: View {
    let status: RoutineDaySummary.Status
    let detailText: String
    let streakText: String
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            HStack(alignment: .top, spacing: GlowSpacing.medium) {
                VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
                    Label(status.template.title, systemImage: status.template.systemImage)
                        .font(GlowTypography.sectionTitle)
                        .foregroundStyle(GlowColors.textPrimary)

                    Text(status.template.detail)
                        .font(GlowTypography.body)
                        .foregroundStyle(GlowColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                completionBadge
            }

            HStack(spacing: GlowSpacing.small) {
                Text(detailText)
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textPrimary)
                    .padding(.horizontal, GlowSpacing.medium)
                    .padding(.vertical, GlowSpacing.xSmall)
                    .background(status.isCompleted ? GlowColors.accentMuted : GlowColors.background)
                    .clipShape(Capsule())

                Text(streakText)
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)

                Spacer()
            }

            PrimaryButton(
                title: status.isCompleted ? "Mark incomplete" : "Mark complete",
                systemImage: status.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle.fill",
                action: onToggle
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

    private var completionBadge: some View {
        Text(status.isCompleted ? "Done" : "Open")
            .font(GlowTypography.caption.weight(.semibold))
            .foregroundStyle(status.isCompleted ? GlowColors.accent : GlowColors.textSecondary)
            .padding(.horizontal, GlowSpacing.medium)
            .padding(.vertical, GlowSpacing.xSmall)
            .background(status.isCompleted ? GlowColors.accentMuted : GlowColors.background)
            .clipShape(Capsule())
    }
}
