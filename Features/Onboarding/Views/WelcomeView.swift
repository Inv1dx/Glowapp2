import SwiftUI

struct WelcomeView: View {
    let step: Int
    let totalSteps: Int
    let noticeMessage: String?
    let onContinue: () -> Void

    var body: some View {
        OnboardingScaffoldView(
            step: step,
            totalSteps: totalSteps,
            title: "Build your next routine",
            message: "Pick a goal, set a few daily targets, and start from a clean home base.",
            primaryButtonTitle: "Continue",
            primaryAction: onContinue,
            noticeMessage: noticeMessage
        ) {
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            Text("What you'll lock in")
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            WelcomeRow(
                title: "One clear direction",
                detail: "Choose the result you're chasing first."
            )
            WelcomeRow(
                title: "Simple daily targets",
                detail: "Start with steps, sleep, protein, and water."
            )
            WelcomeRow(
                title: "Fast setup",
                detail: "This takes about a minute and stays local for now."
            )
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

private struct WelcomeRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text(title)
                .font(GlowTypography.body.weight(.semibold))
                .foregroundStyle(GlowColors.textPrimary)

            Text(detail)
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
