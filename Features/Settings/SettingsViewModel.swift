import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    private let authService: any AuthService
    private let supabaseService: any SupabaseService
    private let relativeDateFormatter: RelativeDateTimeFormatter
    private var cancellables: Set<AnyCancellable> = []

    @Published private(set) var syncStatus: SupabaseSyncStatus

    init(
        authService: any AuthService = StubAuthService(),
        supabaseService: any SupabaseService = StubSupabaseService()
    ) {
        self.authService = authService
        self.supabaseService = supabaseService
        self.syncStatus = supabaseService.status

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        self.relativeDateFormatter = formatter

        supabaseService.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                Task { @MainActor in
                    self?.syncStatus = status
                }
            }
            .store(in: &cancellables)
    }

    var navigationTitle: String {
        "Settings"
    }

    var accountTitle: String {
        switch authService.accountStatus.kind {
        case .stableAnonymous:
            "Anonymous account"
        case .signedIn:
            "Signed in"
        }
    }

    var accountDetail: String {
        "User ID \(authService.accountStatus.shortenedUserId)"
    }

    var accountSystemImage: String {
        authService.isAuthenticated ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle"
    }

    var syncTitle: String {
        switch syncStatus.state {
        case .notConfigured:
            "Backend not configured"
        case .idle:
            "Ready to sync"
        case .syncing:
            "Syncing"
        case .synced:
            "Synced"
        case .failed:
            "Sync needs attention"
        }
    }

    var syncDetail: String {
        switch syncStatus.state {
        case .notConfigured:
            return "Set Supabase URL and anon key before using backend persistence."
        case .idle:
            return "Remote persistence is ready."
        case .syncing:
            return "Saving or loading backend data."
        case .synced:
            if let lastSuccessfulSyncAt = syncStatus.lastSuccessfulSyncAt {
                return "Last synced \(relativeDateFormatter.localizedString(for: lastSuccessfulSyncAt, relativeTo: Date()))."
            }

            return "Last sync completed."
        case .failed:
            return syncStatus.lastErrorMessage ?? "Sync is unavailable. Local fallback is active."
        }
    }

    var syncSystemImage: String {
        switch syncStatus.state {
        case .notConfigured:
            "externaldrive.badge.xmark"
        case .idle:
            "externaldrive"
        case .syncing:
            "arrow.triangle.2.circlepath"
        case .synced:
            "checkmark.icloud.fill"
        case .failed:
            "exclamationmark.icloud.fill"
        }
    }
}
