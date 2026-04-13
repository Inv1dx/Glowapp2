import XCTest
@testable import GlowApp

final class GlowScoreEngineTests: XCTestCase {
    private lazy var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private lazy var engine = GlowScoreEngine(
        config: .stage5,
        calendar: calendar
    )

    func testPerfectDayScoresOneHundred() {
        let input = makeInput()

        let score = engine.evaluate(input)

        XCTAssertEqual(score.overallScore, 100)
        XCTAssertEqual(score.availableWeight, 100)
        XCTAssertEqual(score.breakdown(for: .sleep)?.score, 100)
        XCTAssertEqual(score.breakdown(for: .activity)?.score, 100)
        XCTAssertEqual(score.breakdown(for: .nutrition)?.score, 100)
        XCTAssertEqual(score.breakdown(for: .hydration)?.score, 100)
        XCTAssertEqual(score.breakdown(for: .routineConsistency)?.score, 100)
    }

    func testNearPerfectDayStaysHighButNotPerfect() {
        let input = makeInput(
            sleepHours: .available(7.6),
            steps: .available(7_100),
            activeCalories: .available(300),
            waterML: .available(2_200)
        )

        let score = engine.evaluate(input)

        XCTAssertGreaterThanOrEqual(score.overallScore, 85)
        XCTAssertLessThan(score.overallScore, 100)
    }

    func testLowSleepButGoodNutritionKeepsNutritionHigh() {
        let input = makeInput(
            sleepHours: .available(5.9)
        )

        let score = engine.evaluate(input)

        XCTAssertLessThan(score.breakdown(for: .sleep)?.score ?? 0, 60)
        XCTAssertEqual(score.breakdown(for: .nutrition)?.score, 100)
        XCTAssertTrue(score.explanations.contains("Sleep was well below target."))
        XCTAssertTrue(score.explanations.contains("Protein progress helped your score."))
    }

    func testGoodRoutinesWithWeakActivityShowSplitClearly() {
        let input = makeInput(
            evaluatedAt: makeDate(hour: 18, minute: 0),
            steps: .available(1_500),
            activeCalories: .available(60)
        )

        let score = engine.evaluate(input)

        XCTAssertGreaterThan(score.breakdown(for: .routineConsistency)?.score ?? 0, 90)
        XCTAssertLessThan(score.breakdown(for: .activity)?.score ?? 0, 50)
    }

    func testNoFoodLoggedMarksNutritionAsIncompleteButKeepsCategoryAvailable() {
        let input = makeInput(
            caloriesIn: .available(0),
            proteinGrams: .available(0)
        )

        let score = engine.evaluate(input)
        let nutrition = tryUnwrap(score.breakdown(for: .nutrition))

        XCTAssertEqual(nutrition.status, .available)
        XCTAssertEqual(nutrition.explanation, "Nutrition logging is incomplete today.")
        XCTAssertLessThan(nutrition.score ?? 101, 50)
    }

    func testDeniedHealthKitFallsBackToManualOnlyDenominator() {
        let input = makeInput(
            sleepHours: .unavailable(.appleHealthNotConnected),
            steps: .unavailable(.appleHealthNotConnected),
            activeCalories: .unavailable(.appleHealthNotConnected)
        )

        let score = engine.evaluate(input)

        XCTAssertEqual(score.availableWeight, 55)
        XCTAssertEqual(score.breakdown(for: .sleep)?.status, .unavailable)
        XCTAssertEqual(score.breakdown(for: .activity)?.status, .unavailable)
        XCTAssertTrue(score.explanations.contains("Connect Apple Health for a fuller score."))
        XCTAssertGreaterThan(score.overallScore, 0)
    }

    func testMissingSleepDataProducesMissingState() {
        let input = makeInput(
            sleepHours: .missing()
        )

        let score = engine.evaluate(input)
        let sleep = tryUnwrap(score.breakdown(for: .sleep))

        XCTAssertEqual(sleep.status, .unavailable)
        XCTAssertEqual(sleep.dataState, .missing)
        XCTAssertEqual(sleep.explanation, "No sleep data available yet.")
    }

    func testMissingActivityDataProducesMissingState() {
        let input = makeInput(
            steps: .missing(),
            activeCalories: .missing()
        )

        let score = engine.evaluate(input)
        let activity = tryUnwrap(score.breakdown(for: .activity))

        XCTAssertEqual(activity.status, .unavailable)
        XCTAssertEqual(activity.dataState, .missing)
        XCTAssertEqual(activity.explanation, "No activity data is available yet.")
    }

    func testPartialManualDataStillScoresDeterministically() {
        let input = makeInput(
            caloriesIn: .available(300),
            proteinGrams: .available(35),
            waterML: .available(400)
        )

        let score = engine.evaluate(input)

        XCTAssertNotNil(score.breakdown(for: .nutrition)?.score)
        XCTAssertNotNil(score.breakdown(for: .hydration)?.score)
        XCTAssertGreaterThan(score.overallScore, 0)
        XCTAssertLessThan(score.overallScore, 100)
    }

