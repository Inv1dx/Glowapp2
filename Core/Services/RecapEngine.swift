import Foundation

struct RecapConfig: Equatable, Sendable {
    struct EnergySettings: Equatable, Sendable {
        let weightBasedCaloriesPerKilogram: Double
        let fallbackBaselineCalories: Int
        let minimumBaselineCalories: Int
        let maximumBaselineCalories: Int
        let neutralBalanceThreshold: Int
        let activeCaloriesTarget: Double
    }

    let version: String
    let energy: EnergySettings
    let steadyDayScoreThreshold: Int
    let maintenanceRecommendationThreshold: Int
}

extension RecapConfig {
    static let stage7 = RecapConfig(
        version: "stage7.v1",
        energy: EnergySettings(
            weightBasedCaloriesPerKilogram: 22,
            fallbackBaselineCalories: 1_900,
            minimumBaselineCalories: 1_500,
            maximumBaselineCalories: 2_700,
            neutralBalanceThreshold: 100,
            activeCaloriesTarget: 350
        ),
        steadyDayScoreThreshold: 70,
        maintenanceRecommendationThreshold: 82
    )
}

struct RecapEngine {
    private struct AreaAssessment {
        let category: GlowScoreCategory
        let score: Int
    }

    private struct RecommendationDecision {
        let category: GlowScoreCategory
        let isMaintenance: Bool
        let availableAreaCount: Int
        let text: String
    }

    private enum BaselineSource {
        case weightBased
        case fallback
    }

    let config: RecapConfig
    let calendar: Calendar

    init(
        config: RecapConfig = .stage7,
        calendar: Calendar = .current
    ) {
        self.config = config
        self.calendar = calendar
    }

    func generateRecap(from input: DailyRecapInput) -> DailyRecap {
        let normalizedDay = calendar.startOfDay(for: input.day)
        let energyBalance = makeEnergyBalance(from: input)
        let recommendation = makeRecommendation(from: input)
        let summaryMessage = makeSummaryMessage(
            from: input,
            recommendation: recommendation
        )

        return DailyRecap(
            date: normalizedDay,
            generatedAt: input.evaluatedAt,
            metrics: input.metricsSnapshot.metrics,
            metricsConnectionState: input.metricsSnapshot.connectionState,
            limitedHealthFields: input.metricsSnapshot.limitedFields,
            unsupportedHealthFields: input.metricsSnapshot.unsupportedFields,
            nutritionSummary: input.nutritionSummary,
            routineSummary: input.routineSummary,
            glowScore: input.glowScore,
            energyBalance: energyBalance,
            weakestArea: recommendation.category,
            summaryMessage: summaryMessage,
            recommendationText: recommendation.text
        )
    }

    private func makeEnergyBalance(from input: DailyRecapInput) -> DailyRecapEnergyBalance {
        let caloriesIn = caloriesIn(from: input.nutritionSummary)
        let baseline = baselineEstimate(from: input)
        let activeCalories = availableHealthValue(
            field: .activeCalories,
            from: input.metricsSnapshot,
            value: input.metricsSnapshot.metrics?.activeCalories
        ).map { Int($0.rounded()) }

        let caloriesOut: Int?
        let outputState: RecapEnergyOutputState
        let caloriesOutExplanation: String

        switch (baseline.value, activeCalories) {
        case let (baselineValue?, activeCalories?):
            caloriesOut = baselineValue + activeCalories
            outputState = .estimated
            caloriesOutExplanation = baseline.source == .weightBased
                ? "Estimate = simple weight-based baseline + active calories."
                : "Estimate = simple baseline + active calories."
        case let (baselineValue?, nil):
            caloriesOut = baselineValue
            outputState = .partial
            caloriesOutExplanation = "Partial estimate. Active calories are unavailable today."
        case let (nil, activeCalories?):
            caloriesOut = activeCalories
            outputState = .partial
            caloriesOutExplanation = "Partial estimate. Baseline calories are unavailable."
        case (nil, nil):
            caloriesOut = nil
            outputState = .unavailable
            caloriesOutExplanation = "Estimated calories out is unavailable with today's data."
        }

        let balanceState: RecapEnergyBalanceState
        let balanceAmount: Int?
        let balanceExplanation: String

        if let caloriesIn, let caloriesOut {
            let delta = caloriesIn - caloriesOut
            let absoluteDelta = abs(delta)

            if absoluteDelta <= config.energy.neutralBalanceThreshold {
                balanceState = .neutral
                balanceAmount = absoluteDelta
                balanceExplanation = "Estimated intake and output landed close today."
            } else if delta < 0 {
                balanceState = .deficit
                balanceAmount = absoluteDelta
                balanceExplanation = "Estimated intake came in below output."
            } else {
                balanceState = .surplus
                balanceAmount = absoluteDelta
                balanceExplanation = "Estimated intake came in above output."
            }
        } else if caloriesIn == nil {
            balanceState = .unavailable
            balanceAmount = nil
            balanceExplanation = "Add calorie intake logs to see an estimated balance."
        } else {
            balanceState = .unavailable
            balanceAmount = nil
            balanceExplanation = "Estimated balance is unavailable with today's output data."
        }

        return DailyRecapEnergyBalance(
            caloriesIn: caloriesIn,
            estimatedCaloriesOut: caloriesOut,
            baselineCaloriesEstimate: baseline.value,
            activeCalories: activeCalories,
            outputState: outputState,
            balanceState: balanceState,
            balanceAmount: balanceAmount,
            caloriesOutExplanation: caloriesOutExplanation,
            balanceExplanation: balanceExplanation
        )
    }

