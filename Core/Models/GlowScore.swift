import Foundation

enum GlowScoreCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case sleep
    case activity
    case nutrition
    case hydration
    case routineConsistency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep:
            "Sleep"
        case .activity:
            "Activity"
        case .nutrition:
            "Nutrition"
        case .hydration:
            "Hydration"
        case .routineConsistency:
            "Routine consistency"
        }
    }

    var systemImage: String {
        switch self {
        case .sleep:
            "moon.stars.fill"
        case .activity:
            "figure.walk"
        case .nutrition:
            "fork.knife"
        case .hydration:
            "drop.fill"
        case .routineConsistency:
            "checkmark.circle.fill"
        }
    }
}

enum GlowScoreCategoryStatus: String, Codable, Equatable, Sendable {
    case available
    case unavailable
}

enum GlowScoreDataState: String, Codable, Equatable, Sendable {
    case available
    case missing
    case unavailable
}

enum GlowScoreUnavailableReason: String, Equatable, Sendable {
    case appleHealthNotConnected
    case appleHealthUnavailable
    case accessLimited
    case unsupported
    case unavailable
}

enum GlowScoreMeasurementAvailability: Equatable, Sendable {
    case available
    case missing
    case unavailable(GlowScoreUnavailableReason)
}

struct GlowScoreMeasurement<Value: Equatable & Sendable>: Equatable, Sendable {
    let value: Value?
    let availability: GlowScoreMeasurementAvailability

    static func available(_ value: Value) -> Self {
        GlowScoreMeasurement(value: value, availability: .available)
    }

    static func missing() -> Self {
        GlowScoreMeasurement(value: nil, availability: .missing)
    }

    static func unavailable(_ reason: GlowScoreUnavailableReason) -> Self {
        GlowScoreMeasurement(value: nil, availability: .unavailable(reason))
    }
}

struct GlowScoreInput: Equatable, Sendable {
    let day: Date
    let evaluatedAt: Date
    let userProfile: UserProfile?
    let sleepHours: GlowScoreMeasurement<Double>
    let steps: GlowScoreMeasurement<Int>
    let activeCalories: GlowScoreMeasurement<Double>
    let caloriesIn: GlowScoreMeasurement<Int>
    let proteinGrams: GlowScoreMeasurement<Int>
    let waterML: GlowScoreMeasurement<Int>
    let amRoutineCompleted: GlowScoreMeasurement<Bool>
    let pmRoutineCompleted: GlowScoreMeasurement<Bool>
    let groomingCompleted: GlowScoreMeasurement<Bool>
}

struct GlowScore: Codable, Equatable, Sendable {
    let date: Date
    let overallScore: Int
    let availableWeight: Int
    let totalWeight: Int
    let breakdowns: [GlowScoreCategoryBreakdown]
    let explanations: [String]
    let configVersion: String
    let computedAt: Date

    var availableCategoriesCount: Int {
        breakdowns.filter { $0.status == .available }.count
    }
}

struct GlowScoreCategoryBreakdown: Codable, Equatable, Identifiable, Sendable {
    let category: GlowScoreCategory
    let score: Int?
    let weight: Int
    let status: GlowScoreCategoryStatus
    let dataState: GlowScoreDataState
    let summaryText: String
    let explanation: String

    var id: GlowScoreCategory { category }
}

struct GlowScoreConfig: Equatable, Sendable {
    struct CategoryWeights: Equatable, Sendable {
        let sleep: Int
        let activity: Int
        let nutrition: Int
        let hydration: Int
        let routineConsistency: Int

        var total: Int {
            sleep + activity + nutrition + hydration + routineConsistency
        }

        func weight(for category: GlowScoreCategory) -> Int {
            switch category {
            case .sleep:
                sleep
            case .activity:
                activity
            case .nutrition:
                nutrition
            case .hydration:
                hydration
            case .routineConsistency:
                routineConsistency
            }
        }
    }

    struct FallbackTargets: Equatable, Sendable {
        let dailySteps: Int
        let sleepHours: Double
        let proteinGrams: Int
        let waterML: Int
    }

    struct SleepSettings: Equatable, Sendable {
        let fullCreditDeltaHours: Double
        let zeroCreditDeltaHours: Double
        let minimumScore: Int
    }

    struct ProgressCheckpoint: Equatable, Sendable {
        let hour: Int
        let minute: Int
        let progress: Double

        var minuteOfDay: Int {
            (hour * 60) + minute
        }
    }

    struct ProgressCurve: Equatable, Sendable {
        let checkpoints: [ProgressCheckpoint]
    }

