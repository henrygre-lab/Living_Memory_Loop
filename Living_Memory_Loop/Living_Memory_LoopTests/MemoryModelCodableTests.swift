import XCTest
@testable import Living_Memory_Loop

final class MemoryModelCodableTests: XCTestCase {
    func testDecodesSnakeCaseKeysAndTimestampMillis() throws {
        let json = """
        {
          "id": "abc-123",
          "title": "Morning Plan",
          "category": "Work",
          "action_items": ["Send recap", "Schedule demo"],
          "completed_items": [1],
          "mood": "determined",
          "transcript": "Need to send recap and schedule a demo.",
          "createdAt": 1739310300000,
          "pinned": true
        }
        """

        let memory = try JSONDecoder().decode(Memory.self, from: Data(json.utf8))

        XCTAssertEqual(memory.id, "abc-123")
        XCTAssertEqual(memory.actionItems, ["Send recap", "Schedule demo"])
        XCTAssertEqual(memory.completedItems, [1])
        XCTAssertEqual(memory.createdAt.timeIntervalSince1970, 1_739_310_300, accuracy: 0.001)
        XCTAssertTrue(memory.pinned)
    }

    func testDecodesMissingCompletedItemsAsEmptyArray() throws {
        let json = """
        {
          "id": "abc-123",
          "title": "Morning Plan",
          "category": "Work",
          "action_items": ["Send recap"],
          "mood": "determined",
          "transcript": "Need to send recap.",
          "createdAt": 1739310300000,
          "pinned": false
        }
        """

        let memory = try JSONDecoder().decode(Memory.self, from: Data(json.utf8))
        XCTAssertEqual(memory.completedItems, [])
    }

    func testEncodesSnakeCaseKeysAndTimestampMillis() throws {
        let memory = Memory(
            id: "xyz-999",
            title: "Quick Reminder",
            category: "Personal",
            actionItems: ["Call mom"],
            completedItems: [],
            mood: "calm",
            transcript: "Call mom later",
            createdAt: Date(timeIntervalSince1970: 1_739_310_300),
            pinned: false
        )

        let data = try JSONEncoder().encode(memory)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(object?["action_items"] as? [String], ["Call mom"])
        XCTAssertEqual(object?["completed_items"] as? [Int], [])
        let createdAt = object?["createdAt"] as? Double
        XCTAssertNotNil(createdAt)
        XCTAssertEqual(createdAt ?? 0, 1_739_310_300_000, accuracy: 0.001)
    }
}