    private func makeRecommendation(from input: DailyRecapInput) -> RecommendationDecision {
        let assessments = scoredAssessments(from: input)
        let category = assessments.first?.category ?? defaultMaintenanceCategory(for: input.userProfile)
        let weakestScore = assessments.first?.score ?? 100
        let isMaintenance = weakestScore >= config.maintenanceRecommendationThreshold

        let text = isMaintenance
            ? maintenanceRecommendation(for: category)
            : targetedRecommendation(for: category, input: input)

        return RecommendationDecision(
            category: category,
            isMaintenance: isMaintenance,
            availableAreaCount: assessments.count,
            text: text
        )
    }

    private func makeSummaryMessage(
        from input: DailyRecapInput,
        recommendation: RecommendationDecision
    ) -> String {
        let routinesCompleted = input.routineSummary.statuses.filter(\.isCompleted).count
        let hasAnySignal =
            (input.metricsSnapshot.metrics?.steps ?? 0) > 0 ||
            input.metricsSnapshot.metrics?.sleepDurationHours != nil ||
            input.nutritionSummary.totalCalories > 0 ||
            input.nutritionSummary.totalProteinGrams > 0 ||
            input.nutritionSummary.totalWaterML > 0 ||
            routinesCompleted > 0

        if recommendation.isMaintenance && recommendation.availableAreaCount >= 3 {
            return "Solid day overall."
        }

        if hasAnySignal {
            let overallScore = input.glowScore?.overallScore ?? 0
            let manualWins = [
                input.nutritionSummary.totalCalories > 0 || input.nutritionSummary.totalProteinGrams > 0,
                input.nutritionSummary.totalWaterML > 0,
                routinesCompleted >= 2
            ].filter { $0 }.count

            if overallScore >= config.steadyDayScoreThreshold || manualWins >= 2 {
                return "You kept the basics moving today."
            }

            return "Decent day, with one clear fix for tomorrow."
        }

        return "Good consistency beats perfect days."
    }

    private func scoredAssessments(from input: DailyRecapInput) -> [AreaAssessment] {
        let scoreBreakdownAssessments: [AreaAssessment] = input.glowScore?.breakdowns.compactMap { breakdown in
            guard breakdown.status == .available, let score = breakdown.score else {
                return nil
            }

            return AreaAssessment(category: breakdown.category, score: score)
        } ?? [AreaAssessment]()

        let assessments: [AreaAssessment] = scoreBreakdownAssessments.isEmpty
            ? fallbackAssessments(from: input)
            : scoreBreakdownAssessments

        return assessments.sorted(by: { lhs, rhs in
            if lhs.score == rhs.score {
                return areaPriority(lhs.category) < areaPriority(rhs.category)
            }

            return lhs.score < rhs.score
        })
    }

    private func fallbackAssessments(from input: DailyRecapInput) -> [AreaAssessment] {
        var assessments: [AreaAssessment] = []
        let userProfile = input.userProfile
        let metrics = input.metricsSnapshot.metrics

        if let sleepHours = availableHealthValue(
            field: .sleepDurationHours,
            from: input.metricsSnapshot,
            value: metrics?.sleepDurationHours
        ) {
            let targetSleep = userProfile?.targetSleepHours ?? UserProfile.defaultSleepHours
            let ratio = min(sleepHours, targetSleep) / targetSleep
            assessments.append(
                AreaAssessment(
                    category: .sleep,
                    score: clamp(Int((ratio * 100).rounded()), minimum: 20, maximum: 100)
                )
            )
        }

        var activityScores: [Int] = []

        if let steps = availableHealthValue(
            field: .steps,
            from: input.metricsSnapshot,
            value: metrics?.steps
        ) {
            let targetSteps = Double(userProfile?.targetDailySteps ?? UserProfile.defaultDailySteps)
            let stepRatio = Double(steps) / targetSteps
            activityScores.append(
                clamp(Int((min(stepRatio, 1) * 100).rounded()), minimum: 0, maximum: 100)
            )
        }

        if let activeCalories = availableHealthValue(
            field: .activeCalories,
            from: input.metricsSnapshot,
            value: metrics?.activeCalories
        ) {
            let activeRatio = activeCalories / config.energy.activeCaloriesTarget
            activityScores.append(
                clamp(Int((min(activeRatio, 1) * 100).rounded()), minimum: 0, maximum: 100)
            )
        }

        if !activityScores.isEmpty {
            let average = Int(
                (Double(activityScores.reduce(0, +)) / Double(activityScores.count)).rounded()
            )
            assessments.append(
                AreaAssessment(category: .activity, score: average)
            )
        }

        let hasNutritionLogs =
            input.nutritionSummary.totalCalories > 0 ||
            input.nutritionSummary.totalProteinGrams > 0
        let nutritionScore: Int
        if hasNutritionLogs {
            let targetProtein = Double(userProfile?.targetProteinGrams ?? UserProfile.defaultProteinGrams)
            let proteinRatio = Double(input.nutritionSummary.totalProteinGrams) / targetProtein
            let loggingBonus = input.nutritionSummary.totalCalories > 0 ? 10 : 0
            nutritionScore = clamp(
                Int((min(proteinRatio, 1) * 100).rounded()) + loggingBonus,
                minimum: 0,
                maximum: 100
            )
        } else {
            nutritionScore = 15
        }
        assessments.append(
            AreaAssessment(category: .nutrition, score: nutritionScore)
        )

        let hydrationScore: Int
        if input.nutritionSummary.totalWaterML > 0 {
            let targetWater = Double(userProfile?.targetWaterML ?? UserProfile.defaultWaterML)
            let waterRatio = Double(input.nutritionSummary.totalWaterML) / targetWater
            hydrationScore = clamp(
                Int((min(waterRatio, 1) * 100).rounded()),
                minimum: 0,
                maximum: 100
            )
        } else {
            hydrationScore = 15
        }
        assessments.append(
            AreaAssessment(category: .hydration, score: hydrationScore)
        )

        let completedRoutines = input.routineSummary.statuses.filter(\.isCompleted).count
        let routineScore = clamp(
            Int((Double(completedRoutines) / Double(RoutineTemplate.allCases.count) * 100).rounded()),
            minimum: 0,
            maximum: 100
        )
        assessments.append(
            AreaAssessment(category: .routineConsistency, score: routineScore)
        )

        return assessments
    }

