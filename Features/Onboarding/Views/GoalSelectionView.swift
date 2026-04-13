import SwiftUI

struct GoalSelectionView: View {
    let step: Int
    let totalSteps: Int
    let selectedGoal: UserProfile.PrimaryGoal
    let onSelectGoal: (UserProfile.PrimaryGoal) -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingScaffoldView(
            step: step,
            totalSteps: totalSteps,
            title: "Choose your main goal",
            message: "Pick one for now. You can change direction later without resetting the app.",
            primaryButtonTitle: "Set targets",
            primaryAction: onContinue,
            backAction: onBack
        ) {
            VStack(spacing: GlowSpacing.medium) {
                ForEach(UserProfile.PrimaryGoal.allCases) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: goal == selectedGoal,
                        onTap: { onSelectGoal(goal) }
                    )
                }
            }
        }
    }
}

private struct GoalCard: View {
    let goal: UserProfile.PrimaryGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: GlowSpacing.medium) {
                VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
                    Text(goal.title)
                        .font(GlowTypography.sectionTitle)
                        .foregroundStyle(GlowColors.textPrimary)

                    Text(goal.detail)
                        .font(GlowTypography.body)
                        .foregroundStyle(GlowColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? GlowColors.accent : GlowColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GlowSpacing.cardPadding)
            .background(isSelected ? GlowColors.accentMuted : GlowColors.surface)
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
                .stroke(isSelected ? GlowColors.accent : GlowColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
