import Foundation

struct GlowScoreEngine {
    let config: GlowScoreConfig
    let calendar: Calendar

    init(
        config: GlowScoreConfig = .stage5,
        calendar: Calendar = .current
    ) {
        self.config = config
        self.calendar = calendar
    }

    func evaluate(_ input: GlowScoreInput) -> GlowScore {
        let normalizedDay = calendar.startOfDay(for: input.day)
        let breakdowns = [
            evaluateSleep(input),
            evaluateActivity(input),
            evaluateNutrition(input),
            evaluateHydration(input),
            evaluateRoutineConsistency(input)
        ]

        let availableBreakdowns = breakdowns.filter { $0.status == .available }
        let availableWeight = availableBreakdowns.reduce(0) { $0 + $1.weight }
        let weightedTotal = availableBreakdowns.reduce(0.0) { partialResult, breakdown in
            partialResult + (Double(breakdown.score ?? 0) * Double(breakdown.weight))
        }

        // Missing categories are removed from the denominator instead of being forced to zero.
        let overallScore = availableWeight == 0
            ? 0
            : clamp(Int((weightedTotal / Double(availableWeight)).rounded()), minimum: 0, maximum: 100)

        return GlowScore(
            date: normalizedDay,
            overallScore: overallScore,
            availableWeight: availableWeight,
            totalWeight: config.categoryWeights.total,
            breakdowns: breakdowns,
            explanations: orderedUnique(breakdowns.map(\.explanation)),
            configVersion: config.version,
            computedAt: input.evaluatedAt
        )
    }

    private func evaluateSleep(_ input: GlowScoreInput) -> GlowScoreCategoryBreakdown {
        let category: GlowScoreCategory = .sleep
        let weight = config.categoryWeights.weight(for: category)

        guard case .available = input.sleepHours.availability, let sleepHours = input.sleepHours.value else {
            return unavailableBreakdown(
                for: category,
                weight: weight,
                availability: input.sleepHours.availability,
                missingText: "No sleep data available yet."
            )
        }

        let targetSleep = input.userProfile?.targetSleepHours ?? config.fallbackTargets.sleepHours
        let delta = abs(sleepHours - targetSleep)
        let score: Int

        if delta <= config.sleep.fullCreditDeltaHours {
            score = 100
        } else if delta >= config.sleep.zeroCreditDeltaHours {
            score = config.sleep.minimumScore
        } else {
            let progress = (delta - config.sleep.fullCreditDeltaHours) /
                (config.sleep.zeroCreditDeltaHours - config.sleep.fullCreditDeltaHours)
            let rawScore = 100 - (progress * Double(100 - config.sleep.minimumScore))
            score = clamp(Int(rawScore.rounded()), minimum: config.sleep.minimumScore, maximum: 100)
        }

        let explanation: String
        if delta <= 0.5 {
            explanation = "Sleep matched your target well."
        } else if sleepHours < targetSleep {
            explanation = delta <= 1.0
                ? "Sleep was slightly below target."
                : "Sleep was well below target."
        } else {
            explanation = delta <= 1.0
                ? "Sleep ran slightly above target."
                : "Sleep ran well above target."
        }

        return GlowScoreCategoryBreakdown(
            category: category,
            score: score,
            weight: weight,
            status: .available,
            dataState: .available,
            summaryText: "\(formatHours(sleepHours)) / \(formatHours(targetSleep)) hr target",
            explanation: explanation
        )
    }

