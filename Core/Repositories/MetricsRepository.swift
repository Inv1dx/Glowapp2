import Foundation

enum MetricsConnectionState: String, Codable, Sendable {
    case unavailable
    case notConnected
    case connected
    case needsAttention
}

enum MetricsSnapshotSource: String, Codable, Sendable {
    case live
    case cache
    case none
}

struct MetricsRepositorySnapshot: Sendable {
    let metrics: DailyMetrics?
    let connectionState: MetricsConnectionState
    let source: MetricsSnapshotSource
    let limitedFields: [DailyMetrics.Field]
    let unsupportedFields: [DailyMetrics.Field]
    let lastUpdatedAt: Date?

    static let empty = MetricsRepositorySnapshot(
        metrics: nil,
        connectionState: .notConnected,
        source: .none,
        limitedFields: [],
        unsupportedFields: [],
        lastUpdatedAt: nil
    )
}

protocol MetricsRepository {
    func loadCurrentDaySnapshot() async -> MetricsRepositorySnapshot
    func refreshCurrentDaySnapshot() async -> MetricsRepositorySnapshot
    func requestHealthAccess() async -> MetricsRepositorySnapshot
}

final class LocalMetricsRepository: MetricsRepository {
    private enum StorageKey {
        static let cachedDailyMetrics = "glow.metrics.cachedDailyMetrics"
        static let hasRequestedHealthAccess = "glow.metrics.hasRequestedHealthAccess"
    }

    private let healthKitService: any HealthKitService
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let calendar: Calendar

    init(
        healthKitService: any HealthKitService,
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        calendar: Calendar = .current
    ) {
        self.healthKitService = healthKitService
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.calendar = calendar
    }

    func loadCurrentDaySnapshot() async -> MetricsRepositorySnapshot {
        await liveSnapshotWithCacheFallback()
    }

    func refreshCurrentDaySnapshot() async -> MetricsRepositorySnapshot {
        await liveSnapshotWithCacheFallback()
    }

    func requestHealthAccess() async -> MetricsRepositorySnapshot {
        guard healthKitService.isAvailable else {
            return MetricsRepositorySnapshot(
                metrics: nil,
                connectionState: .unavailable,
                source: .none,
                limitedFields: [],
                unsupportedFields: [],
                lastUpdatedAt: nil
            )
        }

        do {
            try await healthKitService.requestReadAuthorization()
            userDefaults.set(true, forKey: StorageKey.hasRequestedHealthAccess)
        } catch {
            return await liveSnapshotWithCacheFallback()
        }

        return await liveSnapshotWithCacheFallback()
    }

    func cacheRemoteSnapshot(_ snapshot: MetricsRepositorySnapshot) {
        persist(snapshot)
    }

    private func liveSnapshotWithCacheFallback() async -> MetricsRepositorySnapshot {
        let cachedRecord = loadCurrentDayCacheRecord()

        switch await healthKitService.authorizationPhase() {
        case .unavailable:
            return MetricsRepositorySnapshot(
                metrics: cachedRecord?.metrics,
                connectionState: .unavailable,
                source: cachedRecord == nil ? .none : .cache,
                limitedFields: cachedRecord?.limitedFields ?? [],
                unsupportedFields: cachedRecord?.unsupportedFields ?? [],
                lastUpdatedAt: cachedRecord?.updatedAt
            )

        case .shouldRequest:
            return MetricsRepositorySnapshot(
                metrics: nil,
                connectionState: .notConnected,
                source: .none,
                limitedFields: [],
                unsupportedFields: [],
                lastUpdatedAt: nil
            )

        case .unknown:
            return cachedSnapshot(from: cachedRecord) ?? MetricsRepositorySnapshot(
                metrics: nil,
                connectionState: .needsAttention,
                source: .none,
                limitedFields: [],
                unsupportedFields: [],
                lastUpdatedAt: nil
            )

        case .requestCompleted:
            let payload = await healthKitService.fetchDailyMetrics(for: Date())
            let supportedFields = payload.supportedFields
            let limitedFields = orderedFields(from: limitedFieldSet(from: payload))
            let unsupportedFields = orderedFields(from: payload.unsupportedFields)

            if !supportedFields.isEmpty &&
                payload.queryFailureFields.count == supportedFields.count &&
                cachedRecord != nil {
                return cachedSnapshot(from: cachedRecord) ?? MetricsRepositorySnapshot.empty
            }

            let connectionState = connectionState(
                for: payload,
                cachedRecord: cachedRecord
            )

            let snapshot = MetricsRepositorySnapshot(
                metrics: payload.dailyMetrics,
                connectionState: connectionState,
                source: .live,
                limitedFields: limitedFields,
                unsupportedFields: unsupportedFields,
                lastUpdatedAt: Date()
            )

            persist(snapshot)
            return snapshot
        }
    }

