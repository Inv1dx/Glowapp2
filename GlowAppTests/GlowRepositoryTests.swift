import XCTest
@testable import GlowApp

final class GlowRepositoryTests: XCTestCase {
    func testUpsertReplacesExistingScoreForSameDay() async {
        let repository = makeRepository()
        let date = makeDate(year: 2026, month: 4, day: 13, hour: 9)

        await repository.upsertScore(makeScore(date: date, overallScore: 62))
        await repository.upsertScore(makeScore(date: date, overallScore: 81))

        let loaded = await repository.loadScore(for: date)

        XCTAssertEqual(loaded?.overallScore, 81)
        XCTAssertEqual(loaded?.date, calendar.startOfDay(for: date))
    }

    func testScoresAreStoredSeparatelyAcrossDays() async {
        let repository = makeRepository()
        let firstDay = makeDate(year: 2026, month: 4, day: 13, hour: 9)
        let secondDay = makeDate(year: 2026, month: 4, day: 14, hour: 9)

        await repository.upsertScore(makeScore(date: firstDay, overallScore: 70))
        await repository.upsertScore(makeScore(date: secondDay, overallScore: 88))

        let firstLoaded = await repository.loadScore(for: firstDay)
        let secondLoaded = await repository.loadScore(for: secondDay)

        XCTAssertEqual(firstLoaded?.overallScore, 70)
        XCTAssertEqual(secondLoaded?.overallScore, 88)
    }

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private func makeRepository() -> LocalGlowRepository {
        let suiteName = "GlowApp.glow-score-tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)

        return LocalGlowRepository(
            userDefaults: userDefaults,
            calendar: calendar
        )
    }

    private func makeScore(date: Date, overallScore: Int) -> GlowScore {
        GlowScore(
            date: date,
            overallScore: overallScore,
            availableWeight: 100,
            totalWeight: 100,
            breakdowns: [
                GlowScoreCategoryBreakdown(
                    category: .sleep,
                    score: overallScore,
                    weight: 25,
                    status: .available,
                    dataState: .available,
                    summaryText: "Summary",
                    explanation: "Explanation"
                )
            ],
            explanations: ["Explanation"],
            configVersion: GlowScoreConfig.stage5.version,
            computedAt: date
        )
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        )

        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
