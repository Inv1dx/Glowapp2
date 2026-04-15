import Combine
import Foundation

final class SupabaseRoutineRepository: RoutineRepository {
    private let supabaseService: any SupabaseService
    private let localRepository: LocalRoutineRepository
    private let authService: any AuthService
    private let calendar: Calendar

    init(
        supabaseService: any SupabaseService,
        localRepository: LocalRoutineRepository,
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

    func loadSummary(for date: Date) async -> RoutineDaySummary {
        do {
            let entries = try await loadRemoteEntries()
            localRepository.cacheRemoteEntries(entries)
            return makeSummary(for: date, entries: entries)
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "load routine entries")
            return await localRepository.loadSummary(for: date)
        }
    }

    func setCompleted(
        _ isCompleted: Bool,
        for template: RoutineTemplate,
        on date: Date
    ) async {
        if isCompleted {
            await upsertCompletedEntry(for: template, on: date)
        } else {
            await deleteCompletedEntry(for: template, on: date)
        }

        await localRepository.setCompleted(isCompleted, for: template, on: date)
    }

    private func loadRemoteEntries() async throws -> [RoutineEntry] {
        let records = try await supabaseService.select(
            SupabaseRoutineEntryRecord.self,
            from: .routineEntries,
            filters: [SupabaseRepositorySupport.userFilter(authService.currentUserId)],
            order: [.descending("date")],
            limit: nil
        )

        return try records.map { try $0.makeEntry(calendar: calendar) }
    }

    private func upsertCompletedEntry(
        for template: RoutineTemplate,
        on date: Date
    ) async {
        let normalizedDate = calendar.startOfDay(for: date)
        let existingID = await remoteEntryID(for: template, on: normalizedDate)

        let entry = RoutineEntry(
            id: existingID ?? UUID(),
            template: template,
            day: normalizedDate,
            completedAt: date
        )

        do {
            try await supabaseService.upsert(
                SupabaseRoutineEntryRecord(
                    userId: authService.currentUserId,
                    entry: entry,
                    calendar: calendar
                ),
                into: .routineEntries,
                onConflict: ["user_id", "date", "template"]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "save routine entry")
        }
    }

    private func deleteCompletedEntry(
        for template: RoutineTemplate,
        on date: Date
    ) async {
        do {
            try await supabaseService.delete(
                from: .routineEntries,
                filters: [
                    SupabaseRepositorySupport.userFilter(authService.currentUserId),
                    SupabaseRepositorySupport.dateFilter(date, calendar: calendar),
                    .equal("template", template.rawValue)
                ]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "delete routine entry")
        }
    }

    private func remoteEntryID(
        for template: RoutineTemplate,
        on date: Date
    ) async -> UUID? {
        do {
            let records = try await supabaseService.select(
                SupabaseRoutineEntryRecord.self,
                from: .routineEntries,
                filters: [
                    SupabaseRepositorySupport.userFilter(authService.currentUserId),
                    SupabaseRepositorySupport.dateFilter(date, calendar: calendar),
                    .equal("template", template.rawValue)
                ],
                order: [],
                limit: 1
            )

            return records.first?.id
        } catch {
            return nil
        }
    }

    private func makeSummary(
        for date: Date,
        entries: [RoutineEntry]
    ) -> RoutineDaySummary {
        let normalizedDate = calendar.startOfDay(for: date)
        let statuses = RoutineTemplate.allCases.map { template in
            RoutineDaySummary.Status(
                template: template,
                isCompleted: entries.contains {
                    $0.template == template &&
                    DayBoundaryFactory.isSameDay($0.day, normalizedDate, calendar: calendar)
                },
                streakCount: streakCount(
                    for: template,
                    through: normalizedDate,
                    entries: entries
                )
            )
        }

        return RoutineDaySummary(date: normalizedDate, statuses: statuses)
    }

    private func streakCount(
        for template: RoutineTemplate,
        through date: Date,
        entries: [RoutineEntry]
    ) -> Int {
        let completedDays = Set(
            entries
                .filter { $0.template == template }
                .map { calendar.startOfDay(for: $0.day) }
        )

        var streak = 0
        var currentDay = calendar.startOfDay(for: date)

        while completedDays.contains(currentDay) {
            streak += 1

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
                break
            }

            currentDay = previousDay
        }

        return streak
    }
}
