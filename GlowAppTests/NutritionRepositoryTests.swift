import XCTest
@testable import GlowApp

final class NutritionRepositoryTests: XCTestCase {
    func testNutritionSummaryAggregatesCaloriesProteinAndWaterForToday() async throws {
        let repository = makeRepository()
        let today = Date()

        try await repository.saveLog(
            NutritionLog(
                loggedAt: today,
                calories: 540,
                proteinGrams: 38,
                waterML: 0,
                entryType: .meal
            )
        )
        try await repository.saveLog(
            NutritionLog(
                loggedAt: today,
                calories: 220,
                proteinGrams: 0,
                waterML: 0,
                entryType: .quickCalories
            )
        )
        try await repository.saveLog(
            NutritionLog(
                loggedAt: today,
                calories: 0,
                proteinGrams: 0,
                waterML: 500,
                entryType: .water
            )
        )

        let summary = await repository.loadSummary(for: today)

        XCTAssertEqual(summary.totalCalories, 760)
        XCTAssertEqual(summary.totalProteinGrams, 38)
        XCTAssertEqual(summary.totalWaterML, 500)
    }

    func testNutritionLogsPersistAcrossRepositoryInstancesAndSupportDelete() async throws {
        let userDefaults = makeUserDefaults()
        let firstRepository = LocalNutritionRepository(userDefaults: userDefaults)
        let secondRepository = LocalNutritionRepository(userDefaults: userDefaults)

        let log = NutritionLog(
            loggedAt: Date(),
            calories: 410,
            proteinGrams: 28,
            waterML: 0,
            entryType: .meal
        )

        try await firstRepository.saveLog(log)

        let persistedEntries = await secondRepository.loadEntries(for: Date())
        XCTAssertEqual(persistedEntries.count, 1)
        XCTAssertEqual(persistedEntries.first?.id, log.id)

        await secondRepository.deleteLog(id: log.id)

        let deletedEntries = await firstRepository.loadEntries(for: Date())
        XCTAssertTrue(deletedEntries.isEmpty)
    }

    func testSavingSameNutritionLogIDUpdatesExistingEntry() async throws {
        let repository = makeRepository()
        let log = NutritionLog(
            loggedAt: Date(),
            calories: 320,
            proteinGrams: 20,
            waterML: 0,
            entryType: .meal
        )

        try await repository.saveLog(log)
        try await repository.saveLog(
            NutritionLog(
                id: log.id,
                loggedAt: log.loggedAt,
                calories: 500,
                proteinGrams: 44,
                waterML: 0,
                entryType: .meal
            )
        )

        let entries = await repository.loadEntries(for: Date())

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.calories, 500)
        XCTAssertEqual(entries.first?.proteinGrams, 44)
    }

    private func makeRepository() -> LocalNutritionRepository {
        LocalNutritionRepository(userDefaults: makeUserDefaults())
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "GlowApp.nutrition-tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
