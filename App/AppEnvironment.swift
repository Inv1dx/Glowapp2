import SwiftUI

final class AppEnvironment {
    let userRepository: any UserRepository
    let authService: any AuthService
    let healthKitService: any HealthKitService
    let supabaseService: any SupabaseService
    let subscriptionService: any SubscriptionService
    let analyticsService: any AnalyticsService

    init(
        userRepository: any UserRepository = LocalUserRepository(),
        authService: any AuthService = StubAuthService(),
        healthKitService: any HealthKitService = StubHealthKitService(),
        supabaseService: any SupabaseService = StubSupabaseService(),
        subscriptionService: any SubscriptionService = StubSubscriptionService(),
        analyticsService: any AnalyticsService = StubAnalyticsService()
    ) {
        self.userRepository = userRepository
        self.authService = authService
        self.healthKitService = healthKitService
        self.supabaseService = supabaseService
        self.subscriptionService = subscriptionService
        self.analyticsService = analyticsService
    }

    @MainActor
    func makeAppRouter() -> AppRouter {
        AppRouter(userRepository: userRepository)
    }

    @MainActor
    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(userRepository: userRepository)
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
    static let preview = AppEnvironment(
        userRepository: LocalUserRepository(
            userDefaults: UserDefaults(suiteName: "GlowApp.preview") ?? .standard
        )
    )
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
