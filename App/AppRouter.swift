import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum RootDestination {
        case mainTabs
    }

    @Published var rootDestination: RootDestination
    @Published var selectedTab: AppTab

    init(
        rootDestination: RootDestination = .mainTabs,
        selectedTab: AppTab = .home
    ) {
        self.rootDestination = rootDestination
        self.selectedTab = selectedTab
    }

    func showMainTabs(selecting tab: AppTab = .home) {
        rootDestination = .mainTabs
        selectedTab = tab
    }
}
