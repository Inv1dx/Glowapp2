import SwiftUI

final class AppEnvironment {
    let userRepository: any UserRepository
    let authService: any AuthService
    let healthKitService: any HealthKitService
    let metricsRepository: any MetricsRepository
    let nutritionRepository: any NutritionRepository
    let routineRepository: any RoutineRepository
    let glowRepository: any GlowRepository
    let glowPlanRepository: any GlowPlanRepository
    let progressRepository: any ProgressRepository
    let supabaseService: any SupabaseService
    let subscriptionService: any SubscriptionService
    let analyticsService: any AnalyticsService
    let photoStorageService: any PhotoStorageService

    init(
        userRepository: (any UserRepository)? = nil,
        authService: (any AuthService)? = nil,
        healthKitService: any HealthKitService = LiveHealthKitService(),
        metricsRepository: (any MetricsRepository)? = nil,
        nutritionRepository: (any NutritionRepository)? = nil,
        routineRepository: (any RoutineRepository)? = nil,
        glowRepository: (any GlowRepository)? = nil,
        glowPlanRepository: (any GlowPlanRepository)? = nil,
        progressRepository: (any ProgressRepository)? = nil,
        supabaseService: (any SupabaseService)? = nil,
        subscriptionService: any SubscriptionService = StubSubscriptionService(),
        analyticsService: any AnalyticsService = StubAnalyticsService(),
        photoStorageService: (any PhotoStorageService)? = nil
    ) {
        let resolvedAuthService = authService ?? StableAnonymousAuthService()
        let resolvedSupabaseService = supabaseService ?? LiveSupabaseService()
        let resolvedPhotoStorageService = photoStorageService ?? LocalPhotoStorageService()
        let localUserRepository = LocalUserRepository()
        let localMetricsRepository = LocalMetricsRepository(
            healthKitService: healthKitService
        )
        let localNutritionRepository = LocalNutritionRepository()
        let localRoutineRepository = LocalRoutineRepository()
        let localGlowRepository = LocalGlowRepository()
        let localGlowPlanRepository = LocalGlowPlanRepository()
        let localProgressRepository = LocalProgressRepository(
            photoStorageService: resolvedPhotoStorageService
        )

        self.userRepository = userRepository ?? SupabaseUserRepository(
            supabaseService: resolvedSupabaseService,
            localRepository: localUserRepository,
            authService: resolvedAuthService
        )
        self.authService = resolvedAuthService
        self.healthKitService = healthKitService
        self.metricsRepository = metricsRepository ?? SupabaseMetricsRepository(
            supabaseService: resolvedSupabaseService,
            localRepository: localMetricsRepository,
            authService: resolvedAuthService
        )
        self.nutritionRepository = nutritionRepository ?? SupabaseNutritionRepository(
            supabaseService: resolvedSupabaseService,
            localRepository: localNutritionRepository,
            authService: resolvedAuthService
        )
        self.routineRepository = routineRepository ?? SupabaseRoutineRepository(
            supabaseService: resolvedSupabaseService,
            localRepository: localRoutineRepository,
            authService: resolvedAuthService
        )
        self.glowRepository = glowRepository ?? SupabaseGlowRepository(
            supabaseService: resolvedSupabaseService,
            localRepository: localGlowRepository,
            authService: resolvedAuthService
        )
        self.glowPlanRepository = glowPlanRepository ?? SupabaseGlowPlanRepository(
            supabaseService: resolvedSupabaseService,
            localRepository: localGlowPlanRepository,
            authService: resolvedAuthService
        )
        self.progressRepository = progressRepository ?? SupabaseProgressRepository(
            supabaseService: resolvedSupabaseService,
            localRepository: localProgressRepository,
            authService: resolvedAuthService
        )
        self.supabaseService = resolvedSupabaseService
        self.subscriptionService = subscriptionService
        self.analyticsService = analyticsService
        self.photoStorageService = resolvedPhotoStorageService
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

    @MainActor
    func makeGlowScoreViewModel() -> GlowScoreViewModel {
        GlowScoreViewModel(
            userRepository: userRepository,
            glowRepository: glowRepository
        )
    }

    @MainActor
    func makeDailyPlanViewModel() -> DailyPlanViewModel {
        DailyPlanViewModel(
            userRepository: userRepository,
            planRepository: glowPlanRepository
        )
    }

    @MainActor
    func makeRecapViewModel() -> RecapViewModel {
        RecapViewModel(userRepository: userRepository)
    }

    @MainActor
    func makeProgressViewModel() -> ProgressViewModel {
        ProgressViewModel(
            progressRepository: progressRepository,
            glowRepository: glowRepository,
            photoStorageService: photoStorageService
        )
    }

    @MainActor
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            authService: authService,
            supabaseService: supabaseService
        )
    }
}

extension AppEnvironment {
    static let live = AppEnvironment()

    static let preview: AppEnvironment = {
        let userDefaults = UserDefaults(suiteName: "GlowApp.preview") ?? .standard
        let healthKitService = StubHealthKitService()
        let photoStorageService = LocalPhotoStorageService(
            baseDirectoryURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("GlowAppPreview", isDirectory: true)
        )

        return AppEnvironment(
            userRepository: LocalUserRepository(userDefaults: userDefaults),
            authService: StubAuthService(),
            healthKitService: healthKitService,
            metricsRepository: LocalMetricsRepository(
                healthKitService: healthKitService,
                userDefaults: userDefaults
            ),
            nutritionRepository: LocalNutritionRepository(userDefaults: userDefaults),
            routineRepository: LocalRoutineRepository(userDefaults: userDefaults),
            glowRepository: LocalGlowRepository(userDefaults: userDefaults),
            glowPlanRepository: LocalGlowPlanRepository(userDefaults: userDefaults),
            progressRepository: LocalProgressRepository(
                userDefaults: userDefaults,
                photoStorageService: photoStorageService
            ),
            supabaseService: StubSupabaseService(),
            photoStorageService: photoStorageService
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
