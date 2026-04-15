import Combine
import Foundation

enum ProgressRepositoryError: Error, Equatable {
    case invalidEntry
    case photoStorageFailed
}

protocol ProgressRepository: AnyObject {
    var updates: AnyPublisher<Void, Never> { get }

    func fetchAllEntries() async -> [ProgressEntry]
    func fetchEntry(id: UUID) async -> ProgressEntry?
    func addEntry(
        _ entry: ProgressEntry,
        frontPhotoData: Data?,
        sidePhotoData: Data?
    ) async throws -> ProgressEntry
    func updateEntry(
        _ entry: ProgressEntry,
        frontPhotoUpdate: ProgressPhotoUpdate,
        sidePhotoUpdate: ProgressPhotoUpdate
    ) async throws -> ProgressEntry
    func deleteEntry(id: UUID) async
}

final class LocalProgressRepository: ProgressRepository {
    private enum StorageKey {
        static let entries = "glow.progress.entries"
    }

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let calendar: Calendar
    private let photoStorageService: any PhotoStorageService
    private let updatesSubject = PassthroughSubject<Void, Never>()

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        calendar: Calendar = .current,
        photoStorageService: any PhotoStorageService = LocalPhotoStorageService()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.calendar = calendar
        self.photoStorageService = photoStorageService
    }

    var updates: AnyPublisher<Void, Never> {
        updatesSubject.eraseToAnyPublisher()
    }

    func fetchAllEntries() async -> [ProgressEntry] {
        loadAllEntries()
    }

    func fetchEntry(id: UUID) async -> ProgressEntry? {
        loadAllEntries().first { $0.id == id }
    }

    func addEntry(
        _ entry: ProgressEntry,
        frontPhotoData: Data?,
        sidePhotoData: Data?
    ) async throws -> ProgressEntry {
        var storedEntry = normalized(entry)
        guard storedEntry.hasMeaningfulContent else {
            throw ProgressRepositoryError.invalidEntry
        }

        do {
            if let frontPhotoData {
                storedEntry = ProgressEntry(
                    id: storedEntry.id,
                    checkInDate: storedEntry.checkInDate,
                    weightKg: storedEntry.weightKg,
                    waistCm: storedEntry.waistCm,
                    frontPhotoPath: try photoStorageService.savePhotoData(
                        frontPhotoData,
                        entryID: storedEntry.id,
                        role: .front
                    ),
                    sidePhotoPath: storedEntry.sidePhotoPath
                )
            }

            if let sidePhotoData {
                storedEntry = ProgressEntry(
                    id: storedEntry.id,
                    checkInDate: storedEntry.checkInDate,
                    weightKg: storedEntry.weightKg,
                    waistCm: storedEntry.waistCm,
                    frontPhotoPath: storedEntry.frontPhotoPath,
                    sidePhotoPath: try photoStorageService.savePhotoData(
                        sidePhotoData,
                        entryID: storedEntry.id,
                        role: .side
                    )
                )
            }
        } catch {
            try? photoStorageService.deletePhoto(at: storedEntry.frontPhotoPath)
            try? photoStorageService.deletePhoto(at: storedEntry.sidePhotoPath)
            throw ProgressRepositoryError.photoStorageFailed
        }

        var entries = loadAllEntries().filter { $0.id != storedEntry.id }
        entries.append(storedEntry)
        persist(entries)
        updatesSubject.send()
        return storedEntry
    }

    func updateEntry(
        _ entry: ProgressEntry,
        frontPhotoUpdate: ProgressPhotoUpdate,
        sidePhotoUpdate: ProgressPhotoUpdate
    ) async throws -> ProgressEntry {
        let existingEntry = loadAllEntries().first { $0.id == entry.id }
        var storedEntry = normalized(entry)

        do {
            let resolvedFrontPhotoPath = try resolvePhotoPath(
                currentPath: existingEntry?.frontPhotoPath ?? entry.frontPhotoPath,
                update: frontPhotoUpdate,
                entryID: entry.id,
                role: .front
            )
            let resolvedSidePhotoPath = try resolvePhotoPath(
                currentPath: existingEntry?.sidePhotoPath ?? entry.sidePhotoPath,
                update: sidePhotoUpdate,
                entryID: entry.id,
                role: .side
            )

            storedEntry = ProgressEntry(
                id: storedEntry.id,
                checkInDate: storedEntry.checkInDate,
                weightKg: storedEntry.weightKg,
                waistCm: storedEntry.waistCm,
                frontPhotoPath: resolvedFrontPhotoPath,
                sidePhotoPath: resolvedSidePhotoPath
            )
        } catch {
            throw ProgressRepositoryError.photoStorageFailed
        }

        guard storedEntry.hasMeaningfulContent else {
            throw ProgressRepositoryError.invalidEntry
        }

        var entries = loadAllEntries().filter { $0.id != storedEntry.id }
        entries.append(storedEntry)
        persist(entries)
        updatesSubject.send()
        return storedEntry
    }

    func deleteEntry(id: UUID) async {
        let existingEntries = loadAllEntries()
        guard let entry = existingEntries.first(where: { $0.id == id }) else {
            return
        }

        try? photoStorageService.deletePhoto(at: entry.frontPhotoPath)
        try? photoStorageService.deletePhoto(at: entry.sidePhotoPath)

        persist(existingEntries.filter { $0.id != id })
        updatesSubject.send()
    }

    func cacheRemoteEntries(_ entries: [ProgressEntry]) {
        persist(entries)
    }

    func cacheRemoteEntry(_ entry: ProgressEntry) {
        var entries = loadAllEntries().filter { $0.id != entry.id }
        entries.append(entry)
        persist(entries)
    }

    private func resolvePhotoPath(
        currentPath: String?,
        update: ProgressPhotoUpdate,
        entryID: UUID,
        role: ProgressPhotoRole
    ) throws -> String? {
        switch update {
        case .keepCurrent:
            return currentPath

        case .remove:
            try photoStorageService.deletePhoto(at: currentPath)
            return nil

        case .replace(let data):
            let savedPath = try photoStorageService.savePhotoData(
                data,
                entryID: entryID,
                role: role
            )

            if let currentPath, currentPath != savedPath {
                try? photoStorageService.deletePhoto(at: currentPath)
            }

            return savedPath
        }
    }

    private func normalized(_ entry: ProgressEntry) -> ProgressEntry {
        ProgressEntry(
            id: entry.id,
            checkInDate: normalizedCheckInDate(entry.checkInDate),
            weightKg: entry.weightKg,
            waistCm: entry.waistCm,
            frontPhotoPath: entry.frontPhotoPath,
            sidePhotoPath: entry.sidePhotoPath
        )
    }

    private func normalizedCheckInDate(_ date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? startOfDay
    }

    private func loadAllEntries() -> [ProgressEntry] {
        guard
            let data = userDefaults.data(forKey: StorageKey.entries),
            let entries = try? decoder.decode([ProgressEntry].self, from: data)
        else {
            return []
        }

        return entries.sorted(by: newestFirst)
    }

    private func persist(_ entries: [ProgressEntry]) {
        let sortedEntries = entries.sorted(by: newestFirst)

        guard let data = try? encoder.encode(sortedEntries) else {
            return
        }

        userDefaults.set(data, forKey: StorageKey.entries)
    }

    private func newestFirst(_ lhs: ProgressEntry, _ rhs: ProgressEntry) -> Bool {
        if lhs.checkInDate == rhs.checkInDate {
            return lhs.id.uuidString > rhs.id.uuidString
        }

        return lhs.checkInDate > rhs.checkInDate
    }
}
