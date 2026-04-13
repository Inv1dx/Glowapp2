import Foundation

protocol GlowPlanGenerating {
    func generatePlan(from input: GlowPlanInput) -> GlowPlan
}

struct GlowPlanInput: Sendable {
    let day: Date
    let evaluatedAt: Date
    let userProfile: UserProfile?
    let metricsSnapshot: MetricsRepositorySnapshot
    let nutritionSummary: NutritionDaySummary
    let routineSummary: RoutineDaySummary
    let glowScore: GlowScore
}

struct GlowPlanEngine: GlowPlanGenerating {
    private enum RuleConstants {
        static let minimumActions = 3
        static let maximumActions = 5
        static let lowScoreThreshold = 78
        static let lowHydrationGapML = 400
        static let lowProteinGapGrams = 15
        static let lowStepsGap = 1_500
        static let morningRoutineCutoffHour = 12
        static let groomingCutoffHour = 21
        static let activityCutoffHour = 22
    }

    private struct Candidate {
        let kind: GlowPlanActionKind
        let title: String
        let detail: String?
        let rank: Int
        let isMaintenance: Bool
    }

    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func generatePlan(from input: GlowPlanInput) -> GlowPlan {
        let normalizedDay = calendar.startOfDay(for: input.day)
        let recoveryCandidates = buildRecoveryCandidates(from: input)
        var selectedCandidates = chooseCandidates(from: recoveryCandidates)

        if selectedCandidates.count < RuleConstants.minimumActions {
            let excludedKinds = Set(selectedCandidates.map(\.kind))
            let maintenanceCandidates = buildMaintenanceCandidates(
                from: input,
                excluding: excludedKinds
            )
            selectedCandidates.append(
                contentsOf: chooseCandidates(
                    from: maintenanceCandidates,
                    limit: RuleConstants.maximumActions - selectedCandidates.count
                )
            )
        }

        if selectedCandidates.count < RuleConstants.minimumActions {
            let excludedKinds = Set(selectedCandidates.map(\.kind))
            let fallbackCandidates = buildFallbackCandidates(
                from: input,
                excluding: excludedKinds
            )
            selectedCandidates.append(
                contentsOf: chooseCandidates(
                    from: fallbackCandidates,
                    limit: RuleConstants.minimumActions - selectedCandidates.count
                )
            )
        }

        let actions = selectedCandidates
            .prefix(RuleConstants.maximumActions)
            .enumerated()
            .map { index, candidate in
                GlowPlanAction(
                    kind: candidate.kind,
                    title: candidate.title,
                    detail: candidate.detail,
                    priority: index + 1,
                    isCompleted: false
                )
            }

        let mode: GlowPlanMode = actions.allSatisfy { action in
            switch action.kind {
            case .maintainSleep, .maintainActivity, .maintainProtein, .maintainHydration:
                true
            default:
                false
            }
        } ? .maintenance : .focused

        return GlowPlan(
            date: normalizedDay,
            generatedAt: input.evaluatedAt,
            mode: mode,
            actions: actions
        )
    }

    private func buildRecoveryCandidates(from input: GlowPlanInput) -> [Candidate] {
        var candidates: [Candidate] = []

        if let candidate = sleepCandidate(from: input) {
            candidates.append(candidate)
        }

        if let candidate = activityCandidate(from: input) {
            candidates.append(candidate)
        }

        if let candidate = nutritionCandidate(from: input) {
            candidates.append(candidate)
        }

        if let candidate = hydrationCandidate(from: input) {
            candidates.append(candidate)
        }

        if let candidate = routineCandidate(from: input) {
            candidates.append(candidate)
        }

        return candidates.sorted { lhs, rhs in
            if lhs.rank == rhs.rank {
                return lhs.kind.rawValue < rhs.kind.rawValue
            }

            return lhs.rank > rhs.rank
        }
    }

    private func buildMaintenanceCandidates(
        from input: GlowPlanInput,
        excluding excludedKinds: Set<GlowPlanActionKind>
    ) -> [Candidate] {
        let targetSleep = input.userProfile?.targetSleepHours ?? UserProfile.defaultSleepHours
        let sleepTitle = "Protect your \(formatHours(targetSleep)) hr sleep tonight"

        let candidates = [
            Candidate(
                kind: .maintainSleep,
                title: sleepTitle,
                detail: "Sleep is holding up. Keep tonight clean and on target.",
                rank: maintenanceRank(for: .sleep, input: input),
                isMaintenance: true
            ),
            Candidate(
                kind: .maintainActivity,
                title: "Keep your step pace moving",
                detail: "Activity is in a decent spot. Do not flatten out now.",
                rank: maintenanceRank(for: .activity, input: input),
                isMaintenance: true
            ),
            Candidate(
                kind: .maintainProtein,
                title: "Keep your next meal protein-first",
                detail: "Nutrition is steady. Keep the next meal useful.",
                rank: maintenanceRank(for: .nutrition, input: input),
                isMaintenance: true
            ),
            Candidate(
                kind: .maintainHydration,
                title: "Keep water near you tonight",
                detail: "Hydration is on track. Keep sipping so it stays there.",
                rank: maintenanceRank(for: .hydration, input: input),
                isMaintenance: true
            )
        ]

        return candidates
            .filter { !excludedKinds.contains($0.kind) }
            .sorted { lhs, rhs in
                if lhs.rank == rhs.rank {
                    return lhs.kind.rawValue < rhs.kind.rawValue
                }

                return lhs.rank > rhs.rank
            }
    }

