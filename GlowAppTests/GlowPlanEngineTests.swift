import XCTest
@testable import GlowApp

final class GlowPlanEngineTests: XCTestCase {
    private lazy var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private lazy var scoreEngine = GlowScoreEngine(
        config: .stage5,
        calendar: calendar
    )

    private lazy var engine = GlowPlanEngine(calendar: calendar)

    func testLowSleepGeneratesSleepFocusedAction() {
        let input = makeInput(
            metrics: DailyMetrics(
                date: makeDate(hour: 20),
                steps: 8_300,
                activeCalories: 360,
                workoutsCount: 1,
                sleepDurationHours: 5.9,
                weightKg: nil
            )
        )

        let plan = engine.generatePlan(from: input)

        XCTAssertTrue(plan.actions.contains { $0.kind == .sleepWindDown })
        XCTAssertEqual(plan.actions.first?.kind, .sleepWindDown)
        XCTAssertActionCount(plan)
    }

    func testLowHydrationGeneratesHydrationAction() {
        let input = makeInput(
            nutritionSummary: NutritionDaySummary(
                date: makeDate(hour: 19),
                totalCalories: 1_200,
                totalProteinGrams: 110,
                totalWaterML: 500
            )
        )

        let plan = engine.generatePlan(from: input)

        XCTAssertTrue(plan.actions.contains { $0.kind == .hydrationGoal })
        XCTAssertActionCount(plan)
    }

    func testLowProteinGeneratesProteinAction() {
        let input = makeInput(
            nutritionSummary: NutritionDaySummary(
                date: makeDate(hour: 18),
                totalCalories: 900,
                totalProteinGrams: 35,
                totalWaterML: 2_500
            )
        )

        let plan = engine.generatePlan(from: input)

        XCTAssertTrue(plan.actions.contains { $0.kind == .proteinGoal })
        XCTAssertActionCount(plan)
    }

    func testIncompletePmRoutineGeneratesPmAction() {
        let input = makeInput(
            routineSummary: routineSummary(am: true, pm: false, grooming: true),
            evaluatedAt: makeDate(hour: 19)
        )

        let plan = engine.generatePlan(from: input)

        XCTAssertTrue(plan.actions.contains { $0.kind == .eveningRoutine })
        XCTAssertActionCount(plan)
    }

    func testWeakActivityGeneratesWalkAction() {
        let input = makeInput(
            metrics: DailyMetrics(
                date: makeDate(hour: 17),
                steps: 1_900,
                activeCalories: 90,
                workoutsCount: 0,
                sleepDurationHours: 8.0,
                weightKg: nil
            ),
            evaluatedAt: makeDate(hour: 17)
        )

        let plan = engine.generatePlan(from: input)

        XCTAssertTrue(plan.actions.contains { $0.kind == .activityWalk })
        XCTAssertActionCount(plan)
    }

    func testStrongMetricsGenerateMaintenancePlan() {
        let input = makeInput(
            metrics: DailyMetrics(
                date: makeDate(hour: 20),
                steps: 9_200,
                activeCalories: 410,
                workoutsCount: 1,
                sleepDurationHours: 8.1,
                weightKg: nil
            ),
            nutritionSummary: NutritionDaySummary(
                date: makeDate(hour: 20),
                totalCalories: 1_700,
                totalProteinGrams: 120,
                totalWaterML: 2_700
            ),
            routineSummary: routineSummary(am: true, pm: true, grooming: true)
        )

        let plan = engine.generatePlan(from: input)

        XCTAssertEqual(plan.mode, .maintenance)
        XCTAssertTrue(plan.actions.allSatisfy {
            switch $0.kind {
            case .maintainSleep, .maintainActivity, .maintainProtein, .maintainHydration:
                true
            default:
                false
            }
        })
        XCTAssertActionCount(plan)
    }

    func testDuplicateRulesDoNotCreateDuplicateActions() {
        let input = makeInput(
            nutritionSummary: NutritionDaySummary(
                date: makeDate(hour: 20),
                totalCalories: 300,
                totalProteinGrams: 15,
                totalWaterML: 250
            )
        )

        let plan = engine.generatePlan(from: input)
        let uniqueKinds = Set(plan.actions.map(\.kind))

        XCTAssertEqual(uniqueKinds.count, plan.actions.count)
        XCTAssertEqual(plan.actions.filter { $0.kind == .hydrationGoal }.count, 1)
        XCTAssertEqual(plan.actions.filter { $0.kind == .proteinGoal }.count, 1)
    }

