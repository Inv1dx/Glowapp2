import Foundation
import HealthKit

enum HealthKitAuthorizationPhase: Sendable {
    case unavailable
    case shouldRequest
    case requestCompleted
    case unknown
}

enum HealthKitObjectAuthorizationState: String, Codable, Sendable {
    case notDetermined
    case denied
    case authorized
    case unavailableType
}

struct HealthKitMetricsPayload: Sendable {
    let dailyMetrics: DailyMetrics
    let supportedFields: Set<DailyMetrics.Field>
    let unsupportedFields: Set<DailyMetrics.Field>
    let authorizationStates: [DailyMetrics.Field: HealthKitObjectAuthorizationState]
    let queryFailureFields: Set<DailyMetrics.Field>
}

protocol HealthKitService {
    var isAvailable: Bool { get }
    func authorizationPhase() async -> HealthKitAuthorizationPhase
    func requestReadAuthorization() async throws
    func fetchDailyMetrics(for date: Date) async -> HealthKitMetricsPayload
}

final class LiveHealthKitService: HealthKitService {
    private let healthStore: HKHealthStore
    private let calendar: Calendar

    init(
        healthStore: HKHealthStore = HKHealthStore(),
        calendar: Calendar = .current
    ) {
        self.healthStore = healthStore
        self.calendar = calendar
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func authorizationPhase() async -> HealthKitAuthorizationPhase {
        guard isAvailable else {
            return .unavailable
        }

        do {
            let status = try await healthStore.statusForAuthorizationRequest(
                toShare: [],
                read: readableTypes
            )

            switch status {
            case .shouldRequest:
                return .shouldRequest
            case .unnecessary:
                return .requestCompleted
            case .unknown:
                return .unknown
            @unknown default:
                return .unknown
            }
        } catch {
            return .unknown
        }
    }

    func requestReadAuthorization() async throws {
        guard isAvailable else {
            return
        }

        try await healthStore.requestAuthorization(
            toShare: [],
            read: readableTypes
        )
    }

    func fetchDailyMetrics(for date: Date) async -> HealthKitMetricsPayload {
        let dayBoundary = DayBoundaryFactory.day(for: date, calendar: calendar)
        let supportedFields = Set(objectTypesByField.keys)
        let unsupportedFields = Set(DailyMetrics.Field.allCases).subtracting(supportedFields)
        let authorizationStates = buildAuthorizationStates()
        var queryFailureFields = Set<DailyMetrics.Field>()

        async let steps = querySteps(for: dayBoundary)
        async let activeCalories = queryActiveCalories(for: dayBoundary)
        async let workoutsCount = queryWorkoutsCount(for: dayBoundary)
        async let sleepDuration = querySleepDuration(for: dayBoundary)
        async let latestWeight = queryLatestWeight()

        let stepsResult = await steps
        if !stepsResult.didSucceed {
            queryFailureFields.insert(.steps)
        }

        let activeCaloriesResult = await activeCalories
        if !activeCaloriesResult.didSucceed {
            queryFailureFields.insert(.activeCalories)
        }

        let workoutsCountResult = await workoutsCount
        if !workoutsCountResult.didSucceed {
            queryFailureFields.insert(.workoutsCount)
        }

        let sleepDurationResult = await sleepDuration
        if !sleepDurationResult.didSucceed {
            queryFailureFields.insert(.sleepDurationHours)
        }

        let latestWeightResult = await latestWeight
        if !latestWeightResult.didSucceed {
            queryFailureFields.insert(.weightKg)
        }

        let dailyMetrics = DailyMetrics(
            date: dayBoundary.start,
            steps: stepsResult.value ?? 0,
            activeCalories: activeCaloriesResult.value ?? 0,
            workoutsCount: workoutsCountResult.value ?? 0,
            sleepDurationHours: sleepDurationResult.value,
            weightKg: latestWeightResult.value
        )

        return HealthKitMetricsPayload(
            dailyMetrics: dailyMetrics,
            supportedFields: supportedFields,
            unsupportedFields: unsupportedFields,
            authorizationStates: authorizationStates,
            queryFailureFields: queryFailureFields
        )
    }

    private var readableTypes: Set<HKObjectType> {
        Set(objectTypesByField.values)
    }

    private var objectTypesByField: [DailyMetrics.Field: HKObjectType] {
        var types: [DailyMetrics.Field: HKObjectType] = [:]

        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types[.steps] = steps
        }

        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types[.activeCalories] = activeEnergy
        }

