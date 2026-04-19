import SwiftUI

enum GlowScoreHeroState {
    case waiting
    case needsWork
    case building
    case solid
    case strong

    init(score: GlowScore) {
        guard score.availableCategoriesCount > 0 else {
            self = .waiting
            return
        }

        switch score.overallScore {
        case ..<40:
            self = .needsWork
        case ..<60:
            self = .building
        case ..<80:
            self = .solid
        default:
            self = .strong
        }
    }

    var label: String {
        switch self {
        case .waiting:
            "Waiting"
        case .needsWork:
            "Needs work"
        case .building:
            "Building"
        case .solid:
            "Solid"
        case .strong:
            "Strong day"
        }
    }

    var labelColor: Color {
        switch self {
        case .waiting:
            GlowColors.textSecondary
        case .needsWork, .building:
            GlowColors.textPrimary
        case .solid:
            GlowColors.accent.opacity(0.9)
        case .strong:
            GlowColors.accent
        }
    }
}

enum GlowScoreAvailabilityKind {
    case empty
    case partial
    case complete
}

extension GlowScore {
    var orderedBreakdowns: [GlowScoreCategoryBreakdown] {
        GlowScoreCategory.allCases.compactMap { category in
            breakdowns.first { $0.category == category }
        }
    }

    var availabilityKind: GlowScoreAvailabilityKind {
        if availableCategoriesCount == 0 {
            return .empty
        }

        if availableCategoriesCount == GlowScoreCategory.allCases.count {
            return .complete
        }

        return .partial
    }

    var displayScoreText: String {
        availableCategoriesCount == 0 ? "--" : overallScore.formatted()
    }

    var availabilityBadgeTitle: String {
        switch availabilityKind {
        case .empty:
            "Needs inputs"
        case .partial:
            "Partial score"
        case .complete:
            "All inputs"
        }
    }

    var availabilityDetailText: String {
        let totalCount = GlowScoreCategory.allCases.count

        if availableCategoriesCount == 0 {
            return "No inputs available yet"
        }

        return "\(availableCategoriesCount.formatted()) of \(totalCount.formatted()) inputs available"
    }

    var biggestLeverText: String {
        if availableCategoriesCount == 0 {
            return "Add today's first input"
        }

        if orderedBreakdowns.contains(where: { $0.connectsAppleHealth }) {
            return "Connect Apple Health"
        }

        if let missingBreakdown = orderedBreakdowns.first(where: { $0.dataState == .missing }) {
            return missingBreakdown.missingDataLeverText
        }

        if orderedBreakdowns.contains(where: { $0.dataState == .unavailable }) {
            return "Lean on manual inputs today"
        }

        if let lowestBreakdown = orderedBreakdowns
            .filter({ $0.status == .available })
            .min(by: { ($0.score ?? 101) < ($1.score ?? 101) }) {
            return lowestBreakdown.improvementLeverText
        }

        return "Keep today's streak going"
    }

    func accessibilitySummary(stateLabel: String) -> String {
        let scoreText = availableCategoriesCount == 0
            ? "Waiting for inputs"
            : "\(overallScore.formatted()) out of 100"
        let totalCount = GlowScoreCategory.allCases.count
        let availabilityText = "\(availableCategoriesCount.formatted()) of \(totalCount.formatted()) inputs available"

        return "\(scoreText), \(stateLabel), \(availabilityText)"
    }
}

extension GlowScoreCategory {
    var shortTitle: String {
        switch self {
        case .routineConsistency:
            "Routine"
        default:
            title
        }
    }
}

extension GlowScoreCategoryBreakdown {
    var connectsAppleHealth: Bool {
        summaryText.localizedCaseInsensitiveContains("Connect Apple Health")
    }

    var missingDataLeverText: String {
        switch category {
        case .sleep:
            "Sync last night's sleep"
        case .activity:
            "Add a quick walk"
        case .nutrition:
            "Log your next meal"
        case .hydration:
            "Log another glass of water"
        case .routineConsistency:
            "Complete your next routine"
        }
    }

    var improvementLeverText: String {
        switch category {
        case .sleep:
            "Protect tonight's sleep window"
        case .activity:
            "Add a quick walk"
        case .nutrition:
            "Hit your protein target"
        case .hydration:
            "Log another glass of water"
        case .routineConsistency:
            "Complete your next routine"
        }
    }

    var accessibilityStatusLabel: String {
        if let score {
            return "\(score.formatted()) points"
        }

        switch dataState {
        case .missing:
            return "missing today"
        case .unavailable:
            return connectsAppleHealth ? "available after connecting Apple Health" : "unavailable"
        case .available:
            return "available"
        }
    }
}
