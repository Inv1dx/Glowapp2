import Foundation

enum RoutineTemplate: String, CaseIterable, Codable, Identifiable, Sendable {
    case am
    case pm
    case grooming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .am:
            "AM routine"
        case .pm:
            "PM routine"
        case .grooming:
            "Grooming"
        }
    }

    var shortTitle: String {
        switch self {
        case .am:
            "AM"
        case .pm:
            "PM"
        case .grooming:
            "Grooming"
        }
    }

    var detail: String {
        switch self {
        case .am:
            "Morning basics done"
        case .pm:
            "Night reset complete"
        case .grooming:
            "Appearance upkeep checked off"
        }
    }

    var systemImage: String {
        switch self {
        case .am:
            "sun.max.fill"
        case .pm:
            "moon.stars.fill"
        case .grooming:
            "sparkles"
        }
    }
}