    private func evaluateActivity(_ input: GlowScoreInput) -> GlowScoreCategoryBreakdown {
        let category: GlowScoreCategory = .activity
        let weight = config.categoryWeights.weight(for: category)
        let stepTarget = Double(input.userProfile?.targetDailySteps ?? config.fallbackTargets.dailySteps)

        let stepResult = input.steps.value.map {
            cumulativeResult(
                current: Double($0),
                target: stepTarget,
                graceFactor: config.activity.graceFactor,
                evaluatedAt: input.evaluatedAt
            )
        }

        let activeCaloriesResult = input.activeCalories.value.map {
            cumulativeResult(
                current: $0,
                target: config.activity.activeCaloriesTarget,
                graceFactor: config.activity.graceFactor,
                evaluatedAt: input.evaluatedAt
            )
        }

        let score: Int?
        if let stepResult, let activeCaloriesResult {
            let weightedScore = (Double(stepResult.score) * config.activity.stepsWeight) +
                (Double(activeCaloriesResult.score) * config.activity.activeCaloriesWeight)
            score = clamp(Int(weightedScore.rounded()), minimum: 0, maximum: 100)
        } else if let stepResult {
            score = stepResult.score
        } else if let activeCaloriesResult {
            score = activeCaloriesResult.score
        } else {
            score = nil
        }

        guard let score else {
            return unavailableBreakdown(
                for: category,
                weight: weight,
                availability: mergedAvailability(primary: input.steps.availability, secondary: input.activeCalories.availability),
                missingText: "No activity data is available yet."
            )
        }

        let summaryText: String
        if let steps = input.steps.value, let activeCalories = input.activeCalories.value {
            summaryText = "\(steps.formatted()) / \(Int(stepTarget).formatted()) steps • \(Int(activeCalories.rounded()).formatted()) active kcal"
        } else if let steps = input.steps.value {
            summaryText = "\(steps.formatted()) / \(Int(stepTarget).formatted()) steps"
        } else {
            let activeCalories = Int((input.activeCalories.value ?? 0).rounded())
            summaryText = "\(activeCalories.formatted()) / \(Int(config.activity.activeCaloriesTarget).formatted()) active kcal"
        }

        let primaryPace = stepResult?.paceRatio ?? activeCaloriesResult?.paceRatio ?? 0
        let explanation: String
        if input.steps.value == nil, input.activeCalories.value != nil {
            explanation = primaryPace >= 1
                ? "Active calories are carrying activity well."
                : "Active calories are helping while steps stay unavailable."
        } else if primaryPace >= 1 {
            explanation = "Activity is on pace for this point in the day."
        } else if primaryPace >= 0.75 {
            explanation = "Activity is slightly behind for this point in the day."
        } else {
            explanation = "Activity is behind for this point in the day."
        }

        return GlowScoreCategoryBreakdown(
            category: category,
            score: score,
            weight: weight,
            status: .available,
            dataState: .available,
            summaryText: summaryText,
            explanation: explanation
        )
    }

    private func evaluateNutrition(_ input: GlowScoreInput) -> GlowScoreCategoryBreakdown {
        let category: GlowScoreCategory = .nutrition
        let weight = config.categoryWeights.weight(for: category)

        guard case .available = input.proteinGrams.availability, let proteinGrams = input.proteinGrams.value else {
            return unavailableBreakdown(
                for: category,
                weight: weight,
                availability: input.proteinGrams.availability,
                missingText: "Nutrition logging is incomplete today."
            )
        }

        let caloriesIn = input.caloriesIn.value ?? 0
        let proteinTarget = Double(input.userProfile?.targetProteinGrams ?? config.fallbackTargets.proteinGrams)
        let proteinResult = cumulativeResult(
            current: Double(proteinGrams),
            target: proteinTarget,
            graceFactor: config.nutrition.graceFactor,
            evaluatedAt: input.evaluatedAt
        )
        let loggingScore = caloriesLoggingScore(caloriesIn)
        let weightedScore = (Double(proteinResult.score) * config.nutrition.proteinWeight) +
            (Double(loggingScore) * config.nutrition.caloriesLoggingWeight)
        let score = clamp(Int(weightedScore.rounded()), minimum: 0, maximum: 100)

        let summaryText: String
        if caloriesIn > 0 {
            summaryText = "\(proteinGrams.formatted()) / \(Int(proteinTarget).formatted()) g protein • \(caloriesIn.formatted()) kcal logged"
        } else {
            summaryText = "\(proteinGrams.formatted()) / \(Int(proteinTarget).formatted()) g protein"
        }

        let explanation: String
        if proteinGrams == 0 && caloriesIn == 0 {
            explanation = "Nutrition logging is incomplete today."
        } else if proteinResult.paceRatio >= 1 {
            explanation = "Protein progress helped your score."
        } else if proteinGrams == 0 && caloriesIn > 0 {
            explanation = "Food is logged, but protein is still light."
        } else if proteinResult.paceRatio >= 0.65 {
            explanation = "Protein is building, but still behind pace."
        } else {
            explanation = "Nutrition is behind for this point in the day."
        }

        return GlowScoreCategoryBreakdown(
            category: category,
            score: score,
            weight: weight,
            status: .available,
            dataState: .available,
            summaryText: summaryText,
            explanation: explanation
        )
    }

