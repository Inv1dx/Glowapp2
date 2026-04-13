import SwiftUI

struct AppShellView: View {
    @ObservedObject var router: AppRouter
    @Environment(\.appEnvironment) private var environment

    var body: some View {
        TabView(selection: selectedTabBinding) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    contentView(for: tab)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
        .tint(GlowColors.accent)
    }

    private var selectedTabBinding: Binding<AppTab> {
        Binding(
            get: { router.selectedTab },
            set: { router.selectedTab = $0 }
        )
    }

    @ViewBuilder
    private func contentView(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView(
                dashboardViewModel: environment.makeHomeViewModel(),
                nutritionViewModel: environment.makeNutritionViewModel(),
                routinesViewModel: environment.makeRoutinesViewModel()
            )
        case .routines:
            RoutinesView(viewModel: environment.makeRoutinesViewModel())
        case .progress:
            ProgressView(viewModel: environment.makeProgressViewModel())
        case .settings:
            SettingsView(viewModel: environment.makeSettingsViewModel())
        }
    }
}
