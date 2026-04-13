import Foundation

enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case home
    case routines
    case progress
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            "Home"
        case .routines:
            "Routines"
        case .progress:
            "Progress"
        case .settings:
            "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .routines:
            "checklist"
        case .progress:
            "chart.line.uptrend.xyaxis"
        case .settings:
            "gearshape"
        }
    }
}
