import XCTest
@testable import GlowApp

final class UserProfileTests: XCTestCase {
    func testInitializerTrimsDisplayName() {
        let profile = UserProfile(
            displayName: "  Alex  ",
            primaryGoal: .glowUp,
            targetDailySteps: UserProfile.defaultDailySteps,
            targetSleepHours: UserProfile.defaultSleepHours,
            targetProteinGrams: UserProfile.defaultProteinGrams,
            targetWaterML: UserProfile.defaultWaterML,
            onboardingCompleted: false
        )

        XCTAssertEqual(profile.displayName, "Alex")
        XCTAssertTrue(profile.validationIssues.isEmpty)
    }

    func testValidationRequiresDisplayName() {
        let profile = UserProfile(
            displayName: "   ",
            primaryGoal: .routineReset,
            targetDailySteps: UserProfile.defaultDailySteps,
            targetSleepHours: UserProfile.defaultSleepHours,
            targetProteinGrams: UserProfile.defaultProteinGrams,
            targetWaterML: UserProfile.defaultWaterML,
            onboardingCompleted: false
        )

        XCTAssertEqual(
            profile.validationIssues,
            [
                UserProfile.ValidationIssue(
                    field: .displayName,
                    message: "Enter a name or nickname."
                )
            ]
        )
    }

    func testValidationRejectsTargetsOutsideSafeRanges() {
        let profile = UserProfile(
            displayName: "Alex",
            primaryGoal: .fatLoss,
            targetDailySteps: 1_000,
            targetSleepHours: 4.0,
            targetProteinGrams: 20,
            targetWaterML: 300,
            onboardingCompleted: false
        )

        XCTAssertEqual(
            profile.validationIssues.map(\.field),
            [.dailySteps, .sleepHours, .proteinGrams, .waterML]
        )
    }
}
