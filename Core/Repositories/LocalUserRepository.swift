import Foundation

final class LocalUserRepository: UserRepository {
    private enum StorageKey {
        static let userProfile = "glow.userProfile"
    }

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }

    func loadUserProfile() async throws -> UserProfile? {
        guard let data = userDefaults.data(forKey: StorageKey.userProfile) else {
            return nil
        }

        do {
            return try decoder.decode(UserProfile.self, from: data)
        } catch {
            throw UserRepositoryError.failedToDecodeProfile
        }
    }

    func saveUserProfile(_ profile: UserProfile) async throws {
        guard profile.isValid else {
            throw UserRepositoryError.invalidProfile(profile.validationIssues)
        }

        do {
            let data = try encoder.encode(profile)
            userDefaults.set(data, forKey: StorageKey.userProfile)
        } catch {
            throw UserRepositoryError.failedToEncodeProfile
        }
    }

    func clearUserProfile() async throws {
        userDefaults.removeObject(forKey: StorageKey.userProfile)
    }
}
