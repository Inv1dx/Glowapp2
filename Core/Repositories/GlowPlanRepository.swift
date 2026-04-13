import Combine
import Foundation

protocol GlowPlanRepository: AnyObject {
    var updates: AnyPublisher<Void, Never> { get }

    func loadPlan(for date: Date) async -> GlowPlan?
    func savePlan(_ plan: GlowPlan) async
    func setActionCompleted(
        _ isCompleted: Bool,
        for kind: GlowPlanActionKind,
        on date: Date
    ) async
}

final class LocalGlowPlanRepository: GlowPlanRepository {
    private enum StorageKey {
        static let plans = "glow.plan.dailyPlans"
    }

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let calendar: Calendar
    private let updatesSubject = PassthroughSubject<Void, Never>()

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        calendar: Calendar = .current
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.calendar = calendar
    }

    var updates: AnyPublisher<Void, Never> {
        updatesSubject.eraseToAnyPublisher()
    }

    func loadPlan(for date: Date) async -> GlowPlan? {
        let normalizedDate = calendar.startOfDay(for: date)

        return loadAllPlans().first {
            DayBoundaryFactory.isSameDay($0.date, normalizedDate, calendar: calendar)
        }
    }

    func savePlan(_ plan: GlowPlan) async {
        let normalizedPlan = GlowPlan(
            id: plan.id,
            date: calendar.startOfDay(for: plan.date),
            generatedAt: plan.generatedAt,
            mode: plan.mode,
            actions: plan.actions.sorted { $0.priority < $1.priority }
        )

        var plans = loadAllPlans().filter {
            !DayBoundaryFactory.isSameDay($0.date, normalizedPlan.date, calendar: calendar)
        }
        plans.append(normalizedPlan)
        plans.sort { $0.date > $1.date }
        persist(plans)
        updatesSubject.send()
    }

    func setActionCompleted(
        _ isCompleted: Bool,
        for kind: GlowPlanActionKind,
        on date: Date
    ) async {
        let normalizedDate = calendar.startOfDay(for: date)
        var plans = loadAllPlans()

        guard let planIndex = plans.firstIndex(where: {
            DayBoundaryFactory.isSameDay($0.date, normalizedDate, calendar: calendar)
        }) else {
            return
        }

        guard let actionIndex = plans[planIndex].actions.firstIndex(where: { $0.kind == kind }) else {
            return
        }

        plans[planIndex].actions[actionIndex].isCompleted = isCompleted
        plans[planIndex].actions.sort { $0.priority < $1.priority }

        persist(plans)
        updatesSubject.send()
    }

    private func loadAllPlans() -> [GlowPlan] {
        guard
            let data = userDefaults.data(forKey: StorageKey.plans),
            let plans = try? decoder.decode([GlowPlan].self, from: data)
        else {
            return []
        }

        return plans
    }

    private func persist(_ plans: [GlowPlan]) {
        guard let data = try? encoder.encode(plans) else {
            return
        }

        userDefaults.set(data, forKey: StorageKey.plans)
    }
}
