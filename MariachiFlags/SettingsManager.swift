import Foundation

struct TrackEntry: Codable, Identifiable {
    var id: UUID
    var name: String
    var bookmarkData: Data?   // nil = built-in Jarabe Tapatío

    var isBuiltIn: Bool { bookmarkData == nil }

    // Fixed UUID so the built-in track is always the same object after decode
    static let builtInID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    static let builtIn = TrackEntry(
        id: builtInID,
        name: "Jarabe Tapatío",
        bookmarkData: nil
    )
}

class SettingsManager: ObservableObject {
    private let tracksKey  = "settings.tracks2"
    private let waitMinKey = "settings.waitMin"
    private let waitMaxKey = "settings.waitMax"

    @Published var tracks: [TrackEntry] {
        didSet { saveTracks() }
    }

    @Published var waitMin: Double {
        didSet { UserDefaults.standard.set(waitMin, forKey: waitMinKey) }
    }

    @Published var waitMax: Double {
        didSet { UserDefaults.standard.set(waitMax, forKey: waitMaxKey) }
    }

    init() {
        let d = UserDefaults.standard
        let min = d.double(forKey: waitMinKey)
        let max = d.double(forKey: waitMaxKey)
        self.waitMin = min > 0 ? min : 3.0
        self.waitMax = max > 0 ? max : 8.0

        if let data = d.data(forKey: tracksKey),
           let decoded = try? JSONDecoder().decode([TrackEntry].self, from: data),
           !decoded.isEmpty {
            self.tracks = decoded
        } else {
            self.tracks = [.builtIn]
        }
    }

    // MARK: - Tracklist mutations

    func addTrack(url: URL, name: String) {
        do {
            let bookmark = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            // Remove the built-in placeholder when the first custom track is added
            tracks.removeAll { $0.isBuiltIn }
            tracks.append(TrackEntry(id: UUID(), name: name, bookmarkData: bookmark))
        } catch {
            print("Bookmark error: \(error)")
        }
    }

    func removeTrack(id: UUID) {
        tracks.removeAll { $0.id == id && !$0.isBuiltIn }
        // Restore built-in if the playlist is now empty
        if tracks.isEmpty {
            tracks = [.builtIn]
        }
    }

    func moveTracks(from source: IndexSet, to destination: Int) {
        tracks.move(fromOffsets: source, toOffset: destination)
    }

    /// Resolve a security-scoped bookmark to a URL (nil if built-in or stale)
    func resolveURL(for track: TrackEntry) -> URL? {
        guard let data = track.bookmarkData else { return nil }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                // Refresh bookmark
                if let fresh = try? url.bookmarkData() {
                    if let idx = tracks.firstIndex(where: { $0.id == track.id }) {
                        tracks[idx].bookmarkData = fresh
                    }
                }
            }
            return url
        } catch {
            return nil
        }
    }

    private func saveTracks() {
        if let data = try? JSONEncoder().encode(tracks) {
            UserDefaults.standard.set(data, forKey: tracksKey)
        }
    }
}
