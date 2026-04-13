protocol SupabaseService {
    var isConfigured: Bool { get }
}

struct StubSupabaseService: SupabaseService {
    let isConfigured = false
}
