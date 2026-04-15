import Foundation

enum SupabaseMappingError: Error, Equatable {
    case invalidDay(String)
    case invalidTimestamp(String)
    case invalidEnum(String)
}

enum SupabaseDateCoding {
    static func dayString(from date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 1970,
            components.month ?? 1,
            components.day ?? 1
        )
    }

    static func date(fromDayString value: String, calendar: Calendar = .current) throws -> Date {
        let parts = value.split(separator: "-").compactMap { Int(String($0)) }

        guard parts.count == 3 else {
            throw SupabaseMappingError.invalidDay(value)
        }

        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: parts[0],
            month: parts[1],
            day: parts[2]
        )

        guard let date = components.date else {
            throw SupabaseMappingError.invalidDay(value)
        }

        return calendar.startOfDay(for: date)
    }

    static func timestampString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    static func date(fromTimestampString value: String) throws -> Date {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        guard let date = formatter.date(from: value) else {
            throw SupabaseMappingError.invalidTimestamp(value)
        }

        return date
    }
}

struct SupabaseUserProfileRecord: Codable, Equatable {
    let userId: String
    let displayName: String
    let primaryGoal: String
    let targetDailySteps: Int
    let targetSleepHours: Double
    let targetProteinGrams: Int
    let targetWaterML: Int
    let onboardingCompleted: Bool
    let updatedAt: String

    init(userId: String, profile: UserProfile, updatedAt: Date = Date()) {
        self.userId = userId
        self.displayName = profile.displayName
        self.primaryGoal = profile.primaryGoal.rawValue
        self.targetDailySteps = profile.targetDailySteps
        self.targetSleepHours = profile.targetSleepHours
        self.targetProteinGrams = profile.targetProteinGrams
        self.targetWaterML = profile.targetWaterML
        self.onboardingCompleted = profile.onboardingCompleted
        self.updatedAt = SupabaseDateCoding.timestampString(from: updatedAt)
    }

    func makeProfile() throws -> UserProfile {
        guard let primaryGoal = UserProfile.PrimaryGoal(rawValue: primaryGoal) else {
            throw SupabaseMappingError.invalidEnum(primaryGoal)
        }

        return UserProfile(
            displayName: displayName,
            primaryGoal: primaryGoal,
            targetDailySteps: targetDailySteps,
            targetSleepHours: targetSleepHours,
            targetProteinGrams: targetProteinGrams,
            targetWaterML: targetWaterML,
            onboardingCompleted: onboardingCompleted
        )
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case primaryGoal = "primary_goal"
        case targetDailySteps = "target_daily_steps"
        case targetSleepHours = "target_sleep_hours"
        case targetProteinGrams = "target_protein_grams"
        case targetWaterML = "target_water_ml"
        case onboardingCompleted = "onboarding_completed"
        case updatedAt = "updated_at"
    }
}

struct SupabaseDailyMetricsRecord: Codable, Equatable {
    let userId: String
    let date: String
    let steps: Int
    let activeCalories: Double
    let workoutsCount: Int
    let sleepDurationHours: Double?
    let weightKg: Double?
    let connectionState: String
    let source: String
    let limitedFields: [String]
    let unsupportedFields: [String]
    let updatedAt: String

    init(
        userId: String,
        snapshot: MetricsRepositorySnapshot,
        calendar: Calendar = .current,
        updatedAt: Date = Date()
    ) {
        let metrics = snapshot.metrics ?? DailyMetrics.empty(for: Date())

        self.userId = userId
        self.date = SupabaseDateCoding.dayString(from: metrics.date, calendar: calendar)
        self.steps = metrics.steps
        self.activeCalories = metrics.activeCalories
        self.workoutsCount = metrics.workoutsCount
        self.sleepDurationHours = metrics.sleepDurationHours
        self.weightKg = metrics.weightKg
        self.connectionState = snapshot.connectionState.rawValue
        self.source = snapshot.source.rawValue
        self.limitedFields = snapshot.limitedFields.map(\.rawValue)
        self.unsupportedFields = snapshot.unsupportedFields.map(\.rawValue)
        self.updatedAt = SupabaseDateCoding.timestampString(
            from: snapshot.lastUpdatedAt ?? updatedAt
        )
    }

