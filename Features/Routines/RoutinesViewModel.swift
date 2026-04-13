import Combine
import Foundation

@MainActor
final class RoutinesViewModel: ObservableObject {
    private let routineRepository: any RoutineRepository
    private let calendar: Calendar
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var summary = RoutineDaySummary.empty(for: Date())
    @Published private(set) var hasLoadedOnce = false

    init(
        routineRepository: any RoutineRepository,
        calendar: Calendar = .current
    ) {
        self.routineRepository = routineRepository
        self.calendar = calendar

        routineRepository.updates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task {
                    await self?.refresh()
                }
            }
            .store(in: &cancellables)
    }

    var navigationTitle: String {
        "Routines"
    }

    var title: String {
        "Today's consistency basics"
    }

    var subtitle: String {
        "Track the three repeatables that matter for Stage 4: AM, PM, and grooming."
    }

    var statuses: [RoutineDaySummary.Status] {
        summary.statuses
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce || !DayBoundaryFactory.isSameDay(summary.date, Date(), calendar: calendar) else {
            return
        }

        await refresh()
    }

    func refresh() async {
        summary = await routineRepository.loadSummary(for: Date())
        hasLoadedOnce = true
    }

    func toggleCompletion(for template: RoutineTemplate) {
        let status = summary.status(for: template)

        Task {
            await routineRepository.setCompleted(!status.isCompleted, for: template, on: Date())
        }
    }

    func detailText(for status: RoutineDaySummary.Status) -> String {
        if status.isCompleted {
            return "Done today"
        }

        return "Not done yet"
    }

    func streakText(for status: RoutineDaySummary.Status) -> String {
        if status.streakCount == 1 {
            return "1-day streak"
        }

        return "\(status.streakCount.formatted())-day streak"
    }
}
