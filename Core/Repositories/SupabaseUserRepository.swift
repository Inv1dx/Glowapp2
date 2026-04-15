import Foundation

final class SupabaseUserRepository: UserRepository {
    private let supabaseService: any SupabaseService
    private let localRepository: LocalUserRepository
    private let authService: any AuthService

    init(
        supabaseService: any SupabaseService,
        localRepository: LocalUserRepository,
        authService: any AuthService
    ) {
        self.supabaseService = supabaseService
        self.localRepository = localRepository
        self.authService = authService
    }

    func loadUserProfile() async throws -> UserProfile? {
        do {
            let records = try await supabaseService.select(
                SupabaseUserProfileRecord.self,
                from: .userProfiles,
                filters: [SupabaseRepositorySupport.userFilter(authService.currentUserId)],
                order: [],
                limit: 1
            )

            guard let profile = try records.first?.makeProfile() else {
                return try await localRepository.loadUserProfile()
            }

            try await localRepository.saveUserProfile(profile)
            return profile
        } catch let error as UserRepositoryError {
            throw error
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "load user profile")
            return try await localRepository.loadUserProfile()
        }
    }

    func saveUserProfile(_ profile: UserProfile) async throws {
        guard profile.isValid else {
            throw UserRepositoryError.invalidProfile(profile.validationIssues)
        }

        let record = SupabaseUserProfileRecord(
            userId: authService.currentUserId,
            profile: profile
        )

        do {
            try await supabaseService.upsert(
                record,
                into: .userProfiles,
                onConflict: ["user_id"]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "save user profile")
        }

        try await localRepository.saveUserProfile(profile)
    }

    func clearUserProfile() async throws {
        do {
            try await supabaseService.delete(
                from: .userProfiles,
                filters: [SupabaseRepositorySupport.userFilter(authService.currentUserId)]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "clear user profile")
        }

        try await localRepository.clearUserProfile()
    }
}