    func makeSnapshot(calendar: Calendar = .current) throws -> MetricsRepositorySnapshot {
        let metricsDate = try SupabaseDateCoding.date(fromDayString: date, calendar: calendar)
        let lastUpdatedAt = try SupabaseDateCoding.date(fromTimestampString: updatedAt)

        return MetricsRepositorySnapshot(
            metrics: DailyMetrics(
                date: metricsDate,
                steps: steps,
                activeCalories: activeCalories,
                workoutsCount: workoutsCount,
                sleepDurationHours: sleepDurationHours,
                weightKg: weightKg
            ),
            connectionState: MetricsConnectionState(rawValue: connectionState) ?? .needsAttention,
            source: MetricsSnapshotSource(rawValue: source) ?? .cache,
            limitedFields: limitedFields.compactMap(DailyMetrics.Field.init(rawValue:)),
            unsupportedFields: unsupportedFields.compactMap(DailyMetrics.Field.init(rawValue:)),
            lastUpdatedAt: lastUpdatedAt
        )
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case steps
        case activeCalories = "active_calories"
        case workoutsCount = "workouts_count"
        case sleepDurationHours = "sleep_duration_hours"
        case weightKg = "weight_kg"
        case connectionState = "connection_state"
        case source
        case limitedFields = "limited_fields"
        case unsupportedFields = "unsupported_fields"
        case updatedAt = "updated_at"
    }
}

struct SupabaseNutritionLogRecord: Codable, Equatable {
    let id: UUID
    let userId: String
    let date: String
    let loggedAt: String
    let calories: Int
    let proteinGrams: Int
    let waterML: Int
    let entryType: String
    let updatedAt: String

    init(
        userId: String,
        log: NutritionLog,
        calendar: Calendar = .current,
        updatedAt: Date = Date()
    ) {
        self.id = log.id
        self.userId = userId
        self.date = SupabaseDateCoding.dayString(from: log.loggedAt, calendar: calendar)
        self.loggedAt = SupabaseDateCoding.timestampString(from: log.loggedAt)
        self.calories = log.calories
        self.proteinGrams = log.proteinGrams
        self.waterML = log.waterML
        self.entryType = log.entryType.rawValue
        self.updatedAt = SupabaseDateCoding.timestampString(from: updatedAt)
    }

    func makeLog() throws -> NutritionLog {
        guard let entryType = NutritionLog.EntryType(rawValue: entryType) else {
            throw SupabaseMappingError.invalidEnum(entryType)
        }

        return NutritionLog(
            id: id,
            loggedAt: try SupabaseDateCoding.date(fromTimestampString: loggedAt),
            calories: calories,
            proteinGrams: proteinGrams,
            waterML: waterML,
            entryType: entryType
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case loggedAt = "logged_at"
        case calories
        case proteinGrams = "protein_grams"
        case waterML = "water_ml"
        case entryType = "entry_type"
        case updatedAt = "updated_at"
    }
}

struct SupabaseRoutineEntryRecord: Codable, Equatable {
    let id: UUID
    let userId: String
    let date: String
    let template: String
    let completedAt: String
    let updatedAt: String

    init(
        userId: String,
        entry: RoutineEntry,
        calendar: Calendar = .current,
        updatedAt: Date = Date()
    ) {
        self.id = entry.id
        self.userId = userId
        self.date = SupabaseDateCoding.dayString(from: entry.day, calendar: calendar)
        self.template = entry.template.rawValue
        self.completedAt = SupabaseDateCoding.timestampString(from: entry.completedAt)
        self.updatedAt = SupabaseDateCoding.timestampString(from: updatedAt)
    }

