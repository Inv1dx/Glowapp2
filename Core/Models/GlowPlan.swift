import Foundation

enum GlowPlanMode: String, Codable, Equatable, Sendable {
    case focused
    case maintenance
}

enum GlowPlanActionKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case sleepWindDown
    case activityWalk
    case proteinGoal
    case hydrationGoal
    case morningRoutine
    case eveningRoutine
    case groomingReset
    case maintainSleep
    case maintainActivity
    case maintainProtein
    case maintainHydration

    var id: String { rawValue }

    var category: GlowScoreCategory {
        switch self {
        case .sleepWindDown, .maintainSleep:
            .sleep
        case .activityWalk, .maintainActivity:
            .activity
        case .proteinGoal, .maintainProtein:
            .nutrition
        case .hydrationGoal, .maintainHydration:
            .hydration
        case .morningRoutine, .eveningRoutine, .groomingReset:
            .routineConsistency
        }
    }
}

struct GlowPlanAction: Codable, Equatable, Identifiable, Sendable {
    let kind: GlowPlanActionKind
    let title: String
    let detail: String?
    let priority: Int
    var isCompleted: Bool

    var id: GlowPlanActionKind { kind }
    var category: GlowScoreCategory { kind.category }
}

struct GlowPlan: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let generatedAt: Date
    let mode: GlowPlanMode
    var actions: [GlowPlanAction]

    init(
        id: UUID = UUID(),
        date: Date,
        generatedAt: Date,
        mode: GlowPlanMode,
        actions: [GlowPlanAction]
    ) {
        self.id = id
        self.date = date
        self.generatedAt = generatedAt
        self.mode = mode
        self.actions = actions
    }
}
