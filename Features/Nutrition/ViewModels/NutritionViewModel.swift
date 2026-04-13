import Combine
import Foundation

@MainActor
final class NutritionViewModel: ObservableObject {
    struct EditorContext: Identifiable {
        enum Mode {
            case add(entryType: NutritionLog.EntryType)
            case edit(log: NutritionLog)
        }

        let id = UUID()
        let mode: Mode

        var title: String {
            switch mode {
            case .add(let entryType):
                switch entryType {
                case .meal:
                    "Add nutrition"
                case .quickCalories:
                    "Quick add calories"
                case .quickProtein:
                    "Quick add protein"
                case .water:
                    "Add water"
                }
            case .edit:
                "Edit nutrition"
            }
        }

        var initialCalories: Int {
            switch mode {
            case .add:
                0
            case .edit(let log):
                log.calories
            }
        }

        var initialProteinGrams: Int {
            switch mode {
            case .add:
                0
            case .edit(let log):
                log.proteinGrams
            }
        }
    }

    private let nutritionRepository: any NutritionRepository
    private let calendar: Calendar
    private let timeFormatter: DateFormatter
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var entries: [NutritionLog] = []
    @Published private(set) var summary = NutritionDaySummary.empty(for: Date())
    @Published private(set) var hasLoadedOnce = false
    @Published var editorContext: EditorContext?
    @Published private(set) var errorMessage: String?

    init(
        nutritionRepository: any NutritionRepository,
        calendar: Calendar = .current
    ) {
        self.nutritionRepository = nutritionRepository
        self.calendar = calendar

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        self.timeFormatter = formatter

        nutritionRepository.updates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task {
                    await self?.refresh()
                }
            }
            .store(in: &cancellables)
    }

    var sectionTitle: String {
        "Manual logging"
    }

    var sectionSubtitle: String {
        "Keep it fast. Log calories, protein, and water without turning this into a food database."
    }

    var emptyStateMessage: String {
        "No manual logs yet today."
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce || !DayBoundaryFactory.isSameDay(summary.date, Date(), calendar: calendar) else {
            return
        }

        await refresh()
    }

    func refresh() async {
        let date = Date()
        entries = await nutritionRepository.loadEntries(for: date)
        summary = await nutritionRepository.loadSummary(for: date)
        hasLoadedOnce = true
    }

    func presentNutritionEditor() {
        errorMessage = nil
        editorContext = EditorContext(mode: .add(entryType: .meal))
    }

    func presentQuickCaloriesEditor() {
        errorMessage = nil
        editorContext = EditorContext(mode: .add(entryType: .quickCalories))
    }

    func presentQuickProteinEditor() {
        errorMessage = nil
        editorContext = EditorContext(mode: .add(entryType: .quickProtein))
    }

    func presentEditor(for log: NutritionLog) {
        guard log.hasNutritionContent else {
            return
        }

        errorMessage = nil
        editorContext = EditorContext(mode: .edit(log: log))
    }

    func saveEntry(
        context: EditorContext,
        calories: Int,
        proteinGrams: Int
    ) async -> Bool {
        let entryType: NutritionLog.EntryType
        let id: UUID
        let loggedAt: Date

        switch context.mode {
        case .add(let modeEntryType):
            entryType = modeEntryType
            id = UUID()
            loggedAt = Date()
        case .edit(let log):
            entryType = log.entryType
            id = log.id
            loggedAt = log.loggedAt
        }

        do {
            try await nutritionRepository.saveLog(
                NutritionLog(
                    id: id,
                    loggedAt: loggedAt,
                    calories: calories,
                    proteinGrams: proteinGrams,
                    waterML: 0,
                    entryType: entryType
                )
            )
            errorMessage = nil
            editorContext = nil
            return true
        } catch {
            errorMessage = "Couldn't save that nutrition entry."
            return false
        }
    }

    func addWater(amountML: Int) {
        Task {
            do {
                try await nutritionRepository.saveLog(
                    NutritionLog(
                        loggedAt: Date(),
                        calories: 0,
                        proteinGrams: 0,
                        waterML: amountML,
                        entryType: .water
                    )
                )
                errorMessage = nil
            } catch {
                errorMessage = "Couldn't save that water entry."
            }
        }
    }

    func delete(_ log: NutritionLog) {
        Task {
            await nutritionRepository.deleteLog(id: log.id)
        }
    }

    func title(for log: NutritionLog) -> String {
        if log.hasWaterContent {
            return "\(log.waterML.formatted()) mL water"
        }

        if log.calories > 0 && log.proteinGrams > 0 {
            return "\(log.calories.formatted()) kcal • \(log.proteinGrams.formatted()) g protein"
        }

        if log.calories > 0 {
            return "\(log.calories.formatted()) kcal"
        }

        return "\(log.proteinGrams.formatted()) g protein"
    }

    func detail(for log: NutritionLog) -> String {
        let prefix: String

        switch log.entryType {
        case .meal:
            prefix = "Manual entry"
        case .quickCalories:
            prefix = "Quick calories"
        case .quickProtein:
            prefix = "Quick protein"
        case .water:
            prefix = "Water"
        }

        return "\(prefix) • \(timeFormatter.string(from: log.loggedAt))"
    }
}
