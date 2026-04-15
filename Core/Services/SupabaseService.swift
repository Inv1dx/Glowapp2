import Combine
import Foundation

struct SupabaseConfiguration: Equatable {
    let url: URL?
    let anonKey: String

    var isConfigured: Bool {
        url != nil && !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func live(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> SupabaseConfiguration {
        let urlValue = environment["SUPABASE_URL"] ??
        (bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String)

        let anonKey = environment["SUPABASE_ANON_KEY"] ??
        (bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String) ??
        ""

        return SupabaseConfiguration(
            url: urlValue.flatMap(URL.init(string:)),
            anonKey: anonKey
        )
    }
}

enum SupabaseTable: String {
    case userProfiles = "user_profiles"
    case dailyMetrics = "daily_metrics"
    case nutritionLogs = "nutrition_logs"
    case routineEntries = "routine_entries"
    case glowScores = "glow_scores"
    case glowPlans = "glow_plans"
    case progressEntries = "progress_entries"
}

struct SupabaseQueryFilter: Equatable {
    enum Operation: String {
        case equal = "eq"
    }

    let column: String
    let operation: Operation
    let value: String

    static func equal(_ column: String, _ value: String) -> SupabaseQueryFilter {
        SupabaseQueryFilter(column: column, operation: .equal, value: value)
    }

    var queryValue: String {
        "\(operation.rawValue).\(value)"
    }
}

struct SupabaseOrder: Equatable {
    enum Direction: String {
        case ascending = "asc"
        case descending = "desc"
    }

    let column: String
    let direction: Direction

    static func ascending(_ column: String) -> SupabaseOrder {
        SupabaseOrder(column: column, direction: .ascending)
    }

    static func descending(_ column: String) -> SupabaseOrder {
        SupabaseOrder(column: column, direction: .descending)
    }

    var queryValue: String {
        "\(column).\(direction.rawValue)"
    }
}

struct SupabaseSyncStatus: Equatable {
    enum State: Equatable {
        case notConfigured
        case idle
        case syncing
        case synced
        case failed
    }

    let state: State
    let lastSuccessfulSyncAt: Date?
    let lastErrorMessage: String?

    static let notConfigured = SupabaseSyncStatus(
        state: .notConfigured,
        lastSuccessfulSyncAt: nil,
        lastErrorMessage: nil
    )

    static let idle = SupabaseSyncStatus(
        state: .idle,
        lastSuccessfulSyncAt: nil,
        lastErrorMessage: nil
    )
}

enum SupabaseServiceError: Error, Equatable {
    case notConfigured
    case invalidURL
    case encodingFailed
    case decodingFailed
    case requestFailed(statusCode: Int, message: String)
    case transportFailed(message: String)

    var safeMessage: String {
        switch self {
        case .notConfigured:
            "Supabase is not configured."
        case .invalidURL:
            "Supabase request could not be created."
        case .encodingFailed:
            "Sync could not prepare local changes."
        case .decodingFailed:
            "Sync received data Glow could not read."
        case .requestFailed:
            "Sync failed on the server."
        case .transportFailed:
            "Sync is unavailable. Changes are saved locally for now."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .requestFailed(let statusCode, _):
            statusCode == 408 || statusCode == 429 || (500...599).contains(statusCode)
        case .transportFailed:
            true
        case .notConfigured, .invalidURL, .encodingFailed, .decodingFailed:
            false
        }
    }
}

protocol SupabaseService {
    var isConfigured: Bool { get }
    var status: SupabaseSyncStatus { get }
    var statusPublisher: AnyPublisher<SupabaseSyncStatus, Never> { get }

    func select<Record: Decodable>(
        _ recordType: Record.Type,
        from table: SupabaseTable,
        filters: [SupabaseQueryFilter],
        order: [SupabaseOrder],
        limit: Int?
    ) async throws -> [Record]

    func upsert<Record: Encodable>(
        _ record: Record,
        into table: SupabaseTable,
        onConflict columns: [String]
    ) async throws

    func delete(
        from table: SupabaseTable,
        filters: [SupabaseQueryFilter]
    ) async throws
}

final class LiveSupabaseService: SupabaseService {
    private let configuration: SupabaseConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let statusSubject: CurrentValueSubject<SupabaseSyncStatus, Never>
    private let maxRetryCount: Int

    init(
        configuration: SupabaseConfiguration = .live(),
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        maxRetryCount: Int = 2
    ) {
        self.configuration = configuration
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
        self.maxRetryCount = maxRetryCount
        self.statusSubject = CurrentValueSubject(
            configuration.isConfigured ? .idle : .notConfigured
        )
    }

    var isConfigured: Bool {
        configuration.isConfigured
    }

    var status: SupabaseSyncStatus {
        statusSubject.value
    }

    var statusPublisher: AnyPublisher<SupabaseSyncStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    func select<Record: Decodable>(
        _ recordType: Record.Type,
        from table: SupabaseTable,
        filters: [SupabaseQueryFilter],
        order: [SupabaseOrder],
        limit: Int?
    ) async throws -> [Record] {
        try await performWithRetry {
            let request = try makeRequest(
                method: "GET",
                table: table,
                queryItems: makeSelectQueryItems(
                    filters: filters,
                    order: order,
                    limit: limit
                )
            )

            let data = try await self.perform(request)

            do {
                return try self.decoder.decode([Record].self, from: data)
            } catch {
                throw SupabaseServiceError.decodingFailed
            }
        }
    }

    func upsert<Record: Encodable>(
        _ record: Record,
        into table: SupabaseTable,
        onConflict columns: [String]
    ) async throws {
        try await performWithRetry {
            let body: Data

            do {
                body = try self.encoder.encode(record)
            } catch {
                throw SupabaseServiceError.encodingFailed
            }

            var queryItems: [URLQueryItem] = []
            if !columns.isEmpty {
                queryItems.append(
                    URLQueryItem(name: "on_conflict", value: columns.joined(separator: ","))
                )
            }

            var request = try self.makeRequest(
                method: "POST",
                table: table,
                queryItems: queryItems
            )
            request.httpBody = body
            request.setValue(
                "resolution=merge-duplicates,return=minimal",
                forHTTPHeaderField: "Prefer"
            )

            _ = try await self.perform(request)
        }
    }

    func delete(
        from table: SupabaseTable,
        filters: [SupabaseQueryFilter]
    ) async throws {
        try await performWithRetry {
            var request = try self.makeRequest(
                method: "DELETE",
                table: table,
                queryItems: filters.map {
                    URLQueryItem(name: $0.column, value: $0.queryValue)
                }
            )
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

            _ = try await self.perform(request)
        }
    }

    private func makeSelectQueryItems(
        filters: [SupabaseQueryFilter],
        order: [SupabaseOrder],
        limit: Int?
    ) -> [URLQueryItem] {
        var queryItems = [URLQueryItem(name: "select", value: "*")]
        queryItems.append(
            contentsOf: filters.map {
                URLQueryItem(name: $0.column, value: $0.queryValue)
            }
        )

        if !order.isEmpty {
            queryItems.append(
                URLQueryItem(
                    name: "order",
                    value: order.map(\.queryValue).joined(separator: ",")
                )
            )
        }

        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }

        return queryItems
    }

    private func makeRequest(
        method: String,
        table: SupabaseTable,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        guard isConfigured else {
            throw SupabaseServiceError.notConfigured
        }

        guard
            let baseURL = configuration.url?
                .appendingPathComponent("rest")
                .appendingPathComponent("v1")
                .appendingPathComponent(table.rawValue),
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        else {
            throw SupabaseServiceError.invalidURL
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw SupabaseServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseServiceError.transportFailed(message: "Missing HTTP response")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw SupabaseServiceError.requestFailed(
                    statusCode: httpResponse.statusCode,
                    message: String(data: data, encoding: .utf8) ?? ""
                )
            }

            return data
        } catch let error as SupabaseServiceError {
            throw error
        } catch {
            throw SupabaseServiceError.transportFailed(message: error.localizedDescription)
        }
    }

