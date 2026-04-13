import XCTest
@testable import GlowApp

final class RecapEngineTests: XCTestCase {
    private lazy var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private lazy var engine = RecapEngine(
        config: .stage7,
        calendar: calendar
    )

    func testDeficitCaseWithEnoughData() {
        let recap = engine.generateRecap(
            from: makeInput(
                metrics: DailyMetrics(
                    date: makeDate(hour: 21),
                    steps: 8_100,
                    activeCalories: 300,
                    workoutsCount: 1,
                    sleepDurationHours: 7.9,
                    weightKg: 70
                ),
                nutritionSummary: NutritionDaySummary(
                    date: makeDate(hour: 21),
                    totalCalories: 1_500,
                    totalProteinGrams: 110,
                    totalWaterML: 2_200
                )
            )
        )

        XCTAssertEqual(recap.energyBalance.estimatedCaloriesOut, 1_840)
        XCTAssertEqual(recap.energyBalance.outputState, .estimated)
        XCTAssertEqual(recap.energyBalance.balanceState, .deficit)
        XCTAssertEqual(recap.energyBalance.balanceAmount, 340)
    }

    func testSurplusCaseWithEnoughData() {
        let recap = engine.generateRecap(
            from: makeInput(
                metrics: DailyMetrics(
                    date: makeDate(hour: 21),
                    steps: 7_400,
                    activeCalories: 280,
                    workoutsCount: 1,
                    sleepDurationHours: 8.0,
                    weightKg: 72
                ),
                nutritionSummary: NutritionDaySummary(
                    date: makeDate(hour: 21),
                    totalCalories: 2_300,
                    totalProteinGrams: 120,
                    totalWaterML: 2_400
                )
            )
        )

        XCTAssertEqual(recap.energyBalance.estimatedCaloriesOut, 1_864)
        XCTAssertEqual(recap.energyBalance.balanceState, .surplus)
        XCTAssertEqual(recap.energyBalance.balanceAmount, 436)
    }

    func testNoFoodLoggedKeepsRecapStable() {
        let recap = engine.generateRecap(
            from: makeInput(
                metrics: DailyMetrics(
                    date: makeDate(hour: 20),
                    steps: 6_100,
                    activeCalories: 240,
                    workoutsCount: 0,
                    sleepDurationHours: 7.4,
                    weightKg: 69
                ),
                nutritionSummary: NutritionDaySummary(
                    date: makeDate(hour: 20),
                    totalCalories: 0,
                    totalProteinGrams: 0,
                    totalWaterML: 1_200
                )
            )
        )

        XCTAssertNil(recap.energyBalance.caloriesIn)
        XCTAssertEqual(recap.energyBalance.balanceState, .unavailable)
        XCTAssertEqual(
            recap.energyBalance.balanceExplanation,
            "Add calorie intake logs to see an estimated balance."
        )
    }

    func testMissingActiveCaloriesFallsBackToPartialCaloriesOutEstimate() {
        let recap = engine.generateRecap(
            from: makeInput(
                metrics: nil,
                connectionState: .notConnected,
                nutritionSummary: NutritionDaySummary(
                    date: makeDate(hour: 20),
                    totalCalories: 1_600,
                    totalProteinGrams: 105,
                    totalWaterML: 2_100
                )
            )
        )

        XCTAssertEqual(recap.energyBalance.outputState, .partial)
        XCTAssertEqual(recap.energyBalance.estimatedCaloriesOut, 1_900)
        XCTAssertEqual(
            recap.energyBalance.caloriesOutExplanation,
            "Partial estimate. Active calories are unavailable today."
        )
    }

    func testRecommendationUsesWeakestGlowScoreAreaWhenAvailable() {
        let recap = engine.generateRecap(
            from: makeInput(
                glowScore: makeGlowScore(
                    overallScore: 68,
                    scores: [
                        .sleep: 88,
                        .activity: 41,
                        .nutrition: 74,
                        .hydration: 79,
                        .routineConsistency: 82
                    ]
                )
            )
        )

        XCTAssertEqual(recap.weakestArea, .activity)
        XCTAssertEqual(
            recap.recommendationText,
            "Tomorrow, push activity earlier so the day does not stall."
        )
    }

