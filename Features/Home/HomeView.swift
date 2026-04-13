import Combine
import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var dashboardViewModel: HomeViewModel
    @StateObject private var nutritionViewModel: NutritionViewModel
    @StateObject private var routinesViewModel: RoutinesViewModel
    @StateObject private var glowScoreViewModel: GlowScoreViewModel
    @StateObject private var dailyPlanViewModel: DailyPlanViewModel
    @StateObject private var recapViewModel: RecapViewModel

    init(
        dashboardViewModel: HomeViewModel,
        nutritionViewModel: NutritionViewModel,
        routinesViewModel: RoutinesViewModel,
        glowScoreViewModel: GlowScoreViewModel,
        dailyPlanViewModel: DailyPlanViewModel,
        recapViewModel: RecapViewModel
    ) {
        _dashboardViewModel = StateObject(wrappedValue: dashboardViewModel)
        _nutritionViewModel = StateObject(wrappedValue: nutritionViewModel)
        _routinesViewModel = StateObject(wrappedValue: routinesViewModel)
        _glowScoreViewModel = StateObject(wrappedValue: glowScoreViewModel)
        _dailyPlanViewModel = StateObject(wrappedValue: dailyPlanViewModel)
        _recapViewModel = StateObject(wrappedValue: recapViewModel)
    }

    var body: some View {
        DashboardView(
            dashboardViewModel: dashboardViewModel,
            nutritionViewModel: nutritionViewModel,
            routinesViewModel: routinesViewModel,
            glowScoreViewModel: glowScoreViewModel,
            dailyPlanViewModel: dailyPlanViewModel,
            recapViewModel: recapViewModel,
            onRefresh: refreshAllContent,
            onOpenSettings: openSettings
        )
        .navigationTitle(dashboardViewModel.navigationTitle)
        .task {
            await glowScoreViewModel.loadStoredScore()
            await dailyPlanViewModel.loadStoredPlan()
            await loadInitialContent()
        }
        .onReceive(dashboardViewModel.$snapshot.dropFirst()) { _ in
            Task {
                await refreshDerivedContentIfReady()
            }
        }
        .onReceive(nutritionViewModel.$summary.dropFirst()) { _ in
            Task {
                await refreshDerivedContentIfReady()
            }
        }
        .onReceive(routinesViewModel.$summary.dropFirst()) { _ in
            Task {
                await refreshDerivedContentIfReady()
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
        await refreshDerivedContentIfReady()
    }

    private func refreshAllContent() async {
        await dashboardViewModel.refresh()
        await nutritionViewModel.refresh()
        await routinesViewModel.refresh()
        await refreshDerivedContentIfReady()
    }

    private func refreshDerivedContentIfReady() async {
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

        await recapViewModel.refresh(
            metricsSnapshot: dashboardViewModel.snapshot,
            nutritionSummary: nutritionViewModel.summary,
            routineSummary: routinesViewModel.summary,
            glowScore: glowScoreViewModel.score
        )

        guard let score = glowScoreViewModel.score else {
            return
        }

        await dailyPlanViewModel.refreshIfNeeded(
            metricsSnapshot: dashboardViewModel.snapshot,
            nutritionSummary: nutritionViewModel.summary,
            routineSummary: routinesViewModel.summary,
            glowScore: score
        )
    }
}