    private func performWithRetry<T>(
        operation: () async throws -> T
    ) async throws -> T {
        guard isConfigured else {
            let error = SupabaseServiceError.notConfigured
            updateStatusForFailure(error)
            throw error
        }

        updateStatus(
            SupabaseSyncStatus(
                state: .syncing,
                lastSuccessfulSyncAt: status.lastSuccessfulSyncAt,
                lastErrorMessage: nil
            )
        )

        var attempt = 0

        while true {
            do {
                let value = try await operation()
                updateStatus(
                    SupabaseSyncStatus(
                        state: .synced,
                        lastSuccessfulSyncAt: Date(),
                        lastErrorMessage: nil
                    )
                )
                return value
            } catch let error as SupabaseServiceError {
                guard error.isRetryable, attempt < maxRetryCount else {
                    updateStatusForFailure(error)
                    throw error
                }

                attempt += 1
                try await Task.sleep(nanoseconds: UInt64(attempt) * 350_000_000)
            } catch {
                let wrappedError = SupabaseServiceError.transportFailed(
                    message: error.localizedDescription
                )

                guard wrappedError.isRetryable, attempt < maxRetryCount else {
                    updateStatusForFailure(wrappedError)
                    throw wrappedError
                }

                attempt += 1
                try await Task.sleep(nanoseconds: UInt64(attempt) * 350_000_000)
            }
        }
    }

    private func updateStatusForFailure(_ error: SupabaseServiceError) {
        updateStatus(
            SupabaseSyncStatus(
                state: .failed,
                lastSuccessfulSyncAt: status.lastSuccessfulSyncAt,
                lastErrorMessage: error.safeMessage
            )
        )
    }

    private func updateStatus(_ status: SupabaseSyncStatus) {
        DispatchQueue.main.async {
            self.statusSubject.send(status)
        }
    }
}

struct StubSupabaseService: SupabaseService {
    let isConfigured = false
    let status = SupabaseSyncStatus.notConfigured

    var statusPublisher: AnyPublisher<SupabaseSyncStatus, Never> {
        Just(status).eraseToAnyPublisher()
    }

    func select<Record: Decodable>(
        _ recordType: Record.Type,
        from table: SupabaseTable,
        filters: [SupabaseQueryFilter],
        order: [SupabaseOrder],
        limit: Int?
    ) async throws -> [Record] {
        throw SupabaseServiceError.notConfigured
    }

    func upsert<Record: Encodable>(
        _ record: Record,
        into table: SupabaseTable,
        onConflict columns: [String]
    ) async throws {
        throw SupabaseServiceError.notConfigured
    }

    func delete(
        from table: SupabaseTable,
        filters: [SupabaseQueryFilter]
    ) async throws {
        throw SupabaseServiceError.notConfigured
    }
}
