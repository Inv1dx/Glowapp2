import Foundation

@MainActor
final class GlowScoreViewModel: ObservableObject {
    private let userRepository: any UserRepository
    private let glowRepository: any GlowRepository
    private let engine: GlowScoreEngine
    private let calendar: Calendar

    @Published private(set) var score: GlowScore?
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoadedOnce = false

    init(
        userRepository: any UserRepository,
        glowRepository: any GlowRepository,
        engine: GlowScoreEngine = GlowScoreEngine(),
        calendar: Calendar = .current
    ) {
        self.userRepository = userRepository
        self.glowRepository = glowRepository
        self.engine = engine
        self.calendar = calendar
    }

    var title: String {
        "Today's Glow Score"
    }

    var subtitle: String {
        "A deterministic score built from today's available inputs."
    }

    var availabilityText: String {
        guard let score else {
            return "Waiting for today's score."
        }

        return "\(score.availableCategoriesCount.formatted()) of \(GlowScoreCategory.allCases.count.formatted()) categories available"
    }

    func loadStoredScore(for date: Date = Date()) async {
        score = await glowRepository.loadScore(for: date)
    }

    func refresh(
        metricsSnapshot: MetricsRepositorySnapshot,
        nutritionSummary: NutritionDaySummary,
        routineSummary: RoutineDaySummary,
        evaluatedAt: Date = Date()
    ) async {
        isLoading = true

        let userProfile = (try? await userRepository.loadUserProfile()) ?? nil
        let input = makeInput(
            metricsSnapshot: metricsSnapshot,
            nutritionSummary: nutritionSummary,
            routineSummary: routineSummary,
            userProfile: userProfile,
            evaluatedAt: evaluatedAt
        )
        let score = engine.evaluate(input)

        await glowRepository.upsertScore(score)

        self.score = score
        hasLoadedOnce = true
        isLoading = false
    }

    private func makeInput(
        metricsSnapshot: MetricsRepositorySnapshot,
        nutritionSummary: NutritionDaySummary,
        routineSummary: RoutineDaySummary,
        userProfile: UserProfile?,
        evaluatedAt: Date
    ) -> GlowScoreInput {
        let metrics = metricsSnapshot.metrics

        return GlowScoreInput(
            day: calendar.startOfDay(for: evaluatedAt),
            evaluatedAt: evaluatedAt,
            userProfile: userProfile,
            sleepHours: healthMeasurement(
                field: .sleepDurationHours,
                value: metrics?.sleepDurationHours,
                snapshot: metricsSnapshot
            ),
            steps: healthMeasurement(
                field: .steps,
                value: metrics?.steps,
                snapshot: metricsSnapshot
            ),
            activeCalories: healthMeasurement(
                field: .activeCalories,
                value: metrics?.activeCalories,
                snapshot: metricsSnapshot
            ),
            caloriesIn: .available(nutritionSummary.totalCalories),
            proteinGrams: .available(nutritionSummary.totalProteinGrams),
            waterML: .available(nutritionSummary.totalWaterML),
            amRoutineCompleted: .available(routineSummary.status(for: .am).isCompleted),
            pmRoutineCompleted: .available(routineSummary.status(for: .pm).isCompleted),
            groomingCompleted: .available(routineSummary.status(for: .grooming).isCompleted)
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
            return .unavailable(snapshot.connectionState == .unavailable ? .appleHealthUnavailable : .accessLimited)
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
}
