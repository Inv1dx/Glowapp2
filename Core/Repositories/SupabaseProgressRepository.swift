import Combine
import Foundation

final class SupabaseProgressRepository: ProgressRepository {
    private let supabaseService: any SupabaseService
    private let localRepository: LocalProgressRepository
    private let authService: any AuthService
    private let calendar: Calendar

    init(
        supabaseService: any SupabaseService,
        localRepository: LocalProgressRepository,
        authService: any AuthService,
        calendar: Calendar = .current
    ) {
        self.supabaseService = supabaseService
        self.localRepository = localRepository
        self.authService = authService
        self.calendar = calendar
    }

    var updates: AnyPublisher<Void, Never> {
        localRepository.updates
    }

    func fetchAllEntries() async -> [ProgressEntry] {
        do {
            let records = try await supabaseService.select(
                SupabaseProgressEntryRecord.self,
                from: .progressEntries,
                filters: [SupabaseRepositorySupport.userFilter(authService.currentUserId)],
                order: [.descending("check_in_date")],
                limit: nil
            )
            let entries = try records.map { try $0.makeEntry(calendar: calendar) }
                .sorted(by: newestFirst)
            localRepository.cacheRemoteEntries(entries)
            return entries
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "load progress entries")
            return await localRepository.fetchAllEntries()
        }
    }

    func fetchEntry(id: UUID) async -> ProgressEntry? {
        do {
            let records = try await supabaseService.select(
                SupabaseProgressEntryRecord.self,
                from: .progressEntries,
                filters: [
                    SupabaseRepositorySupport.userFilter(authService.currentUserId),
                    .equal("id", id.uuidString.lowercased())
                ],
                order: [],
                limit: 1
            )

            guard let entry = try records.first?.makeEntry(calendar: calendar) else {
                return await localRepository.fetchEntry(id: id)
            }

            localRepository.cacheRemoteEntry(entry)
            return entry
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "load progress entry")
            return await localRepository.fetchEntry(id: id)
        }
    }

    func addEntry(
        _ entry: ProgressEntry,
        frontPhotoData: Data?,
        sidePhotoData: Data?
    ) async throws -> ProgressEntry {
        let storedEntry = try await localRepository.addEntry(
            entry,
            frontPhotoData: frontPhotoData,
            sidePhotoData: sidePhotoData
        )
        await persist(storedEntry, context: "save progress entry")
        return storedEntry
    }

    func updateEntry(
        _ entry: ProgressEntry,
        frontPhotoUpdate: ProgressPhotoUpdate,
        sidePhotoUpdate: ProgressPhotoUpdate
    ) async throws -> ProgressEntry {
        let storedEntry = try await localRepository.updateEntry(
            entry,
            frontPhotoUpdate: frontPhotoUpdate,
            sidePhotoUpdate: sidePhotoUpdate
        )
        await persist(storedEntry, context: "update progress entry")
        return storedEntry
    }

    func deleteEntry(id: UUID) async {
        do {
            try await supabaseService.delete(
                from: .progressEntries,
                filters: [
                    SupabaseRepositorySupport.userFilter(authService.currentUserId),
                    .equal("id", id.uuidString.lowercased())
                ]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "delete progress entry")
        }

        await localRepository.deleteEntry(id: id)
    }

    private func persist(_ entry: ProgressEntry, context: String) async {
        do {
            try await supabaseService.upsert(
                SupabaseProgressEntryRecord(
                    userId: authService.currentUserId,
                    entry: entry,
                    calendar: calendar
                ),
                into: .progressEntries,
                onConflict: ["id"]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: context)
        }
    }

    private func newestFirst(_ lhs: ProgressEntry, _ rhs: ProgressEntry) -> Bool {
        if lhs.checkInDate == rhs.checkInDate {
            return lhs.id.uuidString > rhs.id.uuidString
        }

        return lhs.checkInDate > rhs.checkInDate
    }
}
