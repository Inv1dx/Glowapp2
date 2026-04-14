import Foundation

struct ProgressEntry: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let checkInDate: Date
    let weightKg: Double?
    let waistCm: Double?
    let frontPhotoPath: String?
    let sidePhotoPath: String?

    init(
        id: UUID = UUID(),
        checkInDate: Date,
        weightKg: Double? = nil,
        waistCm: Double? = nil,
        frontPhotoPath: String? = nil,
        sidePhotoPath: String? = nil
    ) {
        self.id = id
        self.checkInDate = checkInDate
        self.weightKg = weightKg
        self.waistCm = waistCm
        self.frontPhotoPath = frontPhotoPath?.nonEmptyValue
        self.sidePhotoPath = sidePhotoPath?.nonEmptyValue
    }

    var hasMetrics: Bool {
        weightKg != nil || waistCm != nil
    }

    var hasPhotos: Bool {
        frontPhotoPath != nil || sidePhotoPath != nil
    }

    var hasMeaningfulContent: Bool {
        hasMetrics || hasPhotos
    }
}

enum ProgressPhotoRole: String, CaseIterable, Codable, Sendable {
    case front
    case side

    var title: String {
        switch self {
        case .front:
            "Front photo"
        case .side:
            "Side photo"
        }
    }

    var storageFileNameComponent: String {
        rawValue
    }
}

enum ProgressPhotoUpdate: Equatable, Sendable {
    case keepCurrent
    case remove
    case replace(Data)
}

private extension String {
    var nonEmptyValue: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