    private func connectionState(
        for payload: HealthKitMetricsPayload,
        cachedRecord: MetricsCacheRecord?
    ) -> MetricsConnectionState {
        let limitedFields = limitedFieldSet(from: payload)
        let supportedFields = payload.supportedFields

        if !supportedFields.isEmpty &&
            limitedFields.intersection(supportedFields).count == supportedFields.count {
            return .needsAttention
        }

        let hasRequestedHealthAccess = userDefaults.bool(
            forKey: StorageKey.hasRequestedHealthAccess
        )

        if hasRequestedHealthAccess &&
            !payload.dailyMetrics.hasAnyValue &&
            cachedRecord == nil {
            return .needsAttention
        }

        return .connected
    }

    private func limitedFieldSet(from payload: HealthKitMetricsPayload) -> Set<DailyMetrics.Field> {
        let authorizationLimitedFields = payload.authorizationStates.compactMap { field, state in
            switch state {
            case .denied, .notDetermined:
                field
            case .authorized, .unavailableType:
                nil
            }
        }

        return Set(authorizationLimitedFields).union(payload.queryFailureFields)
    }

    private func persist(_ snapshot: MetricsRepositorySnapshot) {
        guard let metrics = snapshot.metrics else {
            return
        }

        let record = MetricsCacheRecord(
            metrics: metrics,
            connectionState: snapshot.connectionState,
            limitedFields: snapshot.limitedFields,
            unsupportedFields: snapshot.unsupportedFields,
            updatedAt: snapshot.lastUpdatedAt ?? Date()
        )

        guard let data = try? encoder.encode(record) else {
            return
        }

        userDefaults.set(data, forKey: StorageKey.cachedDailyMetrics)
    }

    private func cachedSnapshot(from record: MetricsCacheRecord?) -> MetricsRepositorySnapshot? {
        guard let record else {
            return nil
        }

        return MetricsRepositorySnapshot(
            metrics: record.metrics,
            connectionState: record.connectionState,
            source: .cache,
            limitedFields: record.limitedFields,
            unsupportedFields: record.unsupportedFields,
            lastUpdatedAt: record.updatedAt
        )
    }

    private func loadCurrentDayCacheRecord() -> MetricsCacheRecord? {
        guard
            let data = userDefaults.data(forKey: StorageKey.cachedDailyMetrics),
            let record = try? decoder.decode(MetricsCacheRecord.self, from: data),
            DayBoundaryFactory.isSameDay(record.metrics.date, Date(), calendar: calendar)
        else {
            return nil
        }

        return record
    }

    private func orderedFields(from fields: Set<DailyMetrics.Field>) -> [DailyMetrics.Field] {
        DailyMetrics.Field.allCases.filter { fields.contains($0) }
    }
}

private struct MetricsCacheRecord: Codable {
    let metrics: DailyMetrics
    let connectionState: MetricsConnectionState
    let limitedFields: [DailyMetrics.Field]
    let unsupportedFields: [DailyMetrics.Field]
    let updatedAt: Date
}
