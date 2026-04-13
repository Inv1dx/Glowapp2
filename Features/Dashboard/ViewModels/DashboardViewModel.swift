import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    struct MetricCard: Identifiable {
        let field: DailyMetrics.Field
        let valueText: String
        let detailText: String
        let systemImage: String

        var id: DailyMetrics.Field { field }
        var title: String { field.displayTitle }
    }

    private let metricsRepository: any MetricsRepository
    private let timeFormatter: DateFormatter

    @Published private(set) var snapshot = MetricsRepositorySnapshot.empty
    @Published private(set) var isLoading = false
    @Published private(set) var isRequestingAccess = false
    @Published private(set) var hasLoadedOnce = false

    init(metricsRepository: any MetricsRepository) {
        self.metricsRepository = metricsRepository

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        self.timeFormatter = formatter
    }

    var navigationTitle: String {
        "Home"
    }

    var title: String {
        "Today's glow inputs"
    }

    var subtitle: String {
        switch snapshot.connectionState {
        case .unavailable:
            "Apple Health is not available on this device."
        case .notConnected:
            "Connect Apple Health to pull in today's movement, sleep, and weight data."
        case .connected:
            "Keep the dashboard practical. Read the basics, then move on with your day."
        case .needsAttention:
            "Glow could not read all of your Apple Health data yet."
        }
    }

    var sourceMessage: String? {
        guard let lastUpdatedAt = snapshot.lastUpdatedAt else {
            return nil
        }

        let formattedTime = timeFormatter.string(from: lastUpdatedAt)

        switch snapshot.source {
        case .live:
            return "Updated \(formattedTime)"
        case .cache:
            return "Showing cached data from \(formattedTime)"
        case .none:
            return nil
        }
    }

    var showsMetrics: Bool {
        snapshot.metrics != nil
    }

    var showsStatusCard: Bool {
        snapshot.connectionState != .connected
    }

    var statusCardTitle: String {
        switch snapshot.connectionState {
        case .unavailable:
            "Apple Health unavailable"
        case .notConnected:
            "Connect Apple Health"
        case .connected:
            ""
        case .needsAttention:
            "Apple Health access needed"
        }
    }

    var statusCardMessage: String {
        switch snapshot.connectionState {
        case .unavailable:
            "HealthKit is not supported here. The rest of Glow can still stay lightweight."
        case .notConnected:
            "Glow reads only today's steps, active calories, workouts, sleep, and your latest logged weight."
        case .connected:
            ""
        case .needsAttention:
            "Glow could not read today's Health data. Review access in the Health app or try the sync again."
        }
    }

    var statusCardSystemImage: String {
        switch snapshot.connectionState {
        case .unavailable:
            "iphone.slash"
        case .notConnected:
            "heart.text.square"
        case .connected:
            "sparkles"
        case .needsAttention:
            "exclamationmark.shield"
        }
    }

    var statusCardButtonTitle: String? {
        switch snapshot.connectionState {
        case .notConnected:
            "Connect Apple Health"
        case .needsAttention:
            "Try Again"
        case .unavailable, .connected:
            nil
        }
    }

    var showsSettingsAction: Bool {
        snapshot.connectionState == .needsAttention
    }

    var limitedAccessMessage: String? {
        guard snapshot.connectionState == .connected else {
            return nil
        }

        guard !snapshot.limitedFields.isEmpty else {
            return nil
        }

        return "Some Apple Health categories are still limited. Glow is showing the data it can read."
    }

    var metricCards: [MetricCard] {
        guard let metrics = snapshot.metrics else {
            return []
        }

        let limitedFields = Set(snapshot.limitedFields)
        let unsupportedFields = Set(snapshot.unsupportedFields)

        return [
            MetricCard(
                field: .steps,
                valueText: metrics.steps.formatted(),
                detailText: "Today",
                systemImage: "figure.walk"
            ),
            MetricCard(
                field: .activeCalories,
                valueText: "\(Int(metrics.activeCalories.rounded()).formatted()) kcal",
                detailText: "Today",
                systemImage: "flame.fill"
            ),
            MetricCard(
                field: .workoutsCount,
                valueText: metrics.workoutsCount.formatted(),
                detailText: "Today",
                systemImage: "figure.strengthtraining.traditional"
            ),
            MetricCard(
                field: .sleepDurationHours,
                valueText: formattedSleepText(
                    metrics.sleepDurationHours,
                    limitedFields: limitedFields,
                    unsupportedFields: unsupportedFields
                ),
                detailText: "Sleep ending today",
                systemImage: "moon.stars.fill"
            ),
            MetricCard(
                field: .weightKg,
                valueText: formattedWeightText(
                    metrics.weightKg,
                    limitedFields: limitedFields,
                    unsupportedFields: unsupportedFields
                ),
                detailText: "Latest logged",
                systemImage: "scalemass.fill"
            )
        ]
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce else {
            return
        }

        isLoading = true
        snapshot = await metricsRepository.loadCurrentDaySnapshot()
        isLoading = false
        hasLoadedOnce = true
    }

    func refresh() async {
        isLoading = true
        snapshot = await metricsRepository.refreshCurrentDaySnapshot()
        isLoading = false
        hasLoadedOnce = true
    }

    func connectAppleHealth() async {
        isRequestingAccess = true
        snapshot = await metricsRepository.requestHealthAccess()
        isRequestingAccess = false
        hasLoadedOnce = true
    }

    private func formattedSleepText(
        _ value: Double?,
        limitedFields: Set<DailyMetrics.Field>,
        unsupportedFields: Set<DailyMetrics.Field>
    ) -> String {
        if unsupportedFields.contains(.sleepDurationHours) {
            return "Unavailable"
        }

        if let value {
            return value.formatted(.number.precision(.fractionLength(1))) + " hr"
        }

        if limitedFields.contains(.sleepDurationHours) {
            return "Check access"
        }

        return "No sleep yet"
    }

    private func formattedWeightText(
        _ value: Double?,
        limitedFields: Set<DailyMetrics.Field>,
        unsupportedFields: Set<DailyMetrics.Field>
    ) -> String {
        if unsupportedFields.contains(.weightKg) {
            return "Unavailable"
        }

        if let value {
            return value.formatted(.number.precision(.fractionLength(1))) + " kg"
        }

        if limitedFields.contains(.weightKg) {
            return "Check access"
        }

        return "No weight yet"
    }
}