    private func buildFallbackCandidates(
        from input: GlowPlanInput,
        excluding excludedKinds: Set<GlowPlanActionKind>
    ) -> [Candidate] {
        buildMaintenanceCandidates(from: input, excluding: excludedKinds)
    }

    private func sleepCandidate(from input: GlowPlanInput) -> Candidate? {
        guard let breakdown = breakdown(for: .sleep, in: input.glowScore) else {
            return nil
        }

        let targetSleep = input.userProfile?.targetSleepHours ?? UserProfile.defaultSleepHours
        let sleepHours = input.metricsSnapshot.metrics?.sleepDurationHours
        let sleepDeficit = max(0, targetSleep - (sleepHours ?? targetSleep))
        let sleepScore = breakdown.score ?? 100

        guard sleepScore < RuleConstants.lowScoreThreshold || sleepDeficit >= 0.5 else {
            return nil
        }

        let detail: String
        if let sleepHours {
            detail = "\(formatHours(sleepHours)) hr last night vs \(formatHours(targetSleep)) hr target."
        } else {
            detail = "Sleep came in soft, so tonight matters more."
        }

        return Candidate(
            kind: .sleepWindDown,
            title: "Start winding down for \(formatHours(targetSleep)) hr tonight",
            detail: detail,
            rank: recoveryRank(
                category: .sleep,
                score: sleepScore,
                bonus: Int((sleepDeficit * 20).rounded()),
                input: input
            ),
            isMaintenance: false
        )
    }

    private func activityCandidate(from input: GlowPlanInput) -> Candidate? {
        guard currentHour(for: input.evaluatedAt) < RuleConstants.activityCutoffHour else {
            return nil
        }

        guard let breakdown = breakdown(for: .activity, in: input.glowScore) else {
            return nil
        }

        let targetSteps = input.userProfile?.targetDailySteps ?? UserProfile.defaultDailySteps
        let currentSteps = input.metricsSnapshot.metrics?.steps
        let remainingSteps = max(0, targetSteps - (currentSteps ?? 0))
        let activityScore = breakdown.score ?? 100

        guard activityScore < RuleConstants.lowScoreThreshold || remainingSteps >= RuleConstants.lowStepsGap else {
            return nil
        }

        let title: String
        if remainingSteps >= 3_500 {
            title = "Take a 30-minute walk today"
        } else if remainingSteps >= 1_500 {
            title = "Get \(roundedSteps(remainingSteps).formatted()) more steps today"
        } else {
            title = "Close out your step target"
        }

        let detail: String
        if let currentSteps {
            detail = "\(currentSteps.formatted()) / \(targetSteps.formatted()) steps so far."
        } else {
            detail = "Activity is soft today. One walk still helps."
        }

        return Candidate(
            kind: .activityWalk,
            title: title,
            detail: detail,
            rank: recoveryRank(
                category: .activity,
                score: activityScore,
                bonus: min(remainingSteps / 250, 20),
                input: input
            ),
            isMaintenance: false
        )
    }

    private func nutritionCandidate(from input: GlowPlanInput) -> Candidate? {
        guard let breakdown = breakdown(for: .nutrition, in: input.glowScore) else {
            return nil
        }

        let targetProtein = input.userProfile?.targetProteinGrams ?? UserProfile.defaultProteinGrams
        let currentProtein = input.nutritionSummary.totalProteinGrams
        let proteinGap = max(0, targetProtein - currentProtein)
        let nutritionScore = breakdown.score ?? 100

        guard nutritionScore < RuleConstants.lowScoreThreshold || proteinGap >= RuleConstants.lowProteinGapGrams else {
            return nil
        }

        let title: String
        if proteinGap >= 35 {
            title = "Make your next meal protein-first"
        } else {
            title = "Get \(roundedProtein(proteinGap).formatted()) g more protein today"
        }

        let detail = "\(currentProtein.formatted()) / \(targetProtein.formatted()) g protein so far."

        return Candidate(
            kind: .proteinGoal,
            title: title,
            detail: detail,
            rank: recoveryRank(
                category: .nutrition,
                score: nutritionScore,
                bonus: min(proteinGap, 25),
                input: input
            ),
            isMaintenance: false
        )
    }

