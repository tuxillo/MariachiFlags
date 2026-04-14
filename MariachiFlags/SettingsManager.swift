import Foundation

class SettingsManager: ObservableObject {
    private let waitMinKey = "settings.waitMin"
    private let waitMaxKey = "settings.waitMax"
    private let customSongBookmarkKey = "settings.customSongBookmark"
    private let customSongNameKey = "settings.customSongName"

    /// Minimum seconds before music fades (default 3)
    @Published var waitMin: Double {
        didSet { UserDefaults.standard.set(waitMin, forKey: waitMinKey) }
    }

    /// Maximum seconds before music fades (default 8)
    @Published var waitMax: Double {
        didSet { UserDefaults.standard.set(waitMax, forKey: waitMaxKey) }
    }

    /// Display name of the custom song, nil = built-in Jarabe Tapatío
    @Published var customSongName: String? {
        didSet { UserDefaults.standard.set(customSongName, forKey: customSongNameKey) }
    }

    init() {
        let defaults = UserDefaults.standard
        let storedMin = defaults.double(forKey: waitMinKey)
        let storedMax = defaults.double(forKey: waitMaxKey)
        self.waitMin = storedMin > 0 ? storedMin : 3.0
        self.waitMax = storedMax > 0 ? storedMax : 8.0
        self.customSongName = defaults.string(forKey: customSongNameKey)
    }

    /// Save a security-scoped bookmark for the user-picked audio file
    func saveCustomSong(url: URL, name: String) {
        do {
            let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmark, forKey: customSongBookmarkKey)
            customSongName = name
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }

    /// Resolve the bookmarked URL (returns nil if using built-in song)
    func resolveCustomSongURL() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: customSongBookmarkKey) else { return nil }
        guard customSongName != nil else { return nil }
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                // Re-save the bookmark
                saveCustomSong(url: url, name: customSongName ?? "Custom")
            }
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }

    /// Reset to built-in song
    func resetToDefaultSong() {
        UserDefaults.standard.removeObject(forKey: customSongBookmarkKey)
        customSongName = nil
    }
}
