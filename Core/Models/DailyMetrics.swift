import Foundation

struct DailyMetrics: Codable, Equatable, Sendable {
    enum Field: String, CaseIterable, Codable, Hashable, Sendable {
        case steps
        case activeCalories
        case workoutsCount
        case sleepDurationHours
        case weightKg

        var displayTitle: String {
            switch self {
            case .steps:
                "Steps"
            case .activeCalories:
                "Active calories"
            case .workoutsCount:
                "Workouts"
            case .sleepDurationHours:
                "Sleep"
            case .weightKg:
                "Weight"
            }
        }
    }

    let date: Date
    let steps: Int
    let activeCalories: Double
    let workoutsCount: Int
    let sleepDurationHours: Double?
    let weightKg: Double?

    var hasAnyValue: Bool {
        steps > 0 ||
        activeCalories > 0 ||
        workoutsCount > 0 ||
        sleepDurationHours != nil ||
        weightKg != nil
    }

    static func empty(for date: Date) -> DailyMetrics {
        DailyMetrics(
            date: date,
            steps: 0,
            activeCalories: 0,
            workoutsCount: 0,
            sleepDurationHours: nil,
            weightKg: nil
        )
    }
}
