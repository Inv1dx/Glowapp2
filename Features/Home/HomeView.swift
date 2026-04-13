import Combine
import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var dashboardViewModel: HomeViewModel
    @StateObject private var nutritionViewModel: NutritionViewModel
    @StateObject private var routinesViewModel: RoutinesViewModel
    @StateObject private var glowScoreViewModel: GlowScoreViewModel

    init(
        dashboardViewModel: HomeViewModel,
        nutritionViewModel: NutritionViewModel,
        routinesViewModel: RoutinesViewModel,
        glowScoreViewModel: GlowScoreViewModel
    ) {
        _dashboardViewModel = StateObject(wrappedValue: dashboardViewModel)
        _nutritionViewModel = StateObject(wrappedValue: nutritionViewModel)
        _routinesViewModel = StateObject(wrappedValue: routinesViewModel)
        _glowScoreViewModel = StateObject(wrappedValue: glowScoreViewModel)
    }

    var body: some View {
        DashboardView(
            dashboardViewModel: dashboardViewModel,
            nutritionViewModel: nutritionViewModel,
            routinesViewModel: routinesViewModel,
            glowScoreViewModel: glowScoreViewModel,
            onRefresh: refreshAllContent,
            onOpenSettings: openSettings
        )
        .navigationTitle(dashboardViewModel.navigationTitle)
        .task {
            await glowScoreViewModel.loadStoredScore()
            await loadInitialContent()
        }
        .onReceive(dashboardViewModel.$snapshot.dropFirst()) { _ in
            Task {
                await refreshGlowScoreIfReady()
            }
        }
        .onReceive(nutritionViewModel.$summary.dropFirst()) { _ in
            Task {
                await refreshGlowScoreIfReady()
            }
        }
        .onReceive(routinesViewModel.$summary.dropFirst()) { _ in
            Task {
                await refreshGlowScoreIfReady()
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(url)
    }

    private func loadInitialContent() async {
        await dashboardViewModel.loadIfNeeded()
        await nutritionViewModel.loadIfNeeded()
        await routinesViewModel.loadIfNeeded()
        await refreshGlowScoreIfReady()
    }

    private func refreshAllContent() async {
        await dashboardViewModel.refresh()
        await nutritionViewModel.refresh()
        await routinesViewModel.refresh()
        await refreshGlowScoreIfReady()
    }

    private func refreshGlowScoreIfReady() async {
        guard
            dashboardViewModel.hasLoadedOnce,
            nutritionViewModel.hasLoadedOnce,
            routinesViewModel.hasLoadedOnce
        else {
            return
        }

        await glowScoreViewModel.refresh(
            metricsSnapshot: dashboardViewModel.snapshot,
            nutritionSummary: nutritionViewModel.summary,
            routineSummary: routinesViewModel.summary
        )
    }
}
