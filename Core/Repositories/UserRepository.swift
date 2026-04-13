import Foundation

protocol UserRepository {
    func loadUserProfile() async throws -> UserProfile?
    func saveUserProfile(_ profile: UserProfile) async throws
    func clearUserProfile() async throws
}

enum UserRepositoryError: Error, Equatable {
    case invalidProfile([UserProfile.ValidationIssue])
    case failedToEncodeProfile
    case failedToDecodeProfile
}
