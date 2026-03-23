import Foundation
import os

/// Downloads the default warhammer image library from the Games Workshop CDN
/// using the bundled warhammer_products.json catalogue.
@MainActor
final class ImageDownloadService: ObservableObject {

    // MARK: - State

    enum DownloadState: Equatable {
        case idle
        case downloading(completed: Int, total: Int, currentName: String)
        case finished(downloaded: Int, skipped: Int)
        case failed(String)
    }

    @Published var state: DownloadState = .idle

    var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }

    // MARK: - Types

    private struct ProductEntry: Decodable {
        let name: String
        let slug: String
        let imageFile: String
        let game: String
        let faction: String
    }

    // MARK: - Constants

    private static let cdnBase = "https://www.games-workshop.com/resources/catalog/product/920x950/"

    // MARK: - Download

    /// Starts downloading all products from the catalogue into Application Support.
    /// Already-existing files are skipped (idempotent — safe to call again after interruption).
    func downloadAll() {
        guard !isDownloading else { return }

        Task {
            guard let url = Bundle.main.url(forResource: "warhammer_products", withExtension: "json") else {
                state = .failed("warhammer_products.json not found in app bundle.")
                return
            }

            let products: [ProductEntry]
            do {
                let data = try Data(contentsOf: url)
                let dict = try JSONDecoder().decode([String: ProductEntry].self, from: data)
                products = Array(dict.values)
            } catch {
                state = .failed("Failed to parse catalogue: \(error.localizedDescription)")
                return
            }

            let libraryRoot = ImageLibraryService.defaultLibraryURL
            let fm = FileManager.default
            var downloaded = 0
            var skipped = 0

            for (index, product) in products.enumerated() {
                let destDir = libraryRoot
                    .appendingPathComponent(product.game, isDirectory: true)
                    .appendingPathComponent(product.faction, isDirectory: true)
                let destFile = destDir.appendingPathComponent(product.imageFile)

                // Update progress on main actor
                state = .downloading(
                    completed: index,
                    total: products.count,
                    currentName: product.name
                )

                // Skip if already downloaded
                if fm.fileExists(atPath: destFile.path) {
                    skipped += 1
                    continue
                }

                guard let imageURL = URL(string: Self.cdnBase + product.imageFile) else {
                    skipped += 1
                    continue
                }

                do {
                    try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
                    let (tmpURL, response) = try await URLSession.shared.download(from: imageURL)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        Logger.image.warning("Skipped \(product.imageFile) — non-200 response.")
                        skipped += 1
                        continue
                    }
                    // Move from temp to destination
                    if fm.fileExists(atPath: destFile.path) {
                        try fm.removeItem(at: destFile)
                    }
                    try fm.moveItem(at: tmpURL, to: destFile)
                    downloaded += 1
                    Logger.image.info("Downloaded \(product.imageFile)")
                } catch {
                    Logger.image.warning("Failed to download \(product.imageFile): \(error.localizedDescription)")
                    skipped += 1
                }
            }

            state = .finished(downloaded: downloaded, skipped: skipped)
        }
    }

    func reset() {
        state = .idle
    }
}
