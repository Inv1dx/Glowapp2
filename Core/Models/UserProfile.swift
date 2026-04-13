import Foundation

struct UserProfile: Codable, Equatable, Sendable {
    enum PrimaryGoal: String, CaseIterable, Codable, Identifiable, Sendable {
        case fatLoss = "fat_loss"
        case leanGain = "lean_gain"
        case glowUp = "glow_up"
        case routineReset = "routine_reset"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .fatLoss:
                "Fat loss"
            case .leanGain:
                "Lean gain"
            case .glowUp:
                "Glow up"
            case .routineReset:
                "Routine reset"
            }
        }

        var detail: String {
            switch self {
            case .fatLoss:
                "Tighten up your day around movement, protein, and clean consistency."
            case .leanGain:
                "Push food, sleep, and training support in a steady direction."
            case .glowUp:
                "Level up your energy, habits, and overall presence."
            case .routineReset:
                "Get your basics back in place and rebuild momentum fast."
            }
        }
    }

    enum Field: Hashable, Sendable {
        case displayName
        case dailySteps
        case sleepHours
        case proteinGrams
        case waterML
    }

    struct ValidationIssue: Equatable, Sendable {
        let field: Field
        let message: String
    }

    static let displayNameMaxLength = 24
    static let dailyStepsRange = 3_000...30_000
    static let sleepHoursRange = 5.0...10.0
    static let proteinRange = 40...250
    static let waterRange = 500...5_000

    static let defaultPrimaryGoal: PrimaryGoal = .glowUp
    static let defaultDailySteps = 8_000
    static let defaultSleepHours = 8.0
    static let defaultProteinGrams = 110
    static let defaultWaterML = 2_500

    let displayName: String
    let primaryGoal: PrimaryGoal
    let targetDailySteps: Int
    let targetSleepHours: Double
    let targetProteinGrams: Int
    let targetWaterML: Int
    let onboardingCompleted: Bool

    init(
        displayName: String,
        primaryGoal: PrimaryGoal,
        targetDailySteps: Int,
        targetSleepHours: Double,
        targetProteinGrams: Int,
        targetWaterML: Int,
        onboardingCompleted: Bool
    ) {
        self.displayName = Self.trimmedDisplayName(displayName)
        self.primaryGoal = primaryGoal
        self.targetDailySteps = targetDailySteps
        self.targetSleepHours = targetSleepHours
        self.targetProteinGrams = targetProteinGrams
        self.targetWaterML = targetWaterML
        self.onboardingCompleted = onboardingCompleted
    }

    var validationIssues: [ValidationIssue] {
        var issues: [ValidationIssue] = []

        if displayName.isEmpty {
            issues.append(
                ValidationIssue(
                    field: .displayName,
                    message: "Enter a name or nickname."
                )
            )
        }

        if displayName.count > Self.displayNameMaxLength {
            issues.append(
                ValidationIssue(
                    field: .displayName,
                    message: "Keep your name under \(Self.displayNameMaxLength) characters."
                )
            )
        }

        if !Self.dailyStepsRange.contains(targetDailySteps) {
            issues.append(
                ValidationIssue(
                    field: .dailySteps,
                    message: "Set steps between 3,000 and 30,000."
                )
            )
        }

        if !Self.sleepHoursRange.contains(targetSleepHours) {
            issues.append(
                ValidationIssue(
                    field: .sleepHours,
                    message: "Set sleep between 5 and 10 hours."
                )
            )
        }

        if !Self.proteinRange.contains(targetProteinGrams) {
            issues.append(
                ValidationIssue(
                    field: .proteinGrams,
                    message: "Set protein between 40 and 250 grams."
                )
            )
        }

        if !Self.waterRange.contains(targetWaterML) {
            issues.append(
                ValidationIssue(
                    field: .waterML,
                    message: "Set water between 500 and 5,000 ml."
                )
            )
        }

        return issues
    }

    var isValid: Bool {
        validationIssues.isEmpty
    }

    static func trimmedDisplayName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
