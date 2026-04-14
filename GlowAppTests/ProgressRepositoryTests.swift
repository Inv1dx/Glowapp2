import UIKit
import XCTest
@testable import GlowApp

final class ProgressRepositoryTests: XCTestCase {
    func testEntriesPersistNewestFirstAcrossRepositoryInstances() async throws {
        let userDefaults = makeUserDefaults()
        let photoStorageService = makePhotoStorageService()
        let firstRepository = makeRepository(
            userDefaults: userDefaults,
            photoStorageService: photoStorageService
        )
        let secondRepository = makeRepository(
            userDefaults: userDefaults,
            photoStorageService: photoStorageService
        )

        let earlierEntry = try await firstRepository.addEntry(
            ProgressEntry(
                checkInDate: makeDate(year: 2026, month: 4, day: 7, hour: 9),
                weightKg: 73.4
            ),
            frontPhotoData: nil,
            sidePhotoData: nil
        )
        let laterEntry = try await firstRepository.addEntry(
            ProgressEntry(
                checkInDate: makeDate(year: 2026, month: 4, day: 14, hour: 8),
                waistCm: 81.2
            ),
            frontPhotoData: nil,
            sidePhotoData: nil
        )

        let loadedEntries = await secondRepository.fetchAllEntries()

        XCTAssertEqual(loadedEntries.map(\.id), [laterEntry.id, earlierEntry.id])
        XCTAssertEqual(calendar.component(.hour, from: loadedEntries[0].checkInDate), 12)
        XCTAssertEqual(calendar.component(.hour, from: loadedEntries[1].checkInDate), 12)
    }

    func testUpdateAndDeleteCleanUpAssociatedPhotos() async throws {
        let photoStorageService = makePhotoStorageService()
        let repository = makeRepository(photoStorageService: photoStorageService)
        let originalFrontPhoto = try makeImageData(color: .systemBlue)
        let replacementSidePhoto = try makeImageData(color: .systemPink)

        let addedEntry = try await repository.addEntry(
            ProgressEntry(
                checkInDate: makeDate(year: 2026, month: 4, day: 14, hour: 9),
                weightKg: 72.4
            ),
            frontPhotoData: originalFrontPhoto,
            sidePhotoData: nil
        )

        XCTAssertNotNil(addedEntry.frontPhotoPath)
        XCTAssertNotNil(
            photoStorageService.imageURL(for: addedEntry.frontPhotoPath ?? "")
        )

        let updatedEntry = try await repository.updateEntry(
            ProgressEntry(
                id: addedEntry.id,
                checkInDate: addedEntry.checkInDate,
                weightKg: 71.9,
                waistCm: 80.8,
                frontPhotoPath: addedEntry.frontPhotoPath,
                sidePhotoPath: addedEntry.sidePhotoPath
            ),
            frontPhotoUpdate: .remove,
            sidePhotoUpdate: .replace(replacementSidePhoto)
        )

        XCTAssertNil(updatedEntry.frontPhotoPath)
        XCTAssertNotNil(updatedEntry.sidePhotoPath)
        XCTAssertNil(photoStorageService.imageURL(for: addedEntry.frontPhotoPath ?? ""))
        XCTAssertNotNil(photoStorageService.imageURL(for: updatedEntry.sidePhotoPath ?? ""))

        await repository.deleteEntry(id: updatedEntry.id)

        let remainingEntries = await repository.fetchAllEntries()
        XCTAssertTrue(remainingEntries.isEmpty)
        XCTAssertNil(photoStorageService.imageURL(for: updatedEntry.sidePhotoPath ?? ""))
    }

    func testAddingEntryWithoutMeaningfulContentThrowsValidationError() async {
        let repository = makeRepository()

        await XCTAssertThrowsErrorAsync(
            try await repository.addEntry(
                ProgressEntry(checkInDate: makeDate(year: 2026, month: 4, day: 14, hour: 9)),
                frontPhotoData: nil,
                sidePhotoData: nil
            )
        ) { error in
            XCTAssertEqual(error as? ProgressRepositoryError, .invalidEntry)
        }
    }

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.firstWeekday = 2
        return calendar
    }()

    private func makeRepository(
        userDefaults: UserDefaults? = nil,
        photoStorageService: LocalPhotoStorageService? = nil
    ) -> LocalProgressRepository {
        LocalProgressRepository(
            userDefaults: userDefaults ?? makeUserDefaults(),
            calendar: calendar,
            photoStorageService: photoStorageService ?? makePhotoStorageService()
        )
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "GlowApp.progress-tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makePhotoStorageService() -> LocalPhotoStorageService {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlowAppProgressTests-\(UUID().uuidString)", isDirectory: true)
        return LocalPhotoStorageService(baseDirectoryURL: directoryURL)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        )

        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    private func makeImageData(color: UIColor) throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw XCTSkip("Unable to create image data for repository test.")
        }

        return data
    }
}

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure () async throws -> some Any,
    _ errorHandler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail("Expected an error to be thrown.")
    } catch {
        errorHandler(error)
    }
}