    func testEarlyDayProgressGetsGrace() {
        let input = makeInput(
            evaluatedAt: makeDate(hour: 8, minute: 0),
            steps: .available(0),
            activeCalories: .available(0),
            caloriesIn: .available(0),
            proteinGrams: .available(0),
            waterML: .available(0),
            amRoutineCompleted: .available(false),
            pmRoutineCompleted: .available(false),
            groomingCompleted: .available(false)
        )

        let score = engine.evaluate(input)

        XCTAssertGreaterThanOrEqual(score.breakdown(for: .activity)?.score ?? 0, 35)
        XCTAssertGreaterThanOrEqual(score.breakdown(for: .nutrition)?.score ?? 0, 40)
        XCTAssertGreaterThanOrEqual(score.breakdown(for: .hydration)?.score ?? 0, 45)
    }

    func testPmRoutineDoesNotPenalizeDuringMorning() {
        let morningInput = makeInput(
            evaluatedAt: makeDate(hour: 9, minute: 0),
            amRoutineCompleted: .available(true),
            pmRoutineCompleted: .available(false),
            groomingCompleted: .available(false)
        )
        let lateInput = makeInput(
            evaluatedAt: makeDate(hour: 23, minute: 10),
            amRoutineCompleted: .available(true),
            pmRoutineCompleted: .available(false),
            groomingCompleted: .available(false)
        )

        let morningScore = engine.evaluate(morningInput)
        let lateScore = engine.evaluate(lateInput)

        XCTAssertGreaterThan(morningScore.breakdown(for: .routineConsistency)?.score ?? 0, 70)
        XCTAssertLessThanOrEqual(lateScore.breakdown(for: .routineConsistency)?.score ?? 101, 40)
    }

    func testSleepThresholdBoundariesStayStable() {
        let fullCreditInput = makeInput(
            sleepHours: .available(7.75)
        )
        let minimumCreditInput = makeInput(
            sleepHours: .available(5.0)
        )

        let fullCreditScore = engine.evaluate(fullCreditInput)
        let minimumCreditScore = engine.evaluate(minimumCreditInput)

        XCTAssertEqual(fullCreditScore.breakdown(for: .sleep)?.score, 100)
        XCTAssertEqual(minimumCreditScore.breakdown(for: .sleep)?.score, 20)
    }

    func testExplanationGenerationIncludesPositiveNegativeAndMissingNotes() {
        let input = makeInput(
            sleepHours: .missing(),
            waterML: .available(200)
        )

        let score = engine.evaluate(input)

        XCTAssertTrue(score.explanations.contains("No sleep data available yet."))
        XCTAssertTrue(score.explanations.contains("Protein progress helped your score."))
        XCTAssertTrue(score.explanations.contains("Hydration is behind for this point in the day."))
    }

    private func makeInput(
        evaluatedAt: Date? = nil,
        userProfile: UserProfile? = UserProfile(
            displayName: "Mia",
            primaryGoal: .glowUp,
            targetDailySteps: 8_000,
            targetSleepHours: 8.0,
            targetProteinGrams: 110,
            targetWaterML: 2_500,
            onboardingCompleted: true
        ),
        sleepHours: GlowScoreMeasurement<Double> = .available(8.0),
        steps: GlowScoreMeasurement<Int> = .available(8_000),
        activeCalories: GlowScoreMeasurement<Double> = .available(350),
        caloriesIn: GlowScoreMeasurement<Int> = .available(900),
        proteinGrams: GlowScoreMeasurement<Int> = .available(110),
        waterML: GlowScoreMeasurement<Int> = .available(2_500),
        amRoutineCompleted: GlowScoreMeasurement<Bool> = .available(true),
        pmRoutineCompleted: GlowScoreMeasurement<Bool> = .available(true),
        groomingCompleted: GlowScoreMeasurement<Bool> = .available(true)
    ) -> GlowScoreInput {
        let evaluatedAt = evaluatedAt ?? makeDate(hour: 20, minute: 0)

        return GlowScoreInput(
            day: calendar.startOfDay(for: evaluatedAt),
            evaluatedAt: evaluatedAt,
            userProfile: userProfile,
            sleepHours: sleepHours,
            steps: steps,
            activeCalories: activeCalories,
            caloriesIn: caloriesIn,
            proteinGrams: proteinGrams,
            waterML: waterML,
            amRoutineCompleted: amRoutineCompleted,
            pmRoutineCompleted: pmRoutineCompleted,
            groomingCompleted: groomingCompleted
        )
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 4,
            day: 13,
            hour: hour,
            minute: minute
        )

        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    private func tryUnwrap(_ breakdown: GlowScoreCategoryBreakdown?) -> GlowScoreCategoryBreakdown {
        guard let breakdown else {
            XCTFail("Expected breakdown")
            return GlowScoreCategoryBreakdown(
                category: .sleep,
                score: nil,
                weight: 0,
                status: .unavailable,
                dataState: .missing,
                summaryText: "",
                explanation: ""
            )
        }

        return breakdown
    }
}

private extension GlowScore {
    func breakdown(for category: GlowScoreCategory) -> GlowScoreCategoryBreakdown? {
        breakdowns.first { $0.category == category }
    }
}
