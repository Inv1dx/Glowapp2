import XCTest
@testable import GlowApp

final class MetricsRepositoryTests: XCTestCase {
    func testAuthorizationPromptStillNeededShowsNotConnectedState() async {
        let repository = makeRepository(
            service: MockHealthKitService(
                authorizationPhaseValue: .shouldRequest,
                payload: Self.livePayload()
            )
        )

        let snapshot = await repository.loadCurrentDaySnapshot()

        XCTAssertEqual(snapshot.connectionState, .notConnected)
        XCTAssertNil(snapshot.metrics)
        XCTAssertEqual(snapshot.source, .none)
    }

    func testLiveMetricsAreCachedAndReturnedWhenQueriesFailLater() async {
        let service = MockHealthKitService(
            authorizationPhaseValue: .requestCompleted,
            payload: Self.livePayload()
        )
        let repository = makeRepository(service: service)

        let liveSnapshot = await repository.loadCurrentDaySnapshot()
        XCTAssertEqual(liveSnapshot.source, .live)
        XCTAssertEqual(liveSnapshot.metrics?.steps, 9_876)

        service.payload = Self.failedPayload()

        let cachedSnapshot = await repository.refreshCurrentDaySnapshot()

        XCTAssertEqual(cachedSnapshot.source, .cache)
        XCTAssertEqual(cachedSnapshot.metrics?.steps, 9_876)
        XCTAssertEqual(cachedSnapshot.connectionState, .connected)
    }

    func testRequestHealthAccessReturnsNeedsAttentionWhenAllSupportedFieldsAreDenied() async {
        let service = MockHealthKitService(
            authorizationPhaseValue: .shouldRequest,
            payload: Self.deniedPayload()
        )
        let repository = makeRepository(service: service)

        let snapshot = await repository.requestHealthAccess()

        XCTAssertEqual(snapshot.connectionState, .needsAttention)
        XCTAssertEqual(snapshot.source, .live)
    }

    private func makeRepository(
        service: MockHealthKitService
    ) -> LocalMetricsRepository {
        let suiteName = "GlowApp.metrics-tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)

        return LocalMetricsRepository(
            healthKitService: service,
            userDefaults: userDefaults
        )
    }

    private static func livePayload() -> HealthKitMetricsPayload {
        let date = DayBoundaryFactory.day(for: Date()).start

        return HealthKitMetricsPayload(
            dailyMetrics: DailyMetrics(
                date: date,
                steps: 9_876,
                activeCalories: 521,
                workoutsCount: 1,
                sleepDurationHours: 7.8,
                weightKg: 72.3
            ),
            supportedFields: Set(DailyMetrics.Field.allCases),
            unsupportedFields: [],
            authorizationStates: Dictionary(
                uniqueKeysWithValues: DailyMetrics.Field.allCases.map { ($0, .authorized) }
            ),
            queryFailureFields: []
        )
    }

    private static func failedPayload() -> HealthKitMetricsPayload {
        let date = DayBoundaryFactory.day(for: Date()).start
        let supportedFields = Set(DailyMetrics.Field.allCases)

        return HealthKitMetricsPayload(
            dailyMetrics: DailyMetrics.empty(for: date),
            supportedFields: supportedFields,
            unsupportedFields: [],
            authorizationStates: Dictionary(
                uniqueKeysWithValues: DailyMetrics.Field.allCases.map { ($0, .authorized) }
            ),
            queryFailureFields: supportedFields
        )
    }

    private static func deniedPayload() -> HealthKitMetricsPayload {
        let date = DayBoundaryFactory.day(for: Date()).start

        return HealthKitMetricsPayload(
            dailyMetrics: DailyMetrics.empty(for: date),
            supportedFields: Set(DailyMetrics.Field.allCases),
            unsupportedFields: [],
            authorizationStates: Dictionary(
                uniqueKeysWithValues: DailyMetrics.Field.allCases.map { ($0, .denied) }
            ),
            queryFailureFields: []
        )
    }
}

private final class MockHealthKitService: HealthKitService {
    var isAvailable = true
    var authorizationPhaseValue: HealthKitAuthorizationPhase
    var payload: HealthKitMetricsPayload

    init(
        authorizationPhaseValue: HealthKitAuthorizationPhase,
        payload: HealthKitMetricsPayload
    ) {
        self.authorizationPhaseValue = authorizationPhaseValue
        self.payload = payload
    }

    func authorizationPhase() async -> HealthKitAuthorizationPhase {
        authorizationPhaseValue
    }

    func requestReadAuthorization() async throws {
        authorizationPhaseValue = .requestCompleted
    }

    func fetchDailyMetrics(for date: Date) async -> HealthKitMetricsPayload {
        payload
    }
}
