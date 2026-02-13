import XCTest
@testable import Living_Memory_Loop

@MainActor
final class MemoryStoreTests: XCTestCase {
    func testToggleActionItemAddsThenRemovesIndexAndPersists() async {
        let memory = Memory(
            title: "Planning Notes",
            category: "Work",
            actionItems: ["Book room", "Share agenda"],
            completedItems: [],
            mood: "determined",
            transcript: "Book a room and share the agenda.",
            createdAt: Date(timeIntervalSince1970: 1_000),
            pinned: false
        )
        let storage = MockMemoryStorage()
        let store = MemoryStore(memories: [memory], isLoading: false, storage: storage)

        await store.toggleActionItem(memoryId: memory.id, index: 1)
        XCTAssertEqual(store.getMemory(id: memory.id)?.completedItems, [1])

        await store.toggleActionItem(memoryId: memory.id, index: 1)
        XCTAssertEqual(store.getMemory(id: memory.id)?.completedItems, [])

        let snapshot = await storage.snapshot()
        XCTAssertEqual(snapshot.saveCount, 2)
        XCTAssertEqual(snapshot.saved.first?.completedItems, [])
    }

    func testSortedMemoriesKeepsPinnedFirstThenNewest() async {
        let olderPinned = Memory(
            id: "A",
            title: "Pinned Older",
            category: "Work",
            actionItems: [],
            completedItems: [],
            mood: "calm",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 1_000),
            pinned: true
        )
        let newerUnpinned = Memory(
            id: "B",
            title: "Unpinned Newer",
            category: "Work",
            actionItems: [],
            completedItems: [],
            mood: "calm",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 3_000),
            pinned: false
        )
        let newerPinned = Memory(
            id: "C",
            title: "Pinned Newer",
            category: "Work",
            actionItems: [],
            completedItems: [],
            mood: "calm",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 2_000),
            pinned: true
        )

        let storage = MockMemoryStorage()
        let store = MemoryStore(
            memories: [newerUnpinned, olderPinned, newerPinned],
            isLoading: false,
            storage: storage
        )

        XCTAssertEqual(store.sortedMemories.map(\.id), ["C", "A", "B"])
    }

    func testLoadMemoriesFailureSetsLastErrorAndClearsList() async {
        let initial = Memory(
            id: "existing",
            title: "Existing",
            category: "Other",
            actionItems: [],
            completedItems: [],
            mood: "neutral",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 1_000),
            pinned: false
        )
        let storage = MockMemoryStorage(loaded: [initial], loadError: DummyError.failedLoad)
        let store = MemoryStore(memories: [initial], isLoading: false, storage: storage)

        await store.loadMemories()

        XCTAssertEqual(store.memories, [])
        XCTAssertEqual(store.lastErrorMessage, "Failed to load memories.")
    }

    func testSaveFailureSetsLastErrorMessage() async {
        let storage = MockMemoryStorage(saveError: DummyError.failedSave)
        let store = MemoryStore(memories: [], isLoading: false, storage: storage)

        let memory = Memory(
            id: "new-memory",
            title: "New",
            category: "Other",
            actionItems: [],
            completedItems: [],
            mood: "neutral",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 1_000),
            pinned: false
        )

        await store.addMemory(memory)

        XCTAssertEqual(store.memories.map(\.id), ["new-memory"])
        XCTAssertEqual(store.lastErrorMessage, "Failed to save memories.")
    }

    func testToggleActionItemIgnoresOutOfRangeIndices() async {
        let memory = Memory(
            id: "range-test",
            title: "Checklist",
            category: "Work",
            actionItems: ["One task"],
            completedItems: [],
            mood: "neutral",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 1_000),
            pinned: false
        )
        let storage = MockMemoryStorage()
        let store = MemoryStore(memories: [memory], isLoading: false, storage: storage)

        await store.toggleActionItem(memoryId: memory.id, index: 99)

        XCTAssertEqual(store.getMemory(id: memory.id)?.completedItems, [])
        let snapshot = await storage.snapshot()
        XCTAssertEqual(snapshot.saveCount, 0)
    }

    func testClearLastErrorClearsMessage() async {
        let storage = MockMemoryStorage()
        let store = MemoryStore(memories: [], isLoading: false, storage: storage)
        store.lastErrorMessage = "Failed to save memories."

        store.clearLastError()

        XCTAssertNil(store.lastErrorMessage)
    }
}

actor MockMemoryStorage: MemoryPersisting {
    private var loaded: [Memory]
    private let loadError: Error?
    private let saveError: Error?
    private(set) var saved: [Memory]
    private(set) var saveCount = 0

    init(
        loaded: [Memory] = [],
        loadError: Error? = nil,
        saveError: Error? = nil
    ) {
        self.loaded = loaded
        self.loadError = loadError
        self.saveError = saveError
        self.saved = loaded
    }

    func loadMemories() async throws -> [Memory] {
        if let loadError {
            throw loadError
        }
        return loaded
    }

    func saveMemories(_ memories: [Memory]) async throws {
        if let saveError {
            throw saveError
        }
        saved = memories
        saveCount += 1
    }

    func snapshot() -> (saved: [Memory], saveCount: Int) {
        (saved, saveCount)
    }
}

private enum DummyError: Error {
    case failedLoad
    case failedSave
}
