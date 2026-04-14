import Combine
import Foundation

@MainActor
final class ProgressViewModel: ObservableObject {
    struct EditorContext: Identifiable {
        enum Mode {
            case add
            case edit(ProgressEntry)
        }

        let id = UUID()
        let mode: Mode
    }

    struct DeleteRequest: Identifiable {
        let entry: ProgressEntry

        var id: UUID { entry.id }
    }

    private let progressRepository: any ProgressRepository
    private let glowRepository: any GlowRepository
    private let photoStorageService: any PhotoStorageService
    private let insightsBuilder: ProgressInsightsBuilder
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var entries: [ProgressEntry] = []
    @Published private(set) var glowScores: [GlowScore] = []
    @Published private(set) var hasLoadedOnce = false
    @Published var editorContext: EditorContext?
    @Published var deleteRequest: DeleteRequest?

    init(
        progressRepository: any ProgressRepository,
        glowRepository: any GlowRepository,
        photoStorageService: any PhotoStorageService,
        calendar: Calendar = .current
    ) {
        self.progressRepository = progressRepository
        self.glowRepository = glowRepository
        self.photoStorageService = photoStorageService
        self.insightsBuilder = ProgressInsightsBuilder(calendar: calendar)

        progressRepository.updates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task {
                    await self?.refreshEntries()
                }
            }
            .store(in: &cancellables)
    }

    var navigationTitle: String {
        "Progress"
    }

    var title: String {
        "Weekly proof that it’s working"
    }

    var subtitle: String {
        "Track weight, waist, and optional photos without turning progress into a body-scanning feature."
    }

    var addButtonTitle: String {
        entries.isEmpty ? "Add first check-in" : "Add weekly check-in"
    }

    var insights: ProgressInsights {
        insightsBuilder.build(entries: entries, glowScores: glowScores)
    }

    var photoStorage: any PhotoStorageService {
        photoStorageService
    }

    func load() async {
        await refresh()
    }

    func refresh() async {
        await refreshEntries()
        glowScores = await glowRepository.loadScores()
        hasLoadedOnce = true
    }

    func presentAddEntry() {
        editorContext = EditorContext(mode: .add)
    }

    func presentEditEntry(_ entry: ProgressEntry) {
        editorContext = EditorContext(mode: .edit(entry))
    }

    func makeEditorViewModel(for context: EditorContext) -> ProgressEntryEditorViewModel {
        let editorMode: ProgressEntryEditorViewModel.Mode

        switch context.mode {
        case .add:
            editorMode = .add
        case .edit(let entry):
            editorMode = .edit(entry)
        }

        return ProgressEntryEditorViewModel(
            mode: editorMode,
            progressRepository: progressRepository,
            photoStorageService: photoStorageService
        )
    }

    func requestDelete(_ entry: ProgressEntry) {
        deleteRequest = DeleteRequest(entry: entry)
    }

    func confirmDeletion() {
        guard let entry = deleteRequest?.entry else {
            return
        }

        deleteRequest = nil

        Task {
            await progressRepository.deleteEntry(id: entry.id)
        }
    }

    private func refreshEntries() async {
        entries = await progressRepository.fetchAllEntries()
    }
}
