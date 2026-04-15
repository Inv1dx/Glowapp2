import Foundation

enum SupabaseRepositorySupport {
    static func logFallback(_ error: Error, context: String) {
        #if DEBUG
        if let supabaseError = error as? SupabaseServiceError {
            print("Glow sync fallback (\(context)): \(supabaseError.safeMessage)")
        } else {
            print("Glow sync fallback (\(context)): \(error.localizedDescription)")
        }
        #endif
    }

    static func userFilter(_ userId: String) -> SupabaseQueryFilter {
        .equal("user_id", userId)
    }

    static func dateFilter(_ date: Date, calendar: Calendar) -> SupabaseQueryFilter {
        .equal("date", SupabaseDateCoding.dayString(from: date, calendar: calendar))
    }
}
