protocol SubscriptionService {
    var hasActiveSubscription: Bool { get }
}

struct StubSubscriptionService: SubscriptionService {
    let hasActiveSubscription = false
}
