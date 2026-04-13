import Foundation

@MainActor
final class RecapViewModel: ObservableObject {
    private let userRepository: any UserRepository
    private let engine: RecapEngine
    private let calendar: Calendar
    private let headerFormatter: DateFormatter

    @Published private(set) var recap: DailyRecap?
    @Published private(set) var hasLoadedOnce = false
    @Published private(set) var isLoading = false

    init(
        userRepository: any UserRepository,
        engine: RecapEngine = RecapEngine(),
        calendar: Calendar = .current
    ) {
        self.userRepository = userRepository
        self.engine = engine
        self.calendar = calendar

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "EEEE, MMM d"
        self.headerFormatter = formatter
    }

    var navigationTitle: String {
        "Recap"
    }

    var title: String {
        "End-of-day recap"
    }

    var entryTitle: String {
        "End-of-day recap"
    }

    var entrySubtitle: String {
        recap?.summaryMessage ?? "Close the day with one clear summary and tomorrow's next move."
    }

    var entryDetail: String {
        recap?.recommendationText ?? "See today's calories, routines, Glow Score, and one practical recommendation."
    }

    func formattedDate(for date: Date) -> String {
        headerFormatter.string(from: calendar.startOfDay(for: date))
    }

    func refresh(
        metricsSnapshot: MetricsRepositorySnapshot,
        nutritionSummary: NutritionDaySummary,
        routineSummary: RoutineDaySummary,
        glowScore: GlowScore?,
        evaluatedAt: Date = Date()
    ) async {
        guard !isLoading else {
            return
        }

        isLoading = true

        let userProfile = (try? await userRepository.loadUserProfile()) ?? nil
        recap = engine.generateRecap(
            from: DailyRecapInput(
                day: evaluatedAt,
                evaluatedAt: evaluatedAt,
                userProfile: userProfile,
                metricsSnapshot: metricsSnapshot,
                nutritionSummary: nutritionSummary,
                routineSummary: routineSummary,
                glowScore: glowScore
            )
        )

        hasLoadedOnce = true
        isLoading = false
    }
}
