protocol AnalyticsService {
    func track(eventName: String)
}

struct StubAnalyticsService: AnalyticsService {
    func track(eventName: String) {}
}
