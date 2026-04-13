protocol AuthService {
    var isAuthenticated: Bool { get }
}

struct StubAuthService: AuthService {
    let isAuthenticated = false
}
