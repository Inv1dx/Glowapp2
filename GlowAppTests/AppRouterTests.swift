import XCTest
@testable import GlowApp

final class AppRouterTests: XCTestCase {
    @MainActor
    func testFreshInstallRoutesToOnboarding() async {
        let router = AppRouter(userRepository: MockUserRepository(profile: nil))

        await router.loadInitialDestinationIfNeeded()

        XCTAssertEqual(router.rootDestination, .onboarding)
    }

    @MainActor
    func testCompletedProfileRoutesToMainTabs() async {
        let profile = UserProfile(
            displayName: "Kai",
            primaryGoal: .routineReset,
            targetDailySteps: UserProfile.defaultDailySteps,
            targetSleepHours: UserProfile.defaultSleepHours,
            targetProteinGrams: UserProfile.defaultProteinGrams,
            targetWaterML: UserProfile.defaultWaterML,
            onboardingCompleted: true
        )
        let router = AppRouter(userRepository: MockUserRepository(profile: profile))

        await router.loadInitialDestinationIfNeeded()

        XCTAssertEqual(router.rootDestination, .mainTabs)
    }

    @MainActor
    func testRepositoryFailureFallsBackToOnboarding() async {
        let router = AppRouter(userRepository: MockUserRepository(profile: nil, shouldThrow: true))

        await router.loadInitialDestinationIfNeeded()

        XCTAssertEqual(router.rootDestination, .onboarding)
        XCTAssertEqual(
            router.launchErrorMessage,
            "We couldn't load your saved setup. You can finish it again."
        )
    }
}

private struct MockUserRepository: UserRepository {
    let profile: UserProfile?
    var shouldThrow = false

    func loadUserProfile() async throws -> UserProfile? {
        if shouldThrow {
            throw UserRepositoryError.failedToDecodeProfile
        }

        return profile
    }

    func saveUserProfile(_ profile: UserProfile) async throws {}

    func clearUserProfile() async throws {}
}
