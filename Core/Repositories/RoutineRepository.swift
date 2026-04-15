import Combine
import Foundation

protocol RoutineRepository: AnyObject {
    var updates: AnyPublisher<Void, Never> { get }

    func loadSummary(for date: Date) async -> RoutineDaySummary
    func setCompleted(
        _ isCompleted: Bool,
        for template: RoutineTemplate,
        on date: Date
    ) async
}

final class LocalRoutineRepository: RoutineRepository {
    private enum StorageKey {
        static let entries = "glow.routines.entries"
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

    func loadSummary(for date: Date) async -> RoutineDaySummary {
        let normalizedDate = calendar.startOfDay(for: date)
        let entries = loadAllEntries()

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

    func setCompleted(
        _ isCompleted: Bool,
        for template: RoutineTemplate,
        on date: Date
    ) async {
        let normalizedDate = calendar.startOfDay(for: date)
        var entries = loadAllEntries().filter {
            !($0.template == template &&
            DayBoundaryFactory.isSameDay($0.day, normalizedDate, calendar: calendar))
        }

        if isCompleted {
            entries.append(
                RoutineEntry(
                    template: template,
                    day: normalizedDate,
                    completedAt: date
                )
            )
        }

        persist(entries)
        updatesSubject.send()
    }

    func cacheRemoteEntries(_ entries: [RoutineEntry]) {
        persist(entries)
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

            guard
                let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay)
            else {
                break
            }

            currentDay = previousDay
        }

        return streak
    }

    private func loadAllEntries() -> [RoutineEntry] {
        guard
            let data = userDefaults.data(forKey: StorageKey.entries),
            let entries = try? decoder.decode([RoutineEntry].self, from: data)
        else {
            return []
        }

        return entries
    }

    private func persist(_ entries: [RoutineEntry]) {
        guard let data = try? encoder.encode(entries) else {
            return
        }

        userDefaults.set(data, forKey: StorageKey.entries)
    }
}
