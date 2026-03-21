import Foundation
import os

struct ImageService {

    /// The sandbox directory where box art images are stored.
    static var boxArtDirectory: URL {
        get throws {
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dir = appSupport
                .appendingPathComponent("com.warmasterstudio.app", isDirectory: true)
                .appendingPathComponent("BoxArt", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }
    }

    /// Copies a source image into the BoxArt sandbox directory.
    /// Returns the relative path (e.g. "BoxArt/<uuid>.png") stored in Project.boxArtImagePath.
    static func importImage(from sourceURL: URL) throws -> String {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessing { sourceURL.stopAccessingSecurityScopedResource() } }

        let ext = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension
        let filename = "\(UUID().uuidString).\(ext)"
        let destURL = try boxArtDirectory.appendingPathComponent(filename)
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
        Logger.image.info("Imported box art to \(filename).")
        return "BoxArt/\(filename)"
    }

    /// Resolves a stored relative path to a full URL. Returns nil if the file no longer exists.
    static func resolveImageURL(relativePath: String) -> URL? {
        guard let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return nil }
        let url = appSupport
            .appendingPathComponent("com.warmasterstudio.app", isDirectory: true)
            .appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Deletes the image file from the sandbox.
    static func deleteImage(relativePath: String) {
        guard let url = resolveImageURL(relativePath: relativePath) else { return }
        do {
            try FileManager.default.removeItem(at: url)
            Logger.image.info("Deleted box art at \(relativePath).")
        } catch {
            Logger.image.error("Failed to delete box art: \(error.localizedDescription)")
        }
    }
}
