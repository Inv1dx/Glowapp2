protocol HealthKitService {
    var isAuthorized: Bool { get }
}

struct StubHealthKitService: HealthKitService {
    let isAuthorized = false
}
