import Foundation

struct ProgressSummaryMetric: Identifiable, Equatable {
    let id: String
    let title: String
    let valueText: String
    let detailText: String
}

struct ProgressTrendPoint: Identifiable, Equatable {
    let date: Date
    let value: Double

    var id: Date { date }
}

struct ProgressInsights: Equatable {
    let summaryMetrics: [ProgressSummaryMetric]
    let weightSeries: [ProgressTrendPoint]
    let waistSeries: [ProgressTrendPoint]
    let glowScoreSeries: [ProgressTrendPoint]
}

struct ProgressInsightsBuilder {
    let calendar: Calendar

    func build(
        entries: [ProgressEntry],
        glowScores: [GlowScore],
        referenceDate: Date = Date()
    ) -> ProgressInsights {
        let newestEntries = entries.sorted(by: newestFirst)
        let summaryMetrics = [
            totalCheckInsMetric(count: newestEntries.count),
            streakMetric(entries: newestEntries, referenceDate: referenceDate),
            measurementMetric(
                id: "weight-change",
                title: "Weight",
                unit: "kg",
                values: newestEntries.compactMap { entry in
                    guard let weightKg = entry.weightKg else {
                        return nil
                    }

                    return (entry.checkInDate, weightKg)
                }
            ),
            measurementMetric(
                id: "waist-change",
                title: "Waist",
                unit: "cm",
                values: newestEntries.compactMap { entry in
                    guard let waistCm = entry.waistCm else {
                        return nil
                    }

                    return (entry.checkInDate, waistCm)
                }
            )
        ]

        return ProgressInsights(
            summaryMetrics: summaryMetrics,
            weightSeries: trendSeries(
                from: newestEntries.compactMap { entry in
                    guard let weightKg = entry.weightKg else {
                        return nil
                    }

                    return ProgressTrendPoint(date: entry.checkInDate, value: weightKg)
                }
            ),
            waistSeries: trendSeries(
                from: newestEntries.compactMap { entry in
                    guard let waistCm = entry.waistCm else {
                        return nil
                    }

                    return ProgressTrendPoint(date: entry.checkInDate, value: waistCm)
                }
            ),
            glowScoreSeries: trendSeries(
                from: glowScores.map {
                    ProgressTrendPoint(
                        date: $0.date,
                        value: Double($0.overallScore)
                    )
                }
            )
        )
    }

    private func totalCheckInsMetric(count: Int) -> ProgressSummaryMetric {
        ProgressSummaryMetric(
            id: "total-check-ins",
            title: "Check-ins",
            valueText: count.formatted(),
            detailText: count == 0 ? "Add your first weekly check-in" : "Saved so far"
        )
    }

    private func streakMetric(
        entries: [ProgressEntry],
        referenceDate: Date
    ) -> ProgressSummaryMetric {
        let streak = weeklyStreakCount(entries: entries, referenceDate: referenceDate)
        let recentWeeks = recentWeeklyCheckInCount(
            entries: entries,
            referenceDate: referenceDate,
            weeks: 4
        )

        let valueText: String
        if streak == 1 {
            valueText = "1 week"
        } else {
            valueText = "\(streak.formatted()) weeks"
        }

        let detailText: String
        if recentWeeks == 0 {
            detailText = "No check-ins in the last 4 weeks"
        } else if recentWeeks == 1 {
            detailText = "1 of the last 4 weeks"
        } else {
            detailText = "\(recentWeeks.formatted()) of the last 4 weeks"
        }

        return ProgressSummaryMetric(
            id: "weekly-streak",
            title: "Weekly streak",
            valueText: valueText,
            detailText: detailText
        )
    }

    private func measurementMetric(
        id: String,
        title: String,
        unit: String,
        values: [(Date, Double)]
    ) -> ProgressSummaryMetric {
        let newestValues = values.sorted { lhs, rhs in
            if lhs.0 == rhs.0 {
                return lhs.1 > rhs.1
            }

            return lhs.0 > rhs.0
        }

        guard let latest = newestValues.first else {
            return ProgressSummaryMetric(
                id: id,
                title: title,
                valueText: "--",
                detailText: "No \(title.lowercased()) saved yet"
            )
        }

        guard newestValues.count > 1 else {
            return ProgressSummaryMetric(
                id: id,
                title: title,
                valueText: measurementText(latest.1, unit: unit),
                detailText: "First saved \(title.lowercased())"
            )
        }

        let delta = latest.1 - newestValues[1].1

        return ProgressSummaryMetric(
            id: id,
            title: title,
            valueText: deltaText(delta, unit: unit),
            detailText: "Since previous check-in"
        )
    }

    private func weeklyStreakCount(
        entries: [ProgressEntry],
        referenceDate: Date
    ) -> Int {
        let weekStarts = Set(entries.map { weekStart(for: $0.checkInDate) })
        let currentWeekStart = weekStart(for: referenceDate)

        guard weekStarts.contains(currentWeekStart) else {
            return 0
        }

        var streak = 0
        var cursor = currentWeekStart

        while weekStarts.contains(cursor) {
            streak += 1

            guard
                let previousWeek = calendar.date(
                    byAdding: .weekOfYear,
                    value: -1,
                    to: cursor
                )
            else {
                break
            }

            cursor = previousWeek
        }

        return streak
    }

    private func recentWeeklyCheckInCount(
        entries: [ProgressEntry],
        referenceDate: Date,
        weeks: Int
    ) -> Int {
        let weekStarts = Set(entries.map { weekStart(for: $0.checkInDate) })
        let currentWeekStart = weekStart(for: referenceDate)

        return (0..<weeks).reduce(into: 0) { count, offset in
            guard
                let evaluatedWeek = calendar.date(
                    byAdding: .weekOfYear,
                    value: -offset,
                    to: currentWeekStart
                ),
                weekStarts.contains(evaluatedWeek)
            else {
                return
            }

            count += 1
        }
    }

    private func weekStart(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ??
        calendar.startOfDay(for: date)
    }

    private func trendSeries(from points: [ProgressTrendPoint]) -> [ProgressTrendPoint] {
        points.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.value < rhs.value
            }

            return lhs.date < rhs.date
        }
    }

    private func newestFirst(
        _ lhs: ProgressEntry,
        _ rhs: ProgressEntry
    ) -> Bool {
        if lhs.checkInDate == rhs.checkInDate {
            return lhs.id.uuidString > rhs.id.uuidString
        }

        return lhs.checkInDate > rhs.checkInDate
    }

    private func measurementText(_ value: Double, unit: String) -> String {
        "\(formattedNumber(value)) \(unit)"
    }

    private func deltaText(_ value: Double, unit: String) -> String {
        if abs(value) < 0.05 {
            return "No change"
        }

        let sign = value > 0 ? "+" : ""
        return "\(sign)\(formattedNumber(value)) \(unit)"
    }

    private func formattedNumber(_ value: Double) -> String {
        value.formatted(
            .number.precision(.fractionLength(0...1))
        )
    }
}
