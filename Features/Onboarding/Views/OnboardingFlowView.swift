import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var viewModel: OnboardingViewModel

    private let launchErrorMessage: String?
    private let onCompletion: () -> Void

    init(
        viewModel: OnboardingViewModel,
        launchErrorMessage: String?,
        onCompletion: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.launchErrorMessage = launchErrorMessage
        self.onCompletion = onCompletion
    }

    var body: some View {
        NavigationStack {
            currentStepView
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.step {
        case .welcome:
            WelcomeView(
                step: viewModel.step.index,
                totalSteps: viewModel.totalSteps,
                noticeMessage: launchErrorMessage,
                onContinue: viewModel.advance
            )
        case .valueProposition:
            ValuePropositionView(
                step: viewModel.step.index,
                totalSteps: viewModel.totalSteps,
                onBack: viewModel.goBack,
                onContinue: viewModel.advance
            )
        case .goalSelection:
            GoalSelectionView(
                step: viewModel.step.index,
                totalSteps: viewModel.totalSteps,
                selectedGoal: viewModel.primaryGoal,
                onSelectGoal: { viewModel.primaryGoal = $0 },
                onBack: viewModel.goBack,
                onContinue: viewModel.advance
            )
        case .targetSetup:
            TargetSetupView(
                step: viewModel.step.index,
                totalSteps: viewModel.totalSteps,
                viewModel: viewModel
            )
        case .completion:
            OnboardingCompletionView(
                step: viewModel.step.index,
                totalSteps: viewModel.totalSteps,
                viewModel: viewModel,
                onBack: viewModel.goBack,
                onComplete: {
                    Task {
                        let completed = await viewModel.completeOnboarding()

                        if completed {
                            onCompletion()
                        }
                    }
                }
            )
        }
    }
}
