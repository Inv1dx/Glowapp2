import XCTest
@testable import GlowApp

final class ProgressInsightsTests: XCTestCase {
    func testBuilderProducesExpectedSummariesAndOldestFirstTrendSeries() {
        let builder = ProgressInsightsBuilder(calendar: calendar)
        let referenceDate = makeDate(year: 2026, month: 4, day: 14, hour: 12)
        let entries = [
            ProgressEntry(
                checkInDate: makeDate(year: 2026, month: 4, day: 14, hour: 9),
                weightKg: 72.4,
                waistCm: 80.0
            ),
            ProgressEntry(
                checkInDate: makeDate(year: 2026, month: 4, day: 7, hour: 9),
                weightKg: 73.0,
                waistCm: 81.0
            ),
            ProgressEntry(
                checkInDate: makeDate(year: 2026, month: 3, day: 31, hour: 9),
                weightKg: 73.8
            )
        ]
        let glowScores = [
            makeScore(
                date: makeDate(year: 2026, month: 4, day: 7, hour: 8),
                overallScore: 71
            ),
            makeScore(
                date: makeDate(year: 2026, month: 4, day: 14, hour: 8),
                overallScore: 78
            )
        ]

        let insights = builder.build(
            entries: entries,
            glowScores: glowScores,
            referenceDate: referenceDate
        )

        XCTAssertEqual(insights.weightSeries.map(\.value), [73.8, 73.0, 72.4])
        XCTAssertEqual(insights.glowScoreSeries.map(\.value), [71, 78])

        let streakMetric = insights.summaryMetrics.first { $0.id == "weekly-streak" }
        XCTAssertEqual(streakMetric?.valueText, "3 weeks")
        XCTAssertEqual(streakMetric?.detailText, "3 of the last 4 weeks")

        let weightMetric = insights.summaryMetrics.first { $0.id == "weight-change" }
        XCTAssertEqual(
            weightMetric?.valueText.replacingOccurrences(of: ",", with: "."),
            "-0.6 kg"
        )
        XCTAssertEqual(weightMetric?.detailText, "Since previous check-in")
    }

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.firstWeekday = 2
        return calendar
    }()

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
}
