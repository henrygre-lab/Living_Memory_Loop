import XCTest
@testable import Living_Memory_Loop

final class MemoryStoreSortTests: XCTestCase {
    @MainActor
    func testSortsPinnedFirstThenNewestFirst() {
        let oldUnpinned = Memory(
            id: "1",
            title: "old",
            category: "Other",
            actionItems: [],
            completedItems: [],
            mood: "neutral",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 1_000),
            pinned: false
        )
        let newUnpinned = Memory(
            id: "2",
            title: "new",
            category: "Other",
            actionItems: [],
            completedItems: [],
            mood: "neutral",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 2_000),
            pinned: false
        )
        let oldPinned = Memory(
            id: "3",
            title: "pinned-old",
            category: "Other",
            actionItems: [],
            completedItems: [],
            mood: "neutral",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 500),
            pinned: true
        )
        let newPinned = Memory(
            id: "4",
            title: "pinned-new",
            category: "Other",
            actionItems: [],
            completedItems: [],
            mood: "neutral",
            transcript: "",
            createdAt: Date(timeIntervalSince1970: 3_000),
            pinned: true
        )

        let sorted = MemoryStore.sortMemories([oldUnpinned, newUnpinned, oldPinned, newPinned])
        XCTAssertEqual(sorted.map(\.id), ["4", "3", "2", "1"])
    }
}
