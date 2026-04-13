import XCTest
@testable import GlowApp

final class RoutineRepositoryTests: XCTestCase {
    func testRoutineSummaryReflectsTodayCompletionAndUndo() async {
        let repository = makeRepository()
        let today = Date()

        await repository.setCompleted(true, for: .am, on: today)

        var summary = await repository.loadSummary(for: today)
        XCTAssertTrue(summary.status(for: .am).isCompleted)
        XCTAssertEqual(summary.status(for: .am).streakCount, 1)

        await repository.setCompleted(false, for: .am, on: today)

        summary = await repository.loadSummary(for: today)
        XCTAssertFalse(summary.status(for: .am).isCompleted)
        XCTAssertEqual(summary.status(for: .am).streakCount, 0)
    }

    func testRoutineStreakCountsConsecutiveDaysOnly() async {
        let repository = makeRepository()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today

        await repository.setCompleted(true, for: .pm, on: twoDaysAgo)
        await repository.setCompleted(true, for: .pm, on: yesterday)
        await repository.setCompleted(true, for: .pm, on: today)

        let summary = await repository.loadSummary(for: today)

        XCTAssertEqual(summary.status(for: .pm).streakCount, 3)
    }

    func testRoutineEntriesPersistAcrossRepositoryInstances() async {
        let userDefaults = makeUserDefaults()
        let firstRepository = LocalRoutineRepository(userDefaults: userDefaults)
        let secondRepository = LocalRoutineRepository(userDefaults: userDefaults)

        await firstRepository.setCompleted(true, for: .grooming, on: Date())

        let summary = await secondRepository.loadSummary(for: Date())

        XCTAssertTrue(summary.status(for: .grooming).isCompleted)
        XCTAssertEqual(summary.status(for: .grooming).streakCount, 1)
    }

    private func makeRepository() -> LocalRoutineRepository {
        LocalRoutineRepository(userDefaults: makeUserDefaults())
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "GlowApp.routine-tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
