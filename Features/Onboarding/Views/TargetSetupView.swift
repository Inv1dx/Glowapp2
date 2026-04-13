import SwiftUI

struct TargetSetupView: View {
    let step: Int
    let totalSteps: Int

    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingScaffoldView(
            step: step,
            totalSteps: totalSteps,
            title: "Set your starter targets",
            message: "Keep them realistic. The goal is a clean baseline you can stick to.",
            primaryButtonTitle: "Review setup",
            primaryAction: viewModel.continueFromTargets,
            backAction: viewModel.goBack
        ) {
            VStack(spacing: GlowSpacing.medium) {
                nameCard
                stepsCard
                sleepCard
                proteinCard
                waterCard
            }
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text("Display name")
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            TextField("Enter a name or nickname", text: $viewModel.displayName)
                .font(GlowTypography.body)
                .disableAutocorrection(true)
                .padding(GlowSpacing.medium)
                .background(GlowColors.background)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: GlowSpacing.cornerRadius,
                        style: .continuous
                    )
                )

            Text(viewModel.validationMessage(for: .displayName) ?? "This stays local on your device for now.")
                .font(GlowTypography.caption)
                .foregroundStyle(
                    viewModel.validationMessage(for: .displayName) == nil ? GlowColors.textSecondary : .red
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

    private var stepsCard: some View {
        TargetCard(
            title: "Daily steps",
            value: "\(viewModel.targetDailySteps.formatted())",
            helperText: viewModel.validationMessage(for: .dailySteps) ?? "Starter range: 3,000 to 30,000."
        ) {
            Stepper(value: $viewModel.targetDailySteps, in: UserProfile.dailyStepsRange, step: 500) {
                Text("Move this with your day, not your fantasy.")
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)
            }
        }
    }

    private var sleepCard: some View {
        TargetCard(
            title: "Sleep hours",
            value: viewModel.targetSleepHours.formatted(),
            helperText: viewModel.validationMessage(for: .sleepHours) ?? "Starter range: 5 to 10 hours."
        ) {
            Stepper(
                value: $viewModel.targetSleepHours,
                in: UserProfile.sleepHoursRange,
                step: 0.5
            ) {
                Text("Use half-hour steps to keep it simple.")
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)
            }
        }
    }

    private var proteinCard: some View {
        TargetCard(
            title: "Protein grams",
            value: "\(viewModel.targetProteinGrams.formatted()) g",
            helperText: viewModel.validationMessage(for: .proteinGrams) ?? "Starter range: 40 to 250 grams."
        ) {
            Stepper(
                value: $viewModel.targetProteinGrams,
                in: UserProfile.proteinRange,
                step: 5
            ) {
                Text("Enough to support your goal without overthinking it.")
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)
            }
        }
    }

    private var waterCard: some View {
        TargetCard(
            title: "Water ml",
            value: "\(viewModel.targetWaterML.formatted()) ml",
            helperText: viewModel.validationMessage(for: .waterML) ?? "Starter range: 500 to 5,000 ml."
        ) {
            Stepper(value: $viewModel.targetWaterML, in: UserProfile.waterRange, step: 250) {
                Text("A straightforward hydration target for the day.")
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)
            }
        }
    }
}

private struct TargetCard<Control: View>: View {
    let title: String
    let value: String
    let helperText: String
    let control: Control

    init(
        title: String,
        value: String,
        helperText: String,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.value = value
        self.helperText = helperText
        self.control = control()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            HStack {
                Text(title)
                    .font(GlowTypography.sectionTitle)
                    .foregroundStyle(GlowColors.textPrimary)

                Spacer()

                Text(value)
                    .font(GlowTypography.body.weight(.semibold))
                    .foregroundStyle(GlowColors.accent)
            }

            control

            Text(helperText)
                .font(GlowTypography.caption)
                .foregroundStyle(helperText.contains("Starter range") ? GlowColors.textSecondary : .red)
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