    func makeEntry(calendar: Calendar = .current) throws -> RoutineEntry {
        guard let template = RoutineTemplate(rawValue: template) else {
            throw SupabaseMappingError.invalidEnum(template)
        }

        return RoutineEntry(
            id: id,
            template: template,
            day: try SupabaseDateCoding.date(fromDayString: date, calendar: calendar),
            completedAt: try SupabaseDateCoding.date(fromTimestampString: completedAt)
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case template
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseGlowScoreRecord: Codable, Equatable {
    let userId: String
    let date: String
    let overallScore: Int
    let availableWeight: Int
    let totalWeight: Int
    let breakdowns: [GlowScoreCategoryBreakdown]
    let explanations: [String]
    let configVersion: String
    let computedAt: String
    let updatedAt: String

    init(
        userId: String,
        score: GlowScore,
        calendar: Calendar = .current,
        updatedAt: Date = Date()
    ) {
        self.userId = userId
        self.date = SupabaseDateCoding.dayString(from: score.date, calendar: calendar)
        self.overallScore = score.overallScore
        self.availableWeight = score.availableWeight
        self.totalWeight = score.totalWeight
        self.breakdowns = score.breakdowns
        self.explanations = score.explanations
        self.configVersion = score.configVersion
        self.computedAt = SupabaseDateCoding.timestampString(from: score.computedAt)
        self.updatedAt = SupabaseDateCoding.timestampString(from: updatedAt)
    }

    func makeScore(calendar: Calendar = .current) throws -> GlowScore {
        GlowScore(
            date: try SupabaseDateCoding.date(fromDayString: date, calendar: calendar),
            overallScore: overallScore,
            availableWeight: availableWeight,
            totalWeight: totalWeight,
            breakdowns: breakdowns,
            explanations: explanations,
            configVersion: configVersion,
            computedAt: try SupabaseDateCoding.date(fromTimestampString: computedAt)
        )
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case overallScore = "overall_score"
        case availableWeight = "available_weight"
        case totalWeight = "total_weight"
        case breakdowns
        case explanations
        case configVersion = "config_version"
        case computedAt = "computed_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseGlowPlanRecord: Codable, Equatable {
    let id: UUID
    let userId: String
    let date: String
    let generatedAt: String
    let mode: String
    let actions: [GlowPlanAction]
    let updatedAt: String

    init(
        userId: String,
        plan: GlowPlan,
        calendar: Calendar = .current,
        updatedAt: Date = Date()
    ) {
        self.id = plan.id
        self.userId = userId
        self.date = SupabaseDateCoding.dayString(from: plan.date, calendar: calendar)
        self.generatedAt = SupabaseDateCoding.timestampString(from: plan.generatedAt)
        self.mode = plan.mode.rawValue
        self.actions = plan.actions.sorted { $0.priority < $1.priority }
        self.updatedAt = SupabaseDateCoding.timestampString(from: updatedAt)
    }

    func makePlan(calendar: Calendar = .current) throws -> GlowPlan {
        guard let mode = GlowPlanMode(rawValue: mode) else {
            throw SupabaseMappingError.invalidEnum(mode)
        }

        return GlowPlan(
            id: id,
            date: try SupabaseDateCoding.date(fromDayString: date, calendar: calendar),
            generatedAt: try SupabaseDateCoding.date(fromTimestampString: generatedAt),
            mode: mode,
            actions: actions.sorted { $0.priority < $1.priority }
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case generatedAt = "generated_at"
        case mode
        case actions
        case updatedAt = "updated_at"
    }
}

struct SupabaseProgressEntryRecord: Codable, Equatable {
    let id: UUID
    let userId: String
    let checkInDate: String
    let weightKg: Double?
    let waistCm: Double?
    let frontPhotoPath: String?
    let sidePhotoPath: String?
    let updatedAt: String

    init(
        userId: String,
        entry: ProgressEntry,
        calendar: Calendar = .current,
        updatedAt: Date = Date()
    ) {
        self.id = entry.id
        self.userId = userId
        self.checkInDate = SupabaseDateCoding.dayString(from: entry.checkInDate, calendar: calendar)
        self.weightKg = entry.weightKg
        self.waistCm = entry.waistCm
        self.frontPhotoPath = entry.frontPhotoPath
        self.sidePhotoPath = entry.sidePhotoPath
        self.updatedAt = SupabaseDateCoding.timestampString(from: updatedAt)
    }

    func makeEntry(calendar: Calendar = .current) throws -> ProgressEntry {
        let startOfDay = try SupabaseDateCoding.date(
            fromDayString: checkInDate,
            calendar: calendar
        )
        let normalizedCheckInDate = calendar.date(
            byAdding: .hour,
            value: 12,
            to: startOfDay
        ) ?? startOfDay

        return ProgressEntry(
            id: id,
            checkInDate: normalizedCheckInDate,
            weightKg: weightKg,
            waistCm: waistCm,
            frontPhotoPath: frontPhotoPath,
            sidePhotoPath: sidePhotoPath
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case checkInDate = "check_in_date"
        case weightKg = "weight_kg"
        case waistCm = "waist_cm"
        case frontPhotoPath = "front_photo_path"
        case sidePhotoPath = "side_photo_path"
        case updatedAt = "updated_at"
    }
}
