import SwiftUI

struct ValuePropositionView: View {
    let step: Int
    let totalSteps: Int
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingScaffoldView(
            step: step,
            totalSteps: totalSteps,
            title: "Glow App keeps your basics in one place",
            message: "No calorie maze. No medical dashboards. Just a lightweight system you can actually follow.",
            primaryButtonTitle: "Keep going",
            primaryAction: onContinue,
            backAction: onBack
        ) {
            VStack(spacing: GlowSpacing.medium) {
                ValueCard(
                    title: "Stay outcome-focused",
                    detail: "Choose the goal that matters most right now."
                )
                ValueCard(
                    title: "Make the day obvious",
                    detail: "Set a few targets you can return to without thinking."
                )
                ValueCard(
                    title: "Start simple",
                    detail: "You can add more depth later without rebuilding the app."
                )
            }
        }
    }
}

private struct ValueCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text(title)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(detail)
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
