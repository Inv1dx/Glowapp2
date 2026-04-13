import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var dashboardViewModel: HomeViewModel
    @StateObject private var nutritionViewModel: NutritionViewModel
    @StateObject private var routinesViewModel: RoutinesViewModel

    init(
        dashboardViewModel: HomeViewModel,
        nutritionViewModel: NutritionViewModel,
        routinesViewModel: RoutinesViewModel
    ) {
        _dashboardViewModel = StateObject(wrappedValue: dashboardViewModel)
        _nutritionViewModel = StateObject(wrappedValue: nutritionViewModel)
        _routinesViewModel = StateObject(wrappedValue: routinesViewModel)
    }

    var body: some View {
        DashboardView(
            dashboardViewModel: dashboardViewModel,
            nutritionViewModel: nutritionViewModel,
            routinesViewModel: routinesViewModel,
            onOpenSettings: openSettings
        )
        .navigationTitle(dashboardViewModel.navigationTitle)
        .task {
            await dashboardViewModel.loadIfNeeded()
            await nutritionViewModel.loadIfNeeded()
            await routinesViewModel.loadIfNeeded()
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(url)
    }
}
