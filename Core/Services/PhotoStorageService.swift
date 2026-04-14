import Foundation
import UIKit

protocol PhotoStorageService {
    func savePhotoData(
        _ data: Data,
        entryID: UUID,
        role: ProgressPhotoRole
    ) throws -> String

    func imageURL(for path: String) -> URL?
    func deletePhoto(at path: String?) throws
}

enum PhotoStorageServiceError: Error, Equatable {
    case invalidImageData
}

final class LocalPhotoStorageService: PhotoStorageService {
    private static let photosDirectoryName = "ProgressPhotos"

    private let fileManager: FileManager
    private let baseDirectoryURL: URL

    init(
        fileManager: FileManager = .default,
        baseDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.baseDirectoryURL = baseDirectoryURL ?? Self.defaultBaseDirectory(for: fileManager)
    }

    func savePhotoData(
        _ data: Data,
        entryID: UUID,
        role: ProgressPhotoRole
    ) throws -> String {
        try ensurePhotosDirectoryExists()

        guard let normalizedData = UIImage(data: data)?.jpegData(compressionQuality: 0.82) else {
            throw PhotoStorageServiceError.invalidImageData
        }

        let storageKey = storageKey(for: entryID, role: role)
        let url = url(for: storageKey)

        try normalizedData.write(to: url, options: .atomic)
        return storageKey
    }

    func imageURL(for path: String) -> URL? {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else {
            return nil
        }

        let resolvedURL = url(for: trimmedPath)
        return fileManager.fileExists(atPath: resolvedURL.path) ? resolvedURL : nil
    }

    func deletePhoto(at path: String?) throws {
        guard
            let trimmedPath = path?.trimmingCharacters(in: .whitespacesAndNewlines),
            !trimmedPath.isEmpty
        else {
            return
        }

        let resolvedURL = url(for: trimmedPath)

        guard fileManager.fileExists(atPath: resolvedURL.path) else {
            return
        }

        try fileManager.removeItem(at: resolvedURL)
    }

    private func storageKey(for entryID: UUID, role: ProgressPhotoRole) -> String {
        "\(Self.photosDirectoryName)/\(entryID.uuidString.lowercased())-\(role.storageFileNameComponent).jpg"
    }

    private func url(for path: String) -> URL {
        baseDirectoryURL.appendingPathComponent(path, isDirectory: false)
    }

    private func ensurePhotosDirectoryExists() throws {
        try fileManager.createDirectory(
            at: photosDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    private var photosDirectoryURL: URL {
        baseDirectoryURL.appendingPathComponent(Self.photosDirectoryName, isDirectory: true)
    }

    private static func defaultBaseDirectory(for fileManager: FileManager) -> URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ??
        fileManager.temporaryDirectory
    }
}
