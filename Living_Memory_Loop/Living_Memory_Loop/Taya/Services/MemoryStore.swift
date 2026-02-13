import Foundation
import Observation

@MainActor
@Observable
final class MemoryStore {
    var memories: [Memory]
    var isLoading: Bool
    var lastErrorMessage: String?
    private let storage: any MemoryPersisting

    init(
        memories: [Memory] = [],
        isLoading: Bool = false,
        storage: any MemoryPersisting = MemoryFileStorage()
    ) {
        self.memories = Self.sortMemories(memories)
        self.isLoading = isLoading
        self.storage = storage
    }

    var sortedMemories: [Memory] {
        Self.sortMemories(memories)
    }

    func loadMemories() async {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            let loaded = try await storage.loadMemories()
            memories = Self.sortMemories(loaded)
        } catch {
            memories = []
            lastErrorMessage = "Failed to load memories."
        }
    }

    func refreshMemories() async {
        await loadMemories()
    }

    func clearLastError() {
        lastErrorMessage = nil
    }

    func addMemory(_ memory: Memory) async {
        memories.insert(memory, at: 0)
        memories = Self.sortMemories(memories)
        await persistCurrentMemories()
    }

    func removeMemory(id: String) async {
        memories.removeAll { $0.id == id }
        await persistCurrentMemories()
    }

    func togglePin(id: String) async {
        guard let index = memories.firstIndex(where: { $0.id == id }) else {
            return
        }

        memories[index].pinned.toggle()
        memories = Self.sortMemories(memories)
        await persistCurrentMemories()
    }

    func toggleActionItem(memoryId: String, index: Int) async {
        guard let memoryIndex = memories.firstIndex(where: { $0.id == memoryId }) else {
            return
        }
        guard memories[memoryIndex].actionItems.indices.contains(index) else {
            return
        }

        if memories[memoryIndex].completedItems.contains(index) {
            memories[memoryIndex].completedItems.removeAll { $0 == index }
        } else {
            memories[memoryIndex].completedItems.append(index)
            memories[memoryIndex].completedItems.sort()
        }

        await persistCurrentMemories()
    }

    func getMemory(id: String) -> Memory? {
        memories.first { $0.id == id }
    }

    private func persistCurrentMemories() async {
        do {
            try await storage.saveMemories(memories)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Failed to save memories."
        }
    }

    nonisolated static func sortMemories(_ input: [Memory]) -> [Memory] {
        input.sorted { lhs, rhs in
            if lhs.pinned && !rhs.pinned {
                return true
            }
            if !lhs.pinned && rhs.pinned {
                return false
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
}
