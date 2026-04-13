import Foundation

protocol GlowRepository {
    func loadScore(for date: Date) async -> GlowScore?
    func upsertScore(_ score: GlowScore) async
}

final class LocalGlowRepository: GlowRepository {
    private enum StorageKey {
        static let scores = "glow.score.dailyScores"
    }

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let calendar: Calendar

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

    func loadScore(for date: Date) async -> GlowScore? {
        let normalizedDate = calendar.startOfDay(for: date)

        return loadAllScores().first {
            DayBoundaryFactory.isSameDay($0.date, normalizedDate, calendar: calendar)
        }
    }

    func upsertScore(_ score: GlowScore) async {
        let normalizedScore = GlowScore(
            date: calendar.startOfDay(for: score.date),
            overallScore: score.overallScore,
            availableWeight: score.availableWeight,
            totalWeight: score.totalWeight,
            breakdowns: score.breakdowns,
            explanations: score.explanations,
            configVersion: score.configVersion,
            computedAt: score.computedAt
        )

        var scores = loadAllScores().filter {
            !DayBoundaryFactory.isSameDay($0.date, normalizedScore.date, calendar: calendar)
        }
        scores.append(normalizedScore)
        scores.sort { $0.date > $1.date }
        persist(scores)
    }

    private func loadAllScores() -> [GlowScore] {
        guard
            let data = userDefaults.data(forKey: StorageKey.scores),
            let scores = try? decoder.decode([GlowScore].self, from: data)
        else {
            return []
        }

        return scores
    }

    private func persist(_ scores: [GlowScore]) {
        guard let data = try? encoder.encode(scores) else {
            return
        }

        userDefaults.set(data, forKey: StorageKey.scores)
    }
}
