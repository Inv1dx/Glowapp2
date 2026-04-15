import Foundation

final class SupabaseMetricsRepository: MetricsRepository {
    private let supabaseService: any SupabaseService
    private let localRepository: LocalMetricsRepository
    private let authService: any AuthService
    private let calendar: Calendar

    init(
        supabaseService: any SupabaseService,
        localRepository: LocalMetricsRepository,
        authService: any AuthService,
        calendar: Calendar = .current
    ) {
        self.supabaseService = supabaseService
        self.localRepository = localRepository
        self.authService = authService
        self.calendar = calendar
    }

    func loadCurrentDaySnapshot() async -> MetricsRepositorySnapshot {
        if let snapshot = await loadRemoteSnapshot(for: Date()) {
            localRepository.cacheRemoteSnapshot(snapshot)
            return snapshot
        }

        let snapshot = await localRepository.loadCurrentDaySnapshot()
        await persistIfNeeded(snapshot)
        return snapshot
    }

    func refreshCurrentDaySnapshot() async -> MetricsRepositorySnapshot {
        let snapshot = await localRepository.refreshCurrentDaySnapshot()
        await persistIfNeeded(snapshot)
        return snapshot
    }

    func requestHealthAccess() async -> MetricsRepositorySnapshot {
        let snapshot = await localRepository.requestHealthAccess()
        await persistIfNeeded(snapshot)
        return snapshot
    }

    private func loadRemoteSnapshot(for date: Date) async -> MetricsRepositorySnapshot? {
        do {
            let records = try await supabaseService.select(
                SupabaseDailyMetricsRecord.self,
                from: .dailyMetrics,
                filters: [
                    SupabaseRepositorySupport.userFilter(authService.currentUserId),
                    SupabaseRepositorySupport.dateFilter(date, calendar: calendar)
                ],
                order: [],
                limit: 1
            )

            return try records.first?.makeSnapshot(calendar: calendar)
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "load daily metrics")
            return nil
        }
    }

    private func persistIfNeeded(_ snapshot: MetricsRepositorySnapshot) async {
        guard snapshot.metrics != nil else {
            return
        }

        do {
            try await supabaseService.upsert(
                SupabaseDailyMetricsRecord(
                    userId: authService.currentUserId,
                    snapshot: snapshot,
                    calendar: calendar
                ),
                into: .dailyMetrics,
                onConflict: ["user_id", "date"]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "save daily metrics")
        }
    }
}