    private func hydrationCandidate(from input: GlowPlanInput) -> Candidate? {
        guard let breakdown = breakdown(for: .hydration, in: input.glowScore) else {
            return nil
        }

        let targetWater = input.userProfile?.targetWaterML ?? UserProfile.defaultWaterML
        let currentWater = input.nutritionSummary.totalWaterML
        let waterGap = max(0, targetWater - currentWater)
        let hydrationScore = breakdown.score ?? 100

        guard hydrationScore < RuleConstants.lowScoreThreshold || waterGap >= RuleConstants.lowHydrationGapML else {
            return nil
        }

        let title: String
        if waterGap >= 1_000 {
            title = "Get 1 L more water in today"
        } else if waterGap >= 600 {
            title = "Get 750 mL more water in today"
        } else {
            title = "Drink 500 mL more water today"
        }

        let detail = "\(currentWater.formatted()) / \(targetWater.formatted()) mL water so far."

        return Candidate(
            kind: .hydrationGoal,
            title: title,
            detail: detail,
            rank: recoveryRank(
                category: .hydration,
                score: hydrationScore,
                bonus: min(waterGap / 75, 25),
                input: input
            ),
            isMaintenance: false
        )
    }

    private func routineCandidate(from input: GlowPlanInput) -> Candidate? {
        guard let breakdown = breakdown(for: .routineConsistency, in: input.glowScore) else {
            return nil
        }

        let hour = currentHour(for: input.evaluatedAt)
        let amStatus = input.routineSummary.status(for: .am)
        let pmStatus = input.routineSummary.status(for: .pm)
        let groomingStatus = input.routineSummary.status(for: .grooming)

        if !pmStatus.isCompleted {
            return Candidate(
                kind: .eveningRoutine,
                title: "Complete PM skincare tonight",
                detail: "Your night routine is still open today.",
                rank: recoveryRank(
                    category: .routineConsistency,
                    score: breakdown.score ?? 100,
                    bonus: hour >= 17 ? 18 : 12,
                    input: input
                ),
                isMaintenance: false
            )
        }

        if !amStatus.isCompleted && hour < RuleConstants.morningRoutineCutoffHour {
            return Candidate(
                kind: .morningRoutine,
                title: "Finish your AM routine",
                detail: "Lock in the morning basics before midday.",
                rank: recoveryRank(
                    category: .routineConsistency,
                    score: breakdown.score ?? 100,
                    bonus: 14,
                    input: input
                ),
                isMaintenance: false
            )
        }

        if !groomingStatus.isCompleted && hour < RuleConstants.groomingCutoffHour {
            return Candidate(
                kind: .groomingReset,
                title: "Do your grooming reset today",
                detail: "Appearance upkeep is still open today.",
                rank: recoveryRank(
                    category: .routineConsistency,
                    score: breakdown.score ?? 100,
                    bonus: 10,
                    input: input
                ),
                isMaintenance: false
            )
        }

        return nil
    }

    private func chooseCandidates(from candidates: [Candidate], limit: Int = RuleConstants.maximumActions) -> [Candidate] {
        guard limit > 0 else {
            return []
        }

        var selectedKinds: Set<GlowPlanActionKind> = []
        var selection: [Candidate] = []

        for candidate in candidates {
            guard !selectedKinds.contains(candidate.kind) else {
                continue
            }

            selection.append(candidate)
            selectedKinds.insert(candidate.kind)

            if selection.count == limit {
                break
            }
        }

        return selection
    }

    private func recoveryRank(
        category: GlowScoreCategory,
        score: Int,
        bonus: Int,
        input: GlowPlanInput
    ) -> Int {
        (100 - score) + categoryWeight(for: category, input: input) + bonus
    }

    private func maintenanceRank(
        for category: GlowScoreCategory,
        input: GlowPlanInput
    ) -> Int {
        let score = breakdown(for: category, in: input.glowScore)?.score ?? 80
        return categoryWeight(for: category, input: input) + max(score - 60, 0)
    }

    private func categoryWeight(for category: GlowScoreCategory, input: GlowPlanInput) -> Int {
        breakdown(for: category, in: input.glowScore)?.weight ?? 0
    }

    private func breakdown(
        for category: GlowScoreCategory,
        in score: GlowScore
    ) -> GlowScoreCategoryBreakdown? {
        score.breakdowns.first { $0.category == category }
    }

    private func currentHour(for date: Date) -> Int {
        calendar.component(.hour, from: date)
    }

    private func roundedSteps(_ steps: Int) -> Int {
        max(1_000, ((steps + 250) / 500) * 500)
    }

    private func roundedProtein(_ grams: Int) -> Int {
        max(10, ((grams + 2) / 5) * 5)
    }

    private func formatHours(_ hours: Double) -> String {
        hours.formatted(.number.precision(.fractionLength(1)))
    }
}
