import XCTest
@testable import GlowApp

final class GlowPlanRepositoryTests: XCTestCase {
    func testPlansPersistSeparatelyAcrossDays() async {
        let repository = makeRepository()
        let firstDay = makeDate(year: 2026, month: 4, day: 13, hour: 9)
        let secondDay = makeDate(year: 2026, month: 4, day: 14, hour: 9)

        await repository.savePlan(makePlan(date: firstDay, title: "Drink water"))
        await repository.savePlan(makePlan(date: secondDay, title: "Walk more"))

        let firstLoaded = await repository.loadPlan(for: firstDay)
        let secondLoaded = await repository.loadPlan(for: secondDay)

        XCTAssertEqual(firstLoaded?.actions.first?.title, "Drink water")
        XCTAssertEqual(secondLoaded?.actions.first?.title, "Walk more")
    }

    func testCompletionUpdatesPersistAcrossRepositoryInstances() async {
        let userDefaults = makeUserDefaults()
        let firstRepository = LocalGlowPlanRepository(
            userDefaults: userDefaults,
            calendar: calendar
        )
        let secondRepository = LocalGlowPlanRepository(
            userDefaults: userDefaults,
            calendar: calendar
        )
        let date = makeDate(year: 2026, month: 4, day: 13, hour: 20)

        await firstRepository.savePlan(makePlan(date: date, title: "Finish water"))
        await secondRepository.setActionCompleted(true, for: .hydrationGoal, on: date)

        let loaded = await firstRepository.loadPlan(for: date)

        XCTAssertEqual(loaded?.actions.first?.isCompleted, true)
    }

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private func makeRepository() -> LocalGlowPlanRepository {
        LocalGlowPlanRepository(
            userDefaults: makeUserDefaults(),
            calendar: calendar
        )
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "GlowApp.glow-plan-tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makePlan(date: Date, title: String) -> GlowPlan {
        GlowPlan(
            date: date,
            generatedAt: date,
            mode: .focused,
            actions: [
                GlowPlanAction(
                    kind: .hydrationGoal,
                    title: title,
                    detail: nil,
                    priority: 1,
                    isCompleted: false
                )
            ]
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
