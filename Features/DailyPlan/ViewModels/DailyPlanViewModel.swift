import Combine
import Foundation

@MainActor
final class DailyPlanViewModel: ObservableObject {
    private let userRepository: any UserRepository
    private let planRepository: any GlowPlanRepository
    private let engine: any GlowPlanGenerating
    private let calendar: Calendar
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var plan: GlowPlan?
    @Published private(set) var hasLoadedOnce = false
    @Published private(set) var isLoading = false

    init(
        userRepository: any UserRepository,
        planRepository: any GlowPlanRepository,
        engine: any GlowPlanGenerating = GlowPlanEngine(),
        calendar: Calendar = .current
    ) {
        self.userRepository = userRepository
        self.planRepository = planRepository
        self.engine = engine
        self.calendar = calendar

        planRepository.updates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task {
                    await self?.loadStoredPlan()
                }
            }
            .store(in: &cancellables)
    }

    var title: String {
        "Today's Glow Plan"
    }

    var subtitle: String {
        switch plan?.mode {
        case .maintenance:
            "Your metrics are holding up. Keep the basics tight."
        case .focused:
            "A short plan built from the weakest parts of today."
        case .none:
            "Today’s plan appears after the dashboard finishes loading."
        }
    }

    var completionText: String? {
        guard let plan else {
            return nil
        }

        let completedCount = plan.actions.filter(\.isCompleted).count
        return "\(completedCount.formatted()) of \(plan.actions.count.formatted()) done"
    }

    func loadStoredPlan(for date: Date = Date()) async {
        plan = await planRepository.loadPlan(for: date)
        hasLoadedOnce = true
    }

    func refreshIfNeeded(
        metricsSnapshot: MetricsRepositorySnapshot,
        nutritionSummary: NutritionDaySummary,
        routineSummary: RoutineDaySummary,
        glowScore: GlowScore,
        evaluatedAt: Date = Date()
    ) async {
        let normalizedDate = calendar.startOfDay(for: evaluatedAt)

        if let plan, DayBoundaryFactory.isSameDay(plan.date, normalizedDate, calendar: calendar) {
            hasLoadedOnce = true
            return
        }

        guard !isLoading else {
            return
        }

        isLoading = true

        if let storedPlan = await planRepository.loadPlan(for: normalizedDate) {
            plan = storedPlan
            hasLoadedOnce = true
            isLoading = false
            return
        }

        let userProfile = (try? await userRepository.loadUserProfile()) ?? nil
        let input = GlowPlanInput(
            day: normalizedDate,
            evaluatedAt: evaluatedAt,
            userProfile: userProfile,
            metricsSnapshot: metricsSnapshot,
            nutritionSummary: nutritionSummary,
            routineSummary: routineSummary,
            glowScore: glowScore
        )
        let generatedPlan = engine.generatePlan(from: input)

        await planRepository.savePlan(generatedPlan)

        plan = generatedPlan
        hasLoadedOnce = true
        isLoading = false
    }

    func toggleCompletion(for action: GlowPlanAction) {
        guard let plan else {
            return
        }

        Task {
            await planRepository.setActionCompleted(
                !action.isCompleted,
                for: action.kind,
                on: plan.date
            )
        }
    }
}
