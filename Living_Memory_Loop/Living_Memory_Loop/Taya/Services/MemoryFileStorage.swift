import Foundation

protocol MemoryPersisting: Sendable {
    func loadMemories() async throws -> [Memory]
    func saveMemories(_ memories: [Memory]) async throws
}

actor MemoryFileStorage: MemoryPersisting {
    private let fileURL: URL

    init(fileName: String = "memories.json") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        fileURL = documentsDirectory.appendingPathComponent(fileName)
    }

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func loadMemories() async throws -> [Memory] {
        let url = fileURL
        return try await Task.detached(priority: .userInitiated) {
            guard FileManager.default.fileExists(atPath: url.path()) else {
                return []
            }

            let data = try Data(contentsOf: url)
            guard !data.isEmpty else {
                return []
            }

            let decoder = JSONDecoder()
            return try decoder.decode([Memory].self, from: data)
        }.value
    }

    func saveMemories(_ memories: [Memory]) async throws {
        let url = fileURL
        try await Task.detached(priority: .utility) {
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(memories)
            try data.write(to: url, options: .atomic)
        }.value
    }
}
