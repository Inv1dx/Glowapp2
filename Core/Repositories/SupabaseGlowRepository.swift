import Foundation

final class SupabaseGlowRepository: GlowRepository {
    private let supabaseService: any SupabaseService
    private let localRepository: LocalGlowRepository
    private let authService: any AuthService
    private let calendar: Calendar

    init(
        supabaseService: any SupabaseService,
        localRepository: LocalGlowRepository,
        authService: any AuthService,
        calendar: Calendar = .current
    ) {
        self.supabaseService = supabaseService
        self.localRepository = localRepository
        self.authService = authService
        self.calendar = calendar
    }

    func loadScore(for date: Date) async -> GlowScore? {
        do {
            let records = try await supabaseService.select(
                SupabaseGlowScoreRecord.self,
                from: .glowScores,
                filters: [
                    SupabaseRepositorySupport.userFilter(authService.currentUserId),
                    SupabaseRepositorySupport.dateFilter(date, calendar: calendar)
                ],
                order: [],
                limit: 1
            )

            guard let score = try records.first?.makeScore(calendar: calendar) else {
                return await localRepository.loadScore(for: date)
            }

            await localRepository.upsertScore(score)
            return score
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "load glow score")
            return await localRepository.loadScore(for: date)
        }
    }

    func loadScores() async -> [GlowScore] {
        do {
            let records = try await supabaseService.select(
                SupabaseGlowScoreRecord.self,
                from: .glowScores,
                filters: [SupabaseRepositorySupport.userFilter(authService.currentUserId)],
                order: [.descending("date")],
                limit: nil
            )
            let scores = try records.map { try $0.makeScore(calendar: calendar) }
                .sorted { $0.date > $1.date }
            localRepository.cacheRemoteScores(scores)
            return scores
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "load glow score history")
            return await localRepository.loadScores()
        }
    }

    func upsertScore(_ score: GlowScore) async {
        do {
            try await supabaseService.upsert(
                SupabaseGlowScoreRecord(
                    userId: authService.currentUserId,
                    score: score,
                    calendar: calendar
                ),
                into: .glowScores,
                onConflict: ["user_id", "date"]
            )
        } catch {
            SupabaseRepositorySupport.logFallback(error, context: "save glow score")
        }

        await localRepository.upsertScore(score)
    }
}
