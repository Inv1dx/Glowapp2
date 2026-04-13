import Foundation

struct DayBoundary: Sendable {
    let start: Date
    let end: Date
}

enum DayBoundaryFactory {
    static func day(
        for date: Date,
        calendar: Calendar = .current
    ) -> DayBoundary {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return DayBoundary(start: start, end: end)
    }

    static func isSameDay(
        _ lhs: Date,
        _ rhs: Date,
        calendar: Calendar = .current
    ) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
}
