import SwiftUI

final class AppEnvironment {
    let authService: any AuthService
    let healthKitService: any HealthKitService
    let supabaseService: any SupabaseService
    let subscriptionService: any SubscriptionService
    let analyticsService: any AnalyticsService

    init(
        authService: any AuthService = StubAuthService(),
        healthKitService: any HealthKitService = StubHealthKitService(),
        supabaseService: any SupabaseService = StubSupabaseService(),
        subscriptionService: any SubscriptionService = StubSubscriptionService(),
        analyticsService: any AnalyticsService = StubAnalyticsService()
    ) {
        self.authService = authService
        self.healthKitService = healthKitService
        self.supabaseService = supabaseService
        self.subscriptionService = subscriptionService
        self.analyticsService = analyticsService
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel()
    }

    func makeRoutinesViewModel() -> RoutinesViewModel {
        RoutinesViewModel()
    }

    func makeProgressViewModel() -> ProgressViewModel {
        ProgressViewModel()
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel()
    }
}

extension AppEnvironment {
    static let live = AppEnvironment()
    static let preview = AppEnvironment()
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.preview
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
