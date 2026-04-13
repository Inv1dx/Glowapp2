import SwiftUI

struct AppRootView: View {
    @ObservedObject var router: AppRouter
    @Environment(\.appEnvironment) private var environment

    var body: some View {
        Group {
            switch router.rootDestination {
            case .launching:
                launchView
            case .onboarding:
                OnboardingFlowView(
                    viewModel: environment.makeOnboardingViewModel(),
                    launchErrorMessage: router.launchErrorMessage,
                    onCompletion: {
                        router.showMainTabs()
                    }
                )
            case .mainTabs:
                AppShellView(router: router)
            }
        }
        .task {
            await router.loadInitialDestinationIfNeeded()
        }
    }

    private var launchView: some View {
        VStack(spacing: GlowSpacing.medium) {
            Text(AppConstants.Shell.appName)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            SwiftUI.ProgressView()
                .tint(GlowColors.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GlowColors.background.ignoresSafeArea())
    }
}