    struct ActivitySettings: Equatable, Sendable {
        let graceFactor: Double
        let stepsWeight: Double
        let activeCaloriesWeight: Double
        let activeCaloriesTarget: Double
    }

    struct NutritionLoggingBonus: Equatable, Sendable {
        let mediumCaloriesThreshold: Int
        let highCaloriesThreshold: Int
        let mediumBonus: Int
        let highBonus: Int
    }

    struct NutritionSettings: Equatable, Sendable {
        let graceFactor: Double
        let proteinWeight: Double
        let caloriesLoggingWeight: Double
        let loggingBonus: NutritionLoggingBonus
    }

    struct HydrationSettings: Equatable, Sendable {
        let graceFactor: Double
    }

    struct RoutineWeights: Equatable, Sendable {
        let am: Double
        let pm: Double
        let grooming: Double
    }

    struct RoutineWindow: Equatable, Sendable {
        let startHour: Int
        let startMinute: Int
        let endHour: Int
        let endMinute: Int

        var startMinuteOfDay: Int {
            (startHour * 60) + startMinute
        }

        var endMinuteOfDay: Int {
            (endHour * 60) + endMinute
        }
    }

    struct RoutineSettings: Equatable, Sendable {
        let weights: RoutineWeights
        let amWindow: RoutineWindow
        let pmWindow: RoutineWindow
        let groomingWindow: RoutineWindow
    }

    let version: String
    let categoryWeights: CategoryWeights
    let fallbackTargets: FallbackTargets
    let sleep: SleepSettings
    let progressCurve: ProgressCurve
    let activity: ActivitySettings
    let nutrition: NutritionSettings
    let hydration: HydrationSettings
    let routine: RoutineSettings
}

extension GlowScoreConfig {
    static let stage5 = GlowScoreConfig(
        version: "stage5.v1",
        categoryWeights: CategoryWeights(
            sleep: 25,
            activity: 20,
            nutrition: 25,
            hydration: 10,
            routineConsistency: 20
        ),
        fallbackTargets: FallbackTargets(
            dailySteps: UserProfile.defaultDailySteps,
            sleepHours: UserProfile.defaultSleepHours,
            proteinGrams: UserProfile.defaultProteinGrams,
            waterML: UserProfile.defaultWaterML
        ),
        sleep: SleepSettings(
            fullCreditDeltaHours: 0.25,
            zeroCreditDeltaHours: 3.0,
            minimumScore: 20
        ),
        progressCurve: ProgressCurve(
            checkpoints: [
                ProgressCheckpoint(hour: 0, minute: 0, progress: 0.0),
                ProgressCheckpoint(hour: 6, minute: 0, progress: 0.02),
                ProgressCheckpoint(hour: 8, minute: 0, progress: 0.08),
                ProgressCheckpoint(hour: 10, minute: 0, progress: 0.18),
                ProgressCheckpoint(hour: 12, minute: 0, progress: 0.35),
                ProgressCheckpoint(hour: 15, minute: 0, progress: 0.55),
                ProgressCheckpoint(hour: 18, minute: 0, progress: 0.75),
                ProgressCheckpoint(hour: 21, minute: 0, progress: 0.92),
                ProgressCheckpoint(hour: 23, minute: 59, progress: 1.0)
            ]
        ),
        activity: ActivitySettings(
            graceFactor: 0.45,
            stepsWeight: 0.8,
            activeCaloriesWeight: 0.2,
            activeCaloriesTarget: 350
        ),
        nutrition: NutritionSettings(
            graceFactor: 0.50,
            proteinWeight: 0.9,
            caloriesLoggingWeight: 0.1,
            loggingBonus: NutritionLoggingBonus(
                mediumCaloriesThreshold: 250,
                highCaloriesThreshold: 700,
                mediumBonus: 50,
                highBonus: 100
            )
        ),
        hydration: HydrationSettings(
            graceFactor: 0.55
        ),
        routine: RoutineSettings(
            weights: RoutineWeights(
                am: 0.4,
                pm: 0.4,
                grooming: 0.2
            ),
            amWindow: RoutineWindow(
                startHour: 5,
                startMinute: 0,
                endHour: 11,
                endMinute: 0
            ),
            pmWindow: RoutineWindow(
                startHour: 18,
                startMinute: 0,
                endHour: 23,
                endMinute: 0
            ),
            groomingWindow: RoutineWindow(
                startHour: 7,
                startMinute: 0,
                endHour: 21,
                endMinute: 0
            )
        )
    )
}
