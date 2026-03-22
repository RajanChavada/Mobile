import Foundation

actor PendingLogQueue {
    private let fileURL: URL
    private var cache: [DraftLog] = []

    init(filename: String = "pending-logs.json") {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        fileURL = base.appending(path: filename)
    }

    func load() async {
        do {
            let data = try Data(contentsOf: fileURL)
            cache = try JSONDecoder().decode([DraftLog].self, from: data)
        } catch {
            cache = []
        }
    }

    func enqueue(_ draft: DraftLog) async throws {
        cache.append(draft)
        try persist()
    }

    func remove(_ temporaryID: UUID) async throws {
        cache.removeAll { $0.temporaryID == temporaryID }
        try persist()
    }

    func all() async -> [DraftLog] {
        cache
    }

    private func persist() throws {
        let data = try JSONEncoder().encode(cache)
        try data.write(to: fileURL, options: .atomic)
    }
}
