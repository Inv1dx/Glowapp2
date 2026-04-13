import Foundation

struct NutritionDaySummary: Equatable, Sendable {
    let date: Date
    let totalCalories: Int
    let totalProteinGrams: Int
    let totalWaterML: Int

    static func empty(for date: Date) -> NutritionDaySummary {
        NutritionDaySummary(
            date: date,
            totalCalories: 0,
            totalProteinGrams: 0,
            totalWaterML: 0
        )
    }
}