    func testPartialDataStillYieldsSensiblePlan() {
        let input = makeInput(
            metrics: nil,
            connectionState: .notConnected,
            nutritionSummary: NutritionDaySummary(
                date: makeDate(hour: 20),
                totalCalories: 400,
                totalProteinGrams: 20,
                totalWaterML: 600
            ),
            routineSummary: routineSummary(am: true, pm: false, grooming: false),
            evaluatedAt: makeDate(hour: 20)
        )

        let plan = engine.generatePlan(from: input)

        XCTAssertTrue(plan.actions.contains { $0.kind == .proteinGoal })
        XCTAssertTrue(plan.actions.contains { $0.kind == .hydrationGoal })
        XCTAssertTrue(plan.actions.contains { $0.kind == .eveningRoutine })
        XCTAssertActionCount(plan)
    }

    private func makeInput(
        metrics: DailyMetrics? = DailyMetrics(
            date: Date(),
            steps: 8_000,
            activeCalories: 350,
            workoutsCount: 1,
            sleepDurationHours: 8.0,
            weightKg: nil
        ),
        connectionState: MetricsConnectionState = .connected,
        nutritionSummary: NutritionDaySummary = NutritionDaySummary(
            date: Date(),
            totalCalories: 1_400,
            totalProteinGrams: 110,
            totalWaterML: 2_500
        ),
        routineSummary: RoutineDaySummary = RoutineDaySummary(
            date: Date(),
            statuses: [
                .init(template: .am, isCompleted: true, streakCount: 3),
                .init(template: .pm, isCompleted: true, streakCount: 2),
                .init(template: .grooming, isCompleted: true, streakCount: 4)
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
        evaluatedAt: Date = Date()
    ) -> GlowPlanInput {
        let snapshot = MetricsRepositorySnapshot(
            metrics: metrics,
            connectionState: connectionState,
            source: .live,
            limitedFields: [],
            unsupportedFields: [],
            lastUpdatedAt: evaluatedAt
        )
        let scoreInput = GlowScoreInput(
            day: calendar.startOfDay(for: evaluatedAt),
            evaluatedAt: evaluatedAt,
            userProfile: userProfile,
            sleepHours: healthMeasurement(
                field: .sleepDurationHours,
                value: metrics?.sleepDurationHours,
                snapshot: snapshot
            ),
            steps: healthMeasurement(
                field: .steps,
                value: metrics?.steps,
                snapshot: snapshot
            ),
            activeCalories: healthMeasurement(
                field: .activeCalories,
                value: metrics?.activeCalories,
                snapshot: snapshot
            ),
            caloriesIn: .available(nutritionSummary.totalCalories),
            proteinGrams: .available(nutritionSummary.totalProteinGrams),
            waterML: .available(nutritionSummary.totalWaterML),
            amRoutineCompleted: .available(routineSummary.status(for: .am).isCompleted),
            pmRoutineCompleted: .available(routineSummary.status(for: .pm).isCompleted),
            groomingCompleted: .available(routineSummary.status(for: .grooming).isCompleted)
        )
        let glowScore = scoreEngine.evaluate(scoreInput)

        return GlowPlanInput(
            day: calendar.startOfDay(for: evaluatedAt),
            evaluatedAt: evaluatedAt,
            userProfile: userProfile,
            metricsSnapshot: snapshot,
            nutritionSummary: nutritionSummary,
            routineSummary: routineSummary,
            glowScore: glowScore
        )
    }

    private func routineSummary(am: Bool, pm: Bool, grooming: Bool) -> RoutineDaySummary {
        RoutineDaySummary(
            date: makeDate(hour: 12),
            statuses: [
                .init(template: .am, isCompleted: am, streakCount: am ? 2 : 0),
                .init(template: .pm, isCompleted: pm, streakCount: pm ? 2 : 0),
                .init(template: .grooming, isCompleted: grooming, streakCount: grooming ? 2 : 0)
            ]
        )
    }

    private func healthMeasurement<Value: Equatable & Sendable>(
        field: DailyMetrics.Field,
        value: Value?,
        snapshot: MetricsRepositorySnapshot
    ) -> GlowScoreMeasurement<Value> {
        let limitedFields = Set(snapshot.limitedFields)
        let unsupportedFields = Set(snapshot.unsupportedFields)

        if unsupportedFields.contains(field) {
            return .unavailable(.unsupported)
        }

        if limitedFields.contains(field) {
            return .unavailable(.accessLimited)
        }

        switch snapshot.connectionState {
        case .unavailable:
            return .unavailable(.appleHealthUnavailable)
        case .notConnected:
            return .unavailable(.appleHealthNotConnected)
        case .needsAttention:
            return .unavailable(.accessLimited)
        case .connected:
            if let value {
                return .available(value)
            }

            return .missing()
        }
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

    private func XCTAssertActionCount(_ plan: GlowPlan, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertGreaterThanOrEqual(plan.actions.count, 3, file: file, line: line)
        XCTAssertLessThanOrEqual(plan.actions.count, 5, file: file, line: line)
    }
}
