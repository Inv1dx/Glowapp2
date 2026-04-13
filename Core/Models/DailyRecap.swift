import Foundation

enum RecapEnergyOutputState: Equatable, Sendable {
    case estimated
    case partial
    case unavailable
}

enum RecapEnergyBalanceState: Equatable, Sendable {
    case deficit
    case surplus
    case neutral
    case unavailable
}

struct DailyRecapInput: Sendable {
    let day: Date
    let evaluatedAt: Date
    let userProfile: UserProfile?
    let metricsSnapshot: MetricsRepositorySnapshot
    let nutritionSummary: NutritionDaySummary
    let routineSummary: RoutineDaySummary
    let glowScore: GlowScore?
}

struct DailyRecapEnergyBalance: Equatable, Sendable {
    let caloriesIn: Int?
    let estimatedCaloriesOut: Int?
    let baselineCaloriesEstimate: Int?
    let activeCalories: Int?
    let outputState: RecapEnergyOutputState
    let balanceState: RecapEnergyBalanceState
    let balanceAmount: Int?
    let caloriesOutExplanation: String
    let balanceExplanation: String
}

struct DailyRecap: Equatable, Sendable {
    let date: Date
    let generatedAt: Date
    let metrics: DailyMetrics?
    let metricsConnectionState: MetricsConnectionState
    let limitedHealthFields: [DailyMetrics.Field]
    let unsupportedHealthFields: [DailyMetrics.Field]
    let nutritionSummary: NutritionDaySummary
    let routineSummary: RoutineDaySummary
    let glowScore: GlowScore?
    let energyBalance: DailyRecapEnergyBalance
    let weakestArea: GlowScoreCategory?
    let summaryMessage: String
    let recommendationText: String
}
