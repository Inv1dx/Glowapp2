import XCTest
@testable import GlowApp

@MainActor
final class DailyPlanViewModelTests: XCTestCase {
    func testRefreshLoadsStoredSameDayPlanWithoutRegenerating() async {
        let userDefaults = makeUserDefaults()
        let repository = LocalGlowPlanRepository(
            userDefaults: userDefaults,
            calendar: calendar
        )
        let storedPlan = makePlan(date: makeDate(year: 2026, month: 4, day: 13, hour: 10))
        await repository.savePlan(storedPlan)

        let engine = SpyGlowPlanEngine(plan: makePlan(date: storedPlan.date))
        let viewModel = DailyPlanViewModel(
            userRepository: MockUserRepository(),
            planRepository: repository,
            engine: engine,
            calendar: calendar
        )

        await viewModel.refreshIfNeeded(
            metricsSnapshot: makeSnapshot(date: storedPlan.date),
            nutritionSummary: NutritionDaySummary(
                date: storedPlan.date,
                totalCalories: 0,
                totalProteinGrams: 0,
                totalWaterML: 0
            ),
            routineSummary: RoutineDaySummary.empty(for: storedPlan.date),
            glowScore: makeScore(date: storedPlan.date),
            evaluatedAt: storedPlan.date
        )

        XCTAssertEqual(engine.generateCallCount, 0)
        XCTAssertEqual(viewModel.plan?.actions, storedPlan.actions)
        XCTAssertEqual(viewModel.plan?.date, calendar.startOfDay(for: storedPlan.date))
    }

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "GlowApp.daily-plan-view-model-tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makePlan(date: Date) -> GlowPlan {
        GlowPlan(
            date: date,
            generatedAt: date,
            mode: .focused,
            actions: [
                GlowPlanAction(
                    kind: .hydrationGoal,
                    title: "Drink 500 mL more water today",
                    detail: nil,
                    priority: 1,
                    isCompleted: false
                ),
                GlowPlanAction(
                    kind: .proteinGoal,
                    title: "Get 20 g more protein today",
                    detail: nil,
                    priority: 2,
                    isCompleted: false
                ),
                GlowPlanAction(
                    kind: .sleepWindDown,
                    title: "Start winding down for 8.0 hr tonight",
                    detail: nil,
                    priority: 3,
                    isCompleted: false
                )
            ]
        )
    }

    private func makeSnapshot(date: Date) -> MetricsRepositorySnapshot {
        MetricsRepositorySnapshot(
            metrics: DailyMetrics(
                date: date,
                steps: 0,
                activeCalories: 0,
                workoutsCount: 0,
                sleepDurationHours: nil,
                weightKg: nil
            ),
            connectionState: .connected,
            source: .live,
            limitedFields: [],
            unsupportedFields: [],
            lastUpdatedAt: date
        )
    }

    private func makeScore(date: Date) -> GlowScore {
        GlowScore(
            date: calendar.startOfDay(for: date),
            overallScore: 60,
            availableWeight: 100,
            totalWeight: 100,
            breakdowns: [
                GlowScoreCategoryBreakdown(
                    category: .hydration,
                    score: 30,
                    weight: 10,
                    status: .available,
                    dataState: .available,
                    summaryText: "0 / 2500 mL",
                    explanation: "Hydration is behind."
                )
            ],
            explanations: ["Hydration is behind."],
            configVersion: GlowScoreConfig.stage5.version,
            computedAt: date
        )
    }

    private final class SpyGlowPlanEngine: GlowPlanGenerating {
        private(set) var generateCallCount = 0
        let plan: GlowPlan

        init(plan: GlowPlan) {
            self.plan = plan
        }

        func generatePlan(from input: GlowPlanInput) -> GlowPlan {
            generateCallCount += 1
            return plan
        }
    }

    private final class MockUserRepository: UserRepository {
        func loadUserProfile() async throws -> UserProfile? {
            nil
        }

        func saveUserProfile(_ profile: UserProfile) async throws {}

        func clearUserProfile() async throws {}
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        )

        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
