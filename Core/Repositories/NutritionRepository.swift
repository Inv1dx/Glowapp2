import Combine
import Foundation

enum NutritionRepositoryError: Error, Equatable {
    case invalidLog
}

protocol NutritionRepository: AnyObject {
    var updates: AnyPublisher<Void, Never> { get }

    func loadEntries(for date: Date) async -> [NutritionLog]
    func loadSummary(for date: Date) async -> NutritionDaySummary
    func saveLog(_ log: NutritionLog) async throws
    func deleteLog(id: UUID) async
}

final class LocalNutritionRepository: NutritionRepository {
    private enum StorageKey {
        static let logs = "glow.nutrition.logs"
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

    func loadEntries(for date: Date) async -> [NutritionLog] {
        loadAllLogs()
            .filter { DayBoundaryFactory.isSameDay($0.loggedAt, date, calendar: calendar) }
            .sorted { $0.loggedAt > $1.loggedAt }
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

        var logs = loadAllLogs()

        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = log
        } else {
            logs.append(log)
        }

        persist(logs)
        updatesSubject.send()
    }

    func deleteLog(id: UUID) async {
        let originalLogs = loadAllLogs()
        let filteredLogs = originalLogs.filter { $0.id != id }

        guard filteredLogs.count != originalLogs.count else {
            return
        }

        persist(filteredLogs)
        updatesSubject.send()
    }

    func cacheRemoteLogs(_ logs: [NutritionLog], for date: Date) {
        var cachedLogs = loadAllLogs().filter {
            !DayBoundaryFactory.isSameDay($0.loggedAt, date, calendar: calendar)
        }
        cachedLogs.append(contentsOf: logs)
        persist(cachedLogs)
    }

    private func isValid(_ log: NutritionLog) -> Bool {
        guard log.calories >= 0, log.proteinGrams >= 0, log.waterML >= 0 else {
            return false
        }

        return log.calories > 0 || log.proteinGrams > 0 || log.waterML > 0
    }

    private func loadAllLogs() -> [NutritionLog] {
        guard
            let data = userDefaults.data(forKey: StorageKey.logs),
            let logs = try? decoder.decode([NutritionLog].self, from: data)
        else {
            return []
        }

        return logs
    }

    private func persist(_ logs: [NutritionLog]) {
        guard let data = try? encoder.encode(logs) else {
            return
        }

        userDefaults.set(data, forKey: StorageKey.logs)
    }
}
