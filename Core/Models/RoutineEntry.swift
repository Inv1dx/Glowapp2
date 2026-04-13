import Foundation

struct RoutineEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let template: RoutineTemplate
    let day: Date
    let completedAt: Date

    init(
        id: UUID = UUID(),
        template: RoutineTemplate,
        day: Date,
        completedAt: Date
    ) {
        self.id = id
        self.template = template
        self.day = day
        self.completedAt = completedAt
    }
}
