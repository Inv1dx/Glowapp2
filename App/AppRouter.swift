import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum RootDestination {
        case launching
        case onboarding
        case mainTabs
    }

    @Published private(set) var rootDestination: RootDestination
    @Published var selectedTab: AppTab
    @Published private(set) var launchErrorMessage: String?

    private let userRepository: any UserRepository
    private var hasResolvedInitialDestination = false

    init(
        userRepository: any UserRepository,
        rootDestination: RootDestination = .launching,
        selectedTab: AppTab = .home
    ) {
        self.userRepository = userRepository
        self.rootDestination = rootDestination
        self.selectedTab = selectedTab
    }

    func loadInitialDestinationIfNeeded() async {
        guard !hasResolvedInitialDestination else {
            return
        }

        hasResolvedInitialDestination = true

        do {
            let userProfile = try await userRepository.loadUserProfile()
            launchErrorMessage = nil
            rootDestination = userProfile?.onboardingCompleted == true ? .mainTabs : .onboarding
        } catch {
            launchErrorMessage = "We couldn't load your saved setup. You can finish it again."
            rootDestination = .onboarding
        }
    }

    func showOnboarding() {
        rootDestination = .onboarding
    }

    func showMainTabs(selecting tab: AppTab = .home) {
        rootDestination = .mainTabs
        selectedTab = tab
    }
}
