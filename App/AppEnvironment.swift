import SwiftUI

final class AppEnvironment {
    let userRepository: any UserRepository
    let authService: any AuthService
    let healthKitService: any HealthKitService
    let metricsRepository: any MetricsRepository
    let nutritionRepository: any NutritionRepository
    let routineRepository: any RoutineRepository
    let supabaseService: any SupabaseService
    let subscriptionService: any SubscriptionService
    let analyticsService: any AnalyticsService

    init(
        userRepository: any UserRepository = LocalUserRepository(),
        authService: any AuthService = StubAuthService(),
        healthKitService: any HealthKitService = LiveHealthKitService(),
        metricsRepository: (any MetricsRepository)? = nil,
        nutritionRepository: (any NutritionRepository)? = nil,
        routineRepository: (any RoutineRepository)? = nil,
        supabaseService: any SupabaseService = StubSupabaseService(),
        subscriptionService: any SubscriptionService = StubSubscriptionService(),
        analyticsService: any AnalyticsService = StubAnalyticsService()
    ) {
        self.userRepository = userRepository
        self.authService = authService
        self.healthKitService = healthKitService
        self.metricsRepository = metricsRepository ?? LocalMetricsRepository(
            healthKitService: healthKitService
        )
        self.nutritionRepository = nutritionRepository ?? LocalNutritionRepository()
        self.routineRepository = routineRepository ?? LocalRoutineRepository()
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

    @MainActor
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(metricsRepository: metricsRepository)
    }

    @MainActor
    func makeNutritionViewModel() -> NutritionViewModel {
        NutritionViewModel(nutritionRepository: nutritionRepository)
    }

    @MainActor
    func makeRoutinesViewModel() -> RoutinesViewModel {
        RoutinesViewModel(routineRepository: routineRepository)
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

    static let preview: AppEnvironment = {
        let userDefaults = UserDefaults(suiteName: "GlowApp.preview") ?? .standard
        let healthKitService = StubHealthKitService()

        return AppEnvironment(
            userRepository: LocalUserRepository(userDefaults: userDefaults),
            healthKitService: healthKitService,
            metricsRepository: LocalMetricsRepository(
                healthKitService: healthKitService,
                userDefaults: userDefaults
            ),
            nutritionRepository: LocalNutritionRepository(userDefaults: userDefaults),
            routineRepository: LocalRoutineRepository(userDefaults: userDefaults)
        )
    }()
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