    func testStrongDayReturnsMaintenanceRecommendation() {
        let recap = engine.generateRecap(
            from: makeInput(
                glowScore: makeGlowScore(
                    overallScore: 92,
                    scores: [
                        .sleep: 95,
                        .activity: 94,
                        .nutrition: 93,
                        .hydration: 88,
                        .routineConsistency: 96
                    ]
                )
            )
        )

        XCTAssertEqual(recap.weakestArea, .hydration)
        XCTAssertEqual(recap.summaryMessage, "Solid day overall.")
        XCTAssertEqual(recap.recommendationText, "Tomorrow, keep water in reach early.")
    }

    func testMissingGlowScoreFallsBackToRawSignals() {
        let recap = engine.generateRecap(
            from: makeInput(
                nutritionSummary: NutritionDaySummary(
                    date: makeDate(hour: 20),
                    totalCalories: 1_700,
                    totalProteinGrams: 120,
                    totalWaterML: 0
                ),
                routineSummary: RoutineDaySummary(
                    date: makeDate(hour: 20),
                    statuses: [
                        .init(template: .am, isCompleted: true, streakCount: 2),
                        .init(template: .pm, isCompleted: true, streakCount: 2),
                        .init(template: .grooming, isCompleted: true, streakCount: 2)
                    ]
                ),
                glowScore: nil
            )
        )

        XCTAssertNil(recap.glowScore)
        XCTAssertEqual(recap.weakestArea, .hydration)
        XCTAssertEqual(
            recap.recommendationText,
            "Tomorrow, focus on hydration earlier in the day."
        )
    }

    private func makeInput(
        metrics: DailyMetrics? = DailyMetrics(
            date: Date(),
            steps: 8_000,
            activeCalories: 300,
            workoutsCount: 1,
            sleepDurationHours: 8.0,
            weightKg: 70
        ),
        connectionState: MetricsConnectionState = .connected,
        nutritionSummary: NutritionDaySummary = NutritionDaySummary(
            date: Date(),
            totalCalories: 1_700,
            totalProteinGrams: 110,
            totalWaterML: 2_300
        ),
        routineSummary: RoutineDaySummary = RoutineDaySummary(
            date: Date(),
            statuses: [
                .init(template: .am, isCompleted: true, streakCount: 2),
                .init(template: .pm, isCompleted: true, streakCount: 2),
                .init(template: .grooming, isCompleted: false, streakCount: 0)
            ]
        ),
        userProfile: UserProfile? = UserProfile(
            displayName: "Mia",
            primaryGoal: .glowUp,
            targetDailySteps: 8_000,
            targetSleepHours: 8.0,
            targetProteinGrams: 110,
            targetWaterML: 2_500,
            onboardingCompleted: true
        ),
        glowScore: GlowScore? = nil,
        evaluatedAt: Date = Date()
    ) -> DailyRecapInput {
        DailyRecapInput(
            day: calendar.startOfDay(for: evaluatedAt),
            evaluatedAt: evaluatedAt,
            userProfile: userProfile,
            metricsSnapshot: MetricsRepositorySnapshot(
                metrics: metrics,
                connectionState: connectionState,
                source: .live,
                limitedFields: [],
                unsupportedFields: [],
                lastUpdatedAt: evaluatedAt
            ),
            nutritionSummary: nutritionSummary,
            routineSummary: routineSummary,
            glowScore: glowScore
        )
    }

    private func makeGlowScore(
        overallScore: Int,
        scores: [GlowScoreCategory: Int]
    ) -> GlowScore {
        GlowScore(
            date: makeDate(hour: 20),
            overallScore: overallScore,
            availableWeight: 100,
            totalWeight: 100,
            breakdowns: GlowScoreCategory.allCases.map { category in
                GlowScoreCategoryBreakdown(
                    category: category,
                    score: scores[category],
                    weight: 20,
                    status: scores[category] == nil ? .unavailable : .available,
                    dataState: scores[category] == nil ? .missing : .available,
                    summaryText: "",
                    explanation: ""
                )
            },
            explanations: [],
            configVersion: "test",
            computedAt: makeDate(hour: 20)
        )
    }

    private func makeDate(hour: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 4,
            day: 13,
            hour: hour
        )

        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
