import Foundation
import Security

struct AccountStatus: Equatable {
    enum Kind: Equatable {
        case stableAnonymous
        case signedIn
    }

    let userId: String
    let kind: Kind
    let isAuthenticated: Bool

    var shortenedUserId: String {
        guard userId.count > 8 else {
            return userId
        }

        return String(userId.prefix(8))
    }
}

protocol AuthService {
    var isAuthenticated: Bool { get }
    var currentUserId: String { get }
    var accountStatus: AccountStatus { get }
}

final class StableAnonymousAuthService: AuthService {
    private static let fallbackStorageKey = "glow.account.stableAnonymousUserId"

    private let keychainStore: StableAnonymousUserIDStore
    private let userDefaults: UserDefaults
    private let cachedUserId: String

    init(
        keychainStore: StableAnonymousUserIDStore = KeychainStableAnonymousUserIDStore(),
        userDefaults: UserDefaults = .standard
    ) {
        self.keychainStore = keychainStore
        self.userDefaults = userDefaults
        self.cachedUserId = Self.resolveUserId(
            keychainStore: keychainStore,
            userDefaults: userDefaults
        )
    }

    var isAuthenticated: Bool {
        false
    }

    var currentUserId: String {
        cachedUserId
    }

    var accountStatus: AccountStatus {
        AccountStatus(
            userId: currentUserId,
            kind: .stableAnonymous,
            isAuthenticated: isAuthenticated
        )
    }

    private static func resolveUserId(
        keychainStore: StableAnonymousUserIDStore,
        userDefaults: UserDefaults
    ) -> String {
        if let userId = keychainStore.loadUserID() {
            userDefaults.set(userId, forKey: fallbackStorageKey)
            return userId
        }

        if let userId = userDefaults.string(forKey: fallbackStorageKey),
           !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? keychainStore.saveUserID(userId)
            return userId
        }

        let userId = UUID().uuidString.lowercased()
        try? keychainStore.saveUserID(userId)
        userDefaults.set(userId, forKey: fallbackStorageKey)
        return userId
    }
}

struct StubAuthService: AuthService {
    let isAuthenticated: Bool
    let currentUserId: String

    init(
        isAuthenticated: Bool = false,
        currentUserId: String = "preview-user"
    ) {
        self.isAuthenticated = isAuthenticated
        self.currentUserId = currentUserId
    }

    var accountStatus: AccountStatus {
        AccountStatus(
            userId: currentUserId,
            kind: isAuthenticated ? .signedIn : .stableAnonymous,
            isAuthenticated: isAuthenticated
        )
    }
}

protocol StableAnonymousUserIDStore {
    func loadUserID() -> String?
    func saveUserID(_ userID: String) throws
}

enum StableAnonymousUserIDStoreError: Error {
    case unexpectedStatus(OSStatus)
}

struct KeychainStableAnonymousUserIDStore: StableAnonymousUserIDStore {
    private let service = "com.example.GlowApp.account"
    private let account = "stableAnonymousUserId"

    func loadUserID() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let userID = String(data: data, encoding: .utf8),
              !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return userID
    }

    func saveUserID(_ userID: String) throws {
        guard let data = userID.data(using: .utf8) else {
            return
        }

        var query = baseQuery()
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw StableAnonymousUserIDStoreError.unexpectedStatus(updateStatus)
        }

        query.merge(attributes) { _, newValue in newValue }
        let addStatus = SecItemAdd(query as CFDictionary, nil)

        guard addStatus == errSecSuccess else {
            throw StableAnonymousUserIDStoreError.unexpectedStatus(addStatus)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
