import Foundation

/// Represents a single image entry from the bundled warhammer image library.
struct LibraryImage: Identifiable, Hashable {
    let id: UUID
    let url: URL
    /// Filename without extension — used as the display name and for search.
    let name: String
    /// The faction subfolder (e.g. "Space Marines").
    let faction: String
    /// The game-system folder (e.g. "Warhammer 40,000").
    let gameSystem: String
}

struct ImageLibraryService {

    // MARK: - Library path

    static let libraryPathKey = "imageLibraryPath"

    /// The default library location inside Application Support — travels with user data.
    static var defaultLibraryURL: URL {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport
            .appendingPathComponent("com.warmasterstudio.app", isDirectory: true)
            .appendingPathComponent("ImageLibrary", isDirectory: true)
    }

    /// The resolved URL of the image library root directory.
    /// Uses an override from UserDefaults when set, otherwise the Application Support default.
    static var libraryURL: URL {
        if let custom = UserDefaults.standard.string(forKey: libraryPathKey), !custom.isEmpty {
            let expanded = (custom as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }
        return defaultLibraryURL
    }

    static var libraryExists: Bool {
        FileManager.default.fileExists(atPath: libraryURL.path)
    }

    // MARK: - Scanning

    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "gif", "tiff", "heic"]

    /// Scans the library directory and returns all images sorted by name.
    /// Call from a background Task — reads up to ~2 k directory entries.
    static func scanLibrary() -> [LibraryImage] {
        let root = libraryURL
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }

        var images: [LibraryImage] = []
        let fm = FileManager.default

        guard let systemURLs = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for systemURL in systemURLs.filter({ isDirectory($0) }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let systemName = systemURL.lastPathComponent

            guard let factionURLs = try? fm.contentsOfDirectory(
                at: systemURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for factionURL in factionURLs.filter({ isDirectory($0) }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let factionName = factionURL.lastPathComponent

                guard let fileURLs = try? fm.contentsOfDirectory(
                    at: factionURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                ) else { continue }

                for fileURL in fileURLs where imageExtensions.contains(fileURL.pathExtension.lowercased()) {
                    images.append(LibraryImage(
                        id: UUID(),
                        url: fileURL,
                        name: fileURL.deletingPathExtension().lastPathComponent,
                        faction: factionName,
                        gameSystem: systemName
                    ))
                }
            }
        }

        return images.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    // MARK: - Derived lists

    static func gameSystems(in images: [LibraryImage]) -> [String] {
        Array(Set(images.map(\.gameSystem))).sorted()
    }

    static func factions(in images: [LibraryImage], system: String?) -> [String] {
        let filtered = system.map { s in images.filter { $0.gameSystem == s } } ?? images
        return Array(Set(filtered.map(\.faction))).sorted()
    }
}
