import Combine
import Foundation

final class SupabaseGlowPlanRepository: GlowPlanRepository {
    private let supabaseService: any SupabaseService
    private let localRepository: LocalGlowPlanRepository
    private let authService: any AuthService
    private let calendar: Calendar

    init(
        supabaseService: any SupabaseService,
        localRepository: LocalGlowPlanRepository,
        authService: any AuthService,
        calendar: Calendar = .current
    ) {
        self.supabaseService = supabaseService
        self.localRepository = localRepository
        self.authService = authService
        self.calendar = calendar
    }

    var updates: AnyPublisher<Void, Never> {
        localRepository.updates
    }

    func loadPlan(for date: Date) async -> GlowPlan? {
        do {
            let records = try await supabaseService.select(
                SupabaseGlowPlanRecord.self,
                from: .glowPlans,
                filters: [
                    SupabaseRepositorySupport.userFilter(authService.currentUserId),
                    SupabaseRepositorySupport.dateFilter(date, calendar: calendar)
                ],
                order: [],
                limit: 1
            )

            guard let plan = try records.first?.makePlan(calendar: calendar) else {
                return await localRepository.loadPlan(for: date)
            }

            localRepository.cacheRemotePlan(plan)
            return plan
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "load glow plan")
            return await localRepository.loadPlan(for: date)
        }
    }

    func savePlan(_ plan: GlowPlan) async {
        do {
            try await supabaseService.upsert(
                SupabaseGlowPlanRecord(
                    userId: authService.currentUserId,
                    plan: plan,
                    calendar: calendar
                ),
                into: .glowPlans,
                onConflict: ["user_id", "date"]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "save glow plan")
        }

        await localRepository.savePlan(plan)
    }

    func setActionCompleted(
        _ isCompleted: Bool,
        for kind: GlowPlanActionKind,
        on date: Date
    ) async {
        guard var plan = await loadPlan(for: date),
              let actionIndex = plan.actions.firstIndex(where: { $0.kind == kind })
        else {
            return
        }

        plan.actions[actionIndex].isCompleted = isCompleted
        plan.actions.sort { $0.priority < $1.priority }
        await savePlan(plan)
    }
}
