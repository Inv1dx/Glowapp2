import Combine
import Foundation

final class SupabaseNutritionRepository: NutritionRepository {
    private let supabaseService: any SupabaseService
    private let localRepository: LocalNutritionRepository
    private let authService: any AuthService
    private let calendar: Calendar

    init(
        supabaseService: any SupabaseService,
        localRepository: LocalNutritionRepository,
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

    func loadEntries(for date: Date) async -> [NutritionLog] {
        do {
            let records = try await supabaseService.select(
                SupabaseNutritionLogRecord.self,
                from: .nutritionLogs,
                filters: [
                    SupabaseRepositorySupport.userFilter(authService.currentUserId),
                    SupabaseRepositorySupport.dateFilter(date, calendar: calendar)
                ],
                order: [.descending("logged_at")],
                limit: nil
            )
            let logs = try records.map { try $0.makeLog() }
            localRepository.cacheRemoteLogs(logs, for: date)
            return logs.sorted { $0.loggedAt > $1.loggedAt }
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "load nutrition logs")
            return await localRepository.loadEntries(for: date)
        }
    }

    func loadSummary(for date: Date) async -> NutritionDaySummary {
        let logs = await loadEntries(for: date)

        return NutritionDaySummary(
            date: calendar.startOfDay(for: date),
            totalCalories: logs.reduce(0) { $0 + $1.calories },
            totalProteinGrams: logs.reduce(0) { $0 + $1.proteinGrams },
            totalWaterML: logs.reduce(0) { $0 + $1.waterML }
        )
    }

    func saveLog(_ log: NutritionLog) async throws {
        guard isValid(log) else {
            throw NutritionRepositoryError.invalidLog
        }

        do {
            try await supabaseService.upsert(
                SupabaseNutritionLogRecord(
                    userId: authService.currentUserId,
                    log: log,
                    calendar: calendar
                ),
                into: .nutritionLogs,
                onConflict: ["id"]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "save nutrition log")
        }

        try await localRepository.saveLog(log)
    }

    func deleteLog(id: UUID) async {
        do {
            try await supabaseService.delete(
                from: .nutritionLogs,
                filters: [
                    SupabaseRepositorySupport.userFilter(authService.currentUserId),
                    .equal("id", id.uuidString.lowercased())
                ]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "delete nutrition log")
        }

        await localRepository.deleteLog(id: id)
    }

    private func isValid(_ log: NutritionLog) -> Bool {
        guard log.calories >= 0, log.proteinGrams >= 0, log.waterML >= 0 else {
            return false
        }

        return log.calories > 0 || log.proteinGrams > 0 || log.waterML > 0
    }
}
