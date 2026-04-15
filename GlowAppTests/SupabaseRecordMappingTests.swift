import XCTest
@testable import GlowApp

final class SupabaseRecordMappingTests: XCTestCase {
    func testDayStringUsesRepositoryCalendarDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current

        let date = Date(timeIntervalSince1970: 1_776_194_400) // 2026-04-15 03:20:00 +0800

        XCTAssertEqual(
            SupabaseDateCoding.dayString(from: date, calendar: calendar),
            "2026-04-15"
        )

        let decodedDate = try SupabaseDateCoding.date(
            fromDayString: "2026-04-15",
            calendar: calendar
        )

        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: decodedDate).year,
            2026
        )
        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: decodedDate).month,
            4
        )
        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: decodedDate).day,
            15
        )
    }

    func testNutritionLogRecordRoundTripsAppModel() throws {
        let loggedAt = Date(timeIntervalSince1970: 1_776_240_000)
        let log = NutritionLog(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            loggedAt: loggedAt,
            calories: 420,
            proteinGrams: 35,
            waterML: 500,
            entryType: .meal
        )

        let record = SupabaseNutritionLogRecord(
            userId: "user-1",
            log: log,
            calendar: utcCalendar,
            updatedAt: loggedAt
        )
        let roundTrippedLog = try record.makeLog()

        XCTAssertEqual(record.userId, "user-1")
        XCTAssertEqual(record.date, "2026-04-15")
        XCTAssertEqual(roundTrippedLog, log)
    }

    func testGlowScoreRecordKeepsNestedBreakdowns() throws {
        let date = Date(timeIntervalSince1970: 1_776_240_000)
        let score = GlowScore(
            date: date,
            overallScore: 82,
            availableWeight: 80,
            totalWeight: 100,
            breakdowns: [
                GlowScoreCategoryBreakdown(
                    category: .nutrition,
                    score: 90,
                    weight: 25,
                    status: .available,
                    dataState: .available,
                    summaryText: "Protein hit",
                    explanation: "Logged enough protein."
                )
            ],
            explanations: ["Strong nutrition day."],
            configVersion: GlowScoreConfig.stage5.version,
            computedAt: date
        )

        let record = SupabaseGlowScoreRecord(
            userId: "user-1",
            score: score,
            calendar: utcCalendar,
            updatedAt: date
        )
        let roundTrippedScore = try record.makeScore(calendar: utcCalendar)

        XCTAssertEqual(record.date, "2026-04-15")
        XCTAssertEqual(roundTrippedScore, score)
    }

    func testProgressEntryRecordRestoresNoonCheckInDate() throws {
        let date = makeUTCDate(year: 2026, month: 4, day: 15, hour: 9)
        let entry = ProgressEntry(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            checkInDate: date,
            weightKg: 82.4,
            waistCm: 90.2,
            frontPhotoPath: "ProgressPhotos/front.jpg",
            sidePhotoPath: nil
        )

        let record = SupabaseProgressEntryRecord(
            userId: "user-1",
            entry: entry,
            calendar: utcCalendar,
            updatedAt: date
        )
        let roundTrippedEntry = try record.makeEntry(calendar: utcCalendar)

        XCTAssertEqual(record.checkInDate, "2026-04-15")
        XCTAssertEqual(utcCalendar.component(.hour, from: roundTrippedEntry.checkInDate), 12)
        XCTAssertEqual(roundTrippedEntry.weightKg, entry.weightKg)
        XCTAssertEqual(roundTrippedEntry.frontPhotoPath, entry.frontPhotoPath)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private func makeUTCDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        DateComponents(
            calendar: utcCalendar,
            timeZone: utcCalendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date ?? Date(timeIntervalSince1970: 0)
    }
}