    private func caloriesIn(from summary: NutritionDaySummary) -> Int? {
        summary.totalCalories > 0 ? summary.totalCalories : nil
    }

    // Stage 7 keeps calories-out intentionally coarse and configurable.
    private func baselineEstimate(from input: DailyRecapInput) -> (value: Int?, source: BaselineSource) {
        if let weightKg = availableHealthValue(
            field: .weightKg,
            from: input.metricsSnapshot,
            value: input.metricsSnapshot.metrics?.weightKg
        ) {
            let baseline = Int((weightKg * config.energy.weightBasedCaloriesPerKilogram).rounded())
            return (
                value: clamp(
                    baseline,
                    minimum: config.energy.minimumBaselineCalories,
                    maximum: config.energy.maximumBaselineCalories
                ),
                source: .weightBased
            )
        }

        return (value: config.energy.fallbackBaselineCalories, source: .fallback)
    }

    private func targetedRecommendation(
        for category: GlowScoreCategory,
        input: DailyRecapInput
    ) -> String {
        switch category {
        case .sleep:
            return "Tomorrow, protect your sleep window."
        case .activity:
            return "Tomorrow, push activity earlier so the day does not stall."
        case .nutrition:
            return "Tomorrow, aim to hit protein sooner."
        case .hydration:
            return "Tomorrow, focus on hydration earlier in the day."
        case .routineConsistency:
            if !input.routineSummary.status(for: .pm).isCompleted {
                return "Tomorrow, finish your PM routine before bed."
            }

            if !input.routineSummary.status(for: .am).isCompleted {
                return "Tomorrow, finish your AM routine earlier."
            }

            if !input.routineSummary.status(for: .grooming).isCompleted {
                return "Tomorrow, finish your grooming reset earlier."
            }

            return "Tomorrow, keep your routines tight at both ends of the day."
        }
    }

    private func maintenanceRecommendation(for category: GlowScoreCategory) -> String {
        switch category {
        case .sleep:
            return "Tomorrow, protect the sleep rhythm you built today."
        case .activity:
            return "Tomorrow, keep activity moving early."
        case .nutrition:
            return "Tomorrow, keep your meals protein-first."
        case .hydration:
            return "Tomorrow, keep water in reach early."
        case .routineConsistency:
            return "Tomorrow, repeat the routine consistency from today."
        }
    }

    private func defaultMaintenanceCategory(for userProfile: UserProfile?) -> GlowScoreCategory {
        switch userProfile?.primaryGoal {
        case .fatLoss:
            return .activity
        case .leanGain:
            return .nutrition
        case .routineReset:
            return .routineConsistency
        case .glowUp, .none:
            return .sleep
        }
    }

    private func areaPriority(_ category: GlowScoreCategory) -> Int {
        switch category {
        case .sleep:
            return 0
        case .activity:
            return 1
        case .nutrition:
            return 2
        case .hydration:
            return 3
        case .routineConsistency:
            return 4
        }
    }

    private func availableHealthValue<Value>(
        field: DailyMetrics.Field,
        from snapshot: MetricsRepositorySnapshot,
        value: Value?
    ) -> Value? {
        if snapshot.unsupportedFields.contains(field) || snapshot.limitedFields.contains(field) {
            return nil
        }

        return value
    }

    private func clamp(_ value: Int, minimum: Int, maximum: Int) -> Int {
        min(max(value, minimum), maximum)
    }
}
