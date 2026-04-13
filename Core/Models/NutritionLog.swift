import Foundation

struct NutritionLog: Identifiable, Codable, Equatable, Sendable {
    enum EntryType: String, Codable, Sendable {
        case meal
        case quickCalories
        case quickProtein
        case water
    }

    let id: UUID
    var loggedAt: Date
    var calories: Int
    var proteinGrams: Int
    var waterML: Int
    var entryType: EntryType

    init(
        id: UUID = UUID(),
        loggedAt: Date,
        calories: Int = 0,
        proteinGrams: Int = 0,
        waterML: Int = 0,
        entryType: EntryType
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.waterML = waterML
        self.entryType = entryType
    }

    var hasNutritionContent: Bool {
        calories > 0 || proteinGrams > 0
    }

    var hasWaterContent: Bool {
        waterML > 0
    }
}
