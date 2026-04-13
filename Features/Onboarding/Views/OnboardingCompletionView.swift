import SwiftUI

struct OnboardingCompletionView: View {
    let step: Int
    let totalSteps: Int

    @ObservedObject var viewModel: OnboardingViewModel

    let onBack: () -> Void
    let onComplete: () -> Void

    var body: some View {
        OnboardingScaffoldView(
            step: step,
            totalSteps: totalSteps,
            title: viewModel.completionTitle,
            message: "Your starter setup is ready. You can change any of this later once you're inside the app.",
            primaryButtonTitle: "Enter Glow App",
            primaryAction: onComplete,
            primaryButtonSystemImage: "sparkles",
            isPrimaryLoading: viewModel.isSaving,
            backAction: onBack
        ) {
            VStack(spacing: GlowSpacing.medium) {
                summaryCard

                if let saveErrorMessage = viewModel.saveErrorMessage {
                    errorCard(message: saveErrorMessage)
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.medium) {
            Text("Your setup")
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            ForEach(viewModel.summaryItems, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle.fill")
                    .font(GlowTypography.body)
                    .foregroundStyle(GlowColors.textPrimary)
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

    private func errorCard(message: String) -> some View {
        Text(message)
            .font(GlowTypography.caption)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GlowSpacing.medium)
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
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
    }
}
