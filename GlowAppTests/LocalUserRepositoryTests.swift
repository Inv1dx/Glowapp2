import XCTest
@testable import GlowApp

final class LocalUserRepositoryTests: XCTestCase {
    func testSaveAndLoadUserProfile() async throws {
        let userDefaults = makeUserDefaults()
        let repository = LocalUserRepository(userDefaults: userDefaults)
        let profile = UserProfile(
            displayName: "Mia",
            primaryGoal: .leanGain,
            targetDailySteps: 9_000,
            targetSleepHours: 8.5,
            targetProteinGrams: 140,
            targetWaterML: 3_000,
            onboardingCompleted: true
        )

        try await repository.saveUserProfile(profile)
        let loadedProfile = try await repository.loadUserProfile()

        XCTAssertEqual(loadedProfile, profile)
    }

    func testClearUserProfileRemovesStoredValue() async throws {
        let userDefaults = makeUserDefaults()
        let repository = LocalUserRepository(userDefaults: userDefaults)
        let profile = UserProfile(
            displayName: "Mia",
            primaryGoal: .glowUp,
            targetDailySteps: UserProfile.defaultDailySteps,
            targetSleepHours: UserProfile.defaultSleepHours,
            targetProteinGrams: UserProfile.defaultProteinGrams,
            targetWaterML: UserProfile.defaultWaterML,
            onboardingCompleted: true
        )

        try await repository.saveUserProfile(profile)
        try await repository.clearUserProfile()

        let loadedProfile = try await repository.loadUserProfile()

        XCTAssertNil(loadedProfile)
    }

    func testSaveRejectsInvalidProfile() async throws {
        let repository = LocalUserRepository(userDefaults: makeUserDefaults())
        let profile = UserProfile(
            displayName: "",
            primaryGoal: .glowUp,
            targetDailySteps: UserProfile.defaultDailySteps,
            targetSleepHours: UserProfile.defaultSleepHours,
            targetProteinGrams: UserProfile.defaultProteinGrams,
            targetWaterML: UserProfile.defaultWaterML,
            onboardingCompleted: false
        )

        do {
            try await repository.saveUserProfile(profile)
            XCTFail("Expected invalid profile error")
        } catch let error as UserRepositoryError {
            XCTAssertEqual(
                error,
                .invalidProfile(
                    [
                        UserProfile.ValidationIssue(
                            field: .displayName,
                            message: "Enter a name or nickname."
                        )
                    ]
                )
            )
        }
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "GlowAppTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