        types[.workoutsCount] = HKObjectType.workoutType()

        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types[.sleepDurationHours] = sleep
        }

        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types[.weightKg] = bodyMass
        }

        return types
    }

    private func buildAuthorizationStates() -> [DailyMetrics.Field: HealthKitObjectAuthorizationState] {
        var states: [DailyMetrics.Field: HealthKitObjectAuthorizationState] = [:]

        for field in DailyMetrics.Field.allCases {
            guard let objectType = objectTypesByField[field] else {
                states[field] = .unavailableType
                continue
            }

            switch healthStore.authorizationStatus(for: objectType) {
            case .notDetermined:
                states[field] = .notDetermined
            case .sharingDenied:
                states[field] = .denied
            case .sharingAuthorized:
                states[field] = .authorized
            @unknown default:
                states[field] = .notDetermined
            }
        }

        return states
    }

    private func querySteps(for dayBoundary: DayBoundary) async -> QueryResult<Int> {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return QueryResult(value: nil, didSucceed: false)
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dayBoundary.start,
            end: dayBoundary.end,
            options: .strictStartDate
        )

        let result = await sumQuantity(
            of: quantityType,
            unit: .count(),
            predicate: predicate
        )

        guard result.didSucceed else {
            return QueryResult(value: nil, didSucceed: false)
        }

        return QueryResult(value: Int(result.value?.rounded() ?? 0), didSucceed: true)
    }

    private func queryActiveCalories(for dayBoundary: DayBoundary) async -> QueryResult<Double> {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return QueryResult(value: nil, didSucceed: false)
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: dayBoundary.start,
            end: dayBoundary.end,
            options: .strictStartDate
        )

        return await sumQuantity(
            of: quantityType,
            unit: .kilocalorie(),
            predicate: predicate
        )
    }

    private func queryWorkoutsCount(for dayBoundary: DayBoundary) async -> QueryResult<Int> {
        let predicate = HKQuery.predicateForSamples(
            withStart: dayBoundary.start,
            end: dayBoundary.end,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                guard error == nil else {
                    continuation.resume(returning: QueryResult(value: nil, didSucceed: false))
                    return
                }

                continuation.resume(
                    returning: QueryResult(value: samples?.count ?? 0, didSucceed: true)
                )
            }

            healthStore.execute(query)
        }
    }

    private func querySleepDuration(for dayBoundary: DayBoundary) async -> QueryResult<Double> {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return QueryResult(value: nil, didSucceed: false)
        }

        // MVP assumption: count asleep samples whose end date falls on the current day,
        // so overnight sleep ending this morning is associated with today.
        let predicate = HKQuery.predicateForSamples(
            withStart: dayBoundary.start,
            end: dayBoundary.end,
            options: .strictEndDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                guard error == nil else {
                    continuation.resume(returning: QueryResult(value: nil, didSucceed: false))
                    return
                }

                let sleepSamples = (samples as? [HKCategorySample]) ?? []
                let totalDuration = sleepSamples
                    .filter(Self.isAsleepSample)
                    .reduce(0.0) { partialResult, sample in
                        partialResult + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                let hours = totalDuration > 0 ? totalDuration / 3_600 : nil
                continuation.resume(returning: QueryResult(value: hours, didSucceed: true))
            }

            healthStore.execute(query)
        }
    }

    private func queryLatestWeight() async -> QueryResult<Double> {
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return QueryResult(value: nil, didSucceed: false)
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil else {
                    continuation.resume(returning: QueryResult(value: nil, didSucceed: false))
                    return
                }

                let sample = (samples as? [HKQuantitySample])?.first
                let value = sample?.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: QueryResult(value: value, didSucceed: true))
            }

            healthStore.execute(query)
        }
    }

    private func sumQuantity(
        of quantityType: HKQuantityType,
        unit: HKUnit,
        predicate: NSPredicate
    ) async -> QueryResult<Double> {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                guard error == nil else {
                    continuation.resume(returning: QueryResult(value: nil, didSucceed: false))
                    return
                }

                let value = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: QueryResult(value: value, didSucceed: true))
            }

            healthStore.execute(query)
        }
    }

    private static func isAsleepSample(_ sample: HKCategorySample) -> Bool {
        guard let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
            return false
        }

        switch sleepValue {
        case .awake, .inBed:
            return false
        default:
            return true
        }
    }
}

struct StubHealthKitService: HealthKitService {
    let isAvailable = false

    func authorizationPhase() async -> HealthKitAuthorizationPhase {
        .unavailable
    }

    func requestReadAuthorization() async throws {}

    func fetchDailyMetrics(for date: Date) async -> HealthKitMetricsPayload {
        HealthKitMetricsPayload(
            dailyMetrics: DailyMetrics.empty(for: DayBoundaryFactory.day(for: date).start),
            supportedFields: [],
            unsupportedFields: Set(DailyMetrics.Field.allCases),
            authorizationStates: Dictionary(
                uniqueKeysWithValues: DailyMetrics.Field.allCases.map { ($0, .unavailableType) }
            ),
            queryFailureFields: []
        )
    }
}

private struct QueryResult<Value: Sendable>: Sendable {
    let value: Value?
    let didSucceed: Bool
}
