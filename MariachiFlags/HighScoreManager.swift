import Foundation

struct HighScoreEntry: Codable, Identifiable {
    let id: UUID
    let score: Int
    let streak: Int
    let date: Date

    init(score: Int, streak: Int) {
        self.id = UUID()
        self.score = score
        self.streak = streak
        self.date = Date()
    }
}

class HighScoreManager: ObservableObject {
    @Published var entries: [HighScoreEntry] = []

    private let key = "mariachiflags_highscores"
    private let maxEntries = 10

    init() {
        load()
    }

    func addScore(_ score: Int, streak: Int) {
        let entry = HighScoreEntry(score: score, streak: streak)
        entries.append(entry)
        entries.sort { $0.score > $1.score }
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    func isHighScore(_ score: Int) -> Bool {
        entries.count < maxEntries || score > (entries.last?.score ?? 0)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([HighScoreEntry].self, from: data) else { return }
        entries = decoded
    }
}