    private func evaluateHydration(_ input: GlowScoreInput) -> GlowScoreCategoryBreakdown {
        let category: GlowScoreCategory = .hydration
        let weight = config.categoryWeights.weight(for: category)

        guard case .available = input.waterML.availability, let waterML = input.waterML.value else {
            return unavailableBreakdown(
                for: category,
                weight: weight,
                availability: input.waterML.availability,
                missingText: "Hydration data is unavailable today."
            )
        }

        let waterTarget = Double(input.userProfile?.targetWaterML ?? config.fallbackTargets.waterML)
        let hydrationResult = cumulativeResult(
            current: Double(waterML),
            target: waterTarget,
            graceFactor: config.hydration.graceFactor,
            evaluatedAt: input.evaluatedAt
        )

        let explanation: String
        if hydrationResult.paceRatio >= 1 {
            explanation = "Hydration is on pace for this point in the day."
        } else {
            explanation = "Hydration is behind for this point in the day."
        }

        return GlowScoreCategoryBreakdown(
            category: category,
            score: hydrationResult.score,
            weight: weight,
            status: .available,
            dataState: .available,
            summaryText: "\(waterML.formatted()) / \(Int(waterTarget).formatted()) mL water",
            explanation: explanation
        )
    }

    private func evaluateRoutineConsistency(_ input: GlowScoreInput) -> GlowScoreCategoryBreakdown {
        let category: GlowScoreCategory = .routineConsistency
        let weight = config.categoryWeights.weight(for: category)

        guard
            case .available = input.amRoutineCompleted.availability,
            let amCompleted = input.amRoutineCompleted.value,
            case .available = input.pmRoutineCompleted.availability,
            let pmCompleted = input.pmRoutineCompleted.value,
            case .available = input.groomingCompleted.availability,
            let groomingCompleted = input.groomingCompleted.value
        else {
            return unavailableBreakdown(
                for: category,
                weight: weight,
                availability: mergedAvailability(
                    primary: input.amRoutineCompleted.availability,
                    secondary: mergedAvailability(
                        primary: input.pmRoutineCompleted.availability,
                        secondary: input.groomingCompleted.availability
                    )
                ),
                missingText: "Routine data is unavailable today."
            )
        }

        let amScore = routineScore(
            isCompleted: amCompleted,
            window: config.routine.amWindow,
            evaluatedAt: input.evaluatedAt
        )
        let pmScore = routineScore(
            isCompleted: pmCompleted,
            window: config.routine.pmWindow,
            evaluatedAt: input.evaluatedAt
        )
        let groomingScore = routineScore(
            isCompleted: groomingCompleted,
            window: config.routine.groomingWindow,
            evaluatedAt: input.evaluatedAt
        )

        let rawScore =
            (Double(amScore) * config.routine.weights.am) +
            (Double(pmScore) * config.routine.weights.pm) +
            (Double(groomingScore) * config.routine.weights.grooming)
        let score = clamp(Int(rawScore.rounded()), minimum: 0, maximum: 100)
        let completedCount = [amCompleted, pmCompleted, groomingCompleted].filter { $0 }.count

        let explanation: String
        if completedCount == 3 {
            explanation = "Routine consistency boosted your score."
        } else if completedCount >= 2 || score >= 70 {
            explanation = "Routine consistency helped your score."
        } else if score >= 40 {
            explanation = "Routine consistency still has room later today."
        } else {
            explanation = "Routine consistency is dragging the score down."
        }

        return GlowScoreCategoryBreakdown(
            category: category,
            score: score,
            weight: weight,
            status: .available,
            dataState: .available,
            summaryText: "\(completedCount.formatted()) / 3 routines done",
            explanation: explanation
        )
    }

    private func unavailableBreakdown(
        for category: GlowScoreCategory,
        weight: Int,
        availability: GlowScoreMeasurementAvailability,
        missingText: String
    ) -> GlowScoreCategoryBreakdown {
        let explanation: String
        let dataState: GlowScoreDataState

        switch availability {
        case .available:
            explanation = missingText
            dataState = .available
        case .missing:
            explanation = missingText
            dataState = .missing
        case .unavailable(let reason):
            explanation = unavailableExplanation(for: category, reason: reason)
            dataState = .unavailable
        }

        return GlowScoreCategoryBreakdown(
            category: category,
            score: nil,
            weight: weight,
            status: .unavailable,
            dataState: dataState,
            summaryText: explanation,
            explanation: explanation
        )
    }

    private func mergedAvailability(
        primary: GlowScoreMeasurementAvailability,
        secondary: GlowScoreMeasurementAvailability
    ) -> GlowScoreMeasurementAvailability {
        if case .available = primary {
            return primary
        }

        if case .available = secondary {
            return secondary
        }

        if case .missing = primary, case .missing = secondary {
            return .missing
        }

        if case .unavailable(let reason) = primary {
            return .unavailable(reason)
        }

        if case .unavailable(let reason) = secondary {
            return .unavailable(reason)
        }

        return .missing
    }

