import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ProgressEntryEditorViewModel: ObservableObject {
    enum Mode {
        case add
        case edit(ProgressEntry)
    }

    enum PhotoState {
        case empty
        case stored(String)
        case imported(image: UIImage, data: Data)

        var hasPhoto: Bool {
            switch self {
            case .empty:
                false
            case .stored, .imported:
                true
            }
        }
    }

    private enum ParsedMeasurement {
        case empty
        case value(Double)
        case invalid
    }

    private let mode: Mode
    private let progressRepository: any ProgressRepository
    let photoStorageService: any PhotoStorageService
    private let numberFormatter: NumberFormatter

    @Published var checkInDate: Date
    @Published var weightText: String
    @Published var waistText: String
    @Published private(set) var frontPhotoState: PhotoState
    @Published private(set) var sidePhotoState: PhotoState
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSaving = false

    init(
        mode: Mode,
        progressRepository: any ProgressRepository,
        photoStorageService: any PhotoStorageService
    ) {
        self.mode = mode
        self.progressRepository = progressRepository
        self.photoStorageService = photoStorageService

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        self.numberFormatter = formatter

        switch mode {
        case .add:
            self.checkInDate = Date()
            self.weightText = ""
            self.waistText = ""
            self.frontPhotoState = .empty
            self.sidePhotoState = .empty

        case .edit(let entry):
            self.checkInDate = entry.checkInDate
            self.weightText = Self.formattedMeasurement(entry.weightKg, formatter: formatter)
            self.waistText = Self.formattedMeasurement(entry.waistCm, formatter: formatter)
            self.frontPhotoState = entry.frontPhotoPath.map(PhotoState.stored) ?? .empty
            self.sidePhotoState = entry.sidePhotoPath.map(PhotoState.stored) ?? .empty
        }
    }

    var title: String {
        switch mode {
        case .add:
            "Add check-in"
        case .edit:
            "Edit check-in"
        }
    }

    func importPhoto(
        from item: PhotosPickerItem?,
        role: ProgressPhotoRole
    ) async {
        guard let item else {
            return
        }

        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                errorMessage = "Couldn't import that photo. Check Photos access or try another image."
                return
            }

            errorMessage = nil

            switch role {
            case .front:
                frontPhotoState = .imported(image: image, data: data)
            case .side:
                sidePhotoState = .imported(image: image, data: data)
            }
        } catch {
            errorMessage = "Couldn't import that photo. Check Photos access or try another image."
        }
    }

    func removePhoto(role: ProgressPhotoRole) {
        switch role {
        case .front:
            frontPhotoState = .empty
        case .side:
            sidePhotoState = .empty
        }
    }

    func save() async -> Bool {
        let weight = parseMeasurement(weightText)
        let waist = parseMeasurement(waistText)

        switch weight {
        case .invalid:
            errorMessage = "Weight must be a positive number."
            return false
        case .empty, .value:
            break
        }

        switch waist {
        case .invalid:
            errorMessage = "Waist must be a positive number."
            return false
        case .empty, .value:
            break
        }

        let resolvedWeight = resolvedValue(from: weight)
        let resolvedWaist = resolvedValue(from: waist)

        guard resolvedWeight != nil || resolvedWaist != nil || frontPhotoState.hasPhoto || sidePhotoState.hasPhoto else {
            errorMessage = "Add weight, waist, or at least one photo before saving."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            switch mode {
            case .add:
                _ = try await progressRepository.addEntry(
                    ProgressEntry(
                        checkInDate: checkInDate,
                        weightKg: resolvedWeight,
                        waistCm: resolvedWaist
                    ),
                    frontPhotoData: photoData(for: frontPhotoState),
                    sidePhotoData: photoData(for: sidePhotoState)
                )

            case .edit(let entry):
                _ = try await progressRepository.updateEntry(
                    ProgressEntry(
                        id: entry.id,
                        checkInDate: checkInDate,
                        weightKg: resolvedWeight,
                        waistCm: resolvedWaist,
                        frontPhotoPath: entry.frontPhotoPath,
                        sidePhotoPath: entry.sidePhotoPath
                    ),
                    frontPhotoUpdate: photoUpdate(
                        currentState: frontPhotoState,
                        originalPath: entry.frontPhotoPath
                    ),
                    sidePhotoUpdate: photoUpdate(
                        currentState: sidePhotoState,
                        originalPath: entry.sidePhotoPath
                    )
                )
            }

            errorMessage = nil
            return true
        } catch ProgressRepositoryError.invalidEntry {
            errorMessage = "Add weight, waist, or at least one photo before saving."
            return false
        } catch {
            errorMessage = "Couldn't save that check-in."
            return false
        }
    }

    private func photoUpdate(
        currentState: PhotoState,
        originalPath: String?
    ) -> ProgressPhotoUpdate {
        switch currentState {
        case .empty:
            return originalPath == nil ? .keepCurrent : .remove
        case .stored:
            return .keepCurrent
        case .imported(_, let data):
            return .replace(data)
        }
    }

    private func photoData(for state: PhotoState) -> Data? {
        switch state {
        case .empty, .stored:
            return nil
        case .imported(_, let data):
            return data
        }
    }

    private func parseMeasurement(_ text: String) -> ParsedMeasurement {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return .empty
        }

        if let number = numberFormatter.number(from: trimmedText)?.doubleValue, number > 0 {
            return .value(number)
        }

        let normalizedText = trimmedText.replacingOccurrences(of: ",", with: ".")
        if let value = Double(normalizedText), value > 0 {
            return .value(value)
        }

        return .invalid
    }

    private func resolvedValue(from parsedMeasurement: ParsedMeasurement) -> Double? {
        switch parsedMeasurement {
        case .empty, .invalid:
            return nil
        case .value(let value):
            return value
        }
    }

    private static func formattedMeasurement(
        _ value: Double?,
        formatter: NumberFormatter
    ) -> String {
        guard
            let value,
            let text = formatter.string(from: NSNumber(value: value))
        else {
            return ""
        }

        return text
    }
}
