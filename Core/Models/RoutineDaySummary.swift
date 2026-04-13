import Foundation

struct RoutineDaySummary: Equatable, Sendable {
    struct Status: Identifiable, Equatable, Sendable {
        let template: RoutineTemplate
        let isCompleted: Bool
        let streakCount: Int

        var id: RoutineTemplate { template }
    }

    let date: Date
    let statuses: [Status]

    static func empty(for date: Date) -> RoutineDaySummary {
        RoutineDaySummary(
            date: date,
            statuses: RoutineTemplate.allCases.map {
                Status(template: $0, isCompleted: false, streakCount: 0)
            }
        )
    }

    func status(for template: RoutineTemplate) -> Status {
        statuses.first(where: { $0.template == template }) ??
        Status(template: template, isCompleted: false, streakCount: 0)
    }
}