    private func unavailableExplanation(
        for category: GlowScoreCategory,
        reason: GlowScoreUnavailableReason
    ) -> String {
        switch reason {
        case .appleHealthNotConnected, .accessLimited:
            return "Connect Apple Health for a fuller score."
        case .appleHealthUnavailable, .unsupported:
            switch category {
            case .sleep:
                return "Sleep data is unavailable on this device."
            case .activity:
                return "Activity data is unavailable on this device."
            case .nutrition:
                return "Nutrition data is unavailable on this device."
            case .hydration:
                return "Hydration data is unavailable on this device."
            case .routineConsistency:
                return "Routine data is unavailable on this device."
            }
        case .unavailable:
            switch category {
            case .sleep:
                return "No sleep data available yet."
            case .activity:
                return "No activity data is available yet."
            case .nutrition:
                return "Nutrition logging is incomplete today."
            case .hydration:
                return "Hydration data is unavailable today."
            case .routineConsistency:
                return "Routine data is unavailable today."
            }
        }
    }

    private func cumulativeResult(
        current: Double,
        target: Double,
        graceFactor: Double,
        evaluatedAt: Date
    ) -> (score: Int, expectedProgress: Double, paceRatio: Double) {
        guard target > 0 else {
            return (0, 1.0, 0)
        }

        let expectedProgress = progressThroughDay(at: evaluatedAt)
        let expectedTarget = max(target * max(expectedProgress, 0.01), 1)
        let paceRatio = max(0, current / expectedTarget)
        let graceScore = (1 - expectedProgress) * graceFactor * 100
        let earnedRange = 100 - graceScore
        let score = graceScore + (min(paceRatio, 1) * earnedRange)

        return (
            clamp(Int(score.rounded()), minimum: 0, maximum: 100),
            expectedProgress,
            paceRatio
        )
    }

    private func caloriesLoggingScore(_ calories: Int) -> Int {
        if calories >= config.nutrition.loggingBonus.highCaloriesThreshold {
            return config.nutrition.loggingBonus.highBonus
        }

        if calories >= config.nutrition.loggingBonus.mediumCaloriesThreshold {
            return config.nutrition.loggingBonus.mediumBonus
        }

        return 0
    }

    private func routineScore(
        isCompleted: Bool,
        window: GlowScoreConfig.RoutineWindow,
        evaluatedAt: Date
    ) -> Int {
        if isCompleted {
            return 100
        }

        let nowMinute = minuteOfDay(for: evaluatedAt)

        if nowMinute <= window.startMinuteOfDay {
            return 100
        }

        if nowMinute >= window.endMinuteOfDay {
            return 0
        }

        let progress = Double(nowMinute - window.startMinuteOfDay) /
            Double(window.endMinuteOfDay - window.startMinuteOfDay)
        let score = (1 - progress) * 100
        return clamp(Int(score.rounded()), minimum: 0, maximum: 100)
    }

    private func progressThroughDay(at date: Date) -> Double {
        let currentMinute = minuteOfDay(for: date)
        let checkpoints = config.progressCurve.checkpoints.sorted { $0.minuteOfDay < $1.minuteOfDay }

        guard let first = checkpoints.first, let last = checkpoints.last else {
            return 1.0
        }

        if currentMinute <= first.minuteOfDay {
            return first.progress
        }

        if currentMinute >= last.minuteOfDay {
            return last.progress
        }

        for index in 1..<checkpoints.count {
            let previous = checkpoints[index - 1]
            let next = checkpoints[index]

            if currentMinute <= next.minuteOfDay {
                let range = max(next.minuteOfDay - previous.minuteOfDay, 1)
                let offset = currentMinute - previous.minuteOfDay
                let ratio = Double(offset) / Double(range)
                return previous.progress + ((next.progress - previous.progress) * ratio)
            }
        }

        return last.progress
    }

    private func minuteOfDay(for date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return ((components.hour ?? 0) * 60) + (components.minute ?? 0)
    }

    private func formatHours(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    private func clamp(_ value: Int, minimum: Int, maximum: Int) -> Int {
        min(max(value, minimum), maximum)
    }

    private func orderedUnique(_ explanations: [String]) -> [String] {
        var seen: Set<String> = []
        var deduped: [String] = []

        for explanation in explanations where seen.insert(explanation).inserted {
            deduped.append(explanation)
        }

        return deduped
    }
}
