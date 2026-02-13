import Foundation

nonisolated struct Memory: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var title: String
    var category: String
    var actionItems: [String]
    var completedItems: [Int]
    var mood: String
    var transcript: String
    var createdAt: Date
    var pinned: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case actionItems = "action_items"
        case completedItems = "completed_items"
        case mood
        case transcript
        case createdAt
        case pinned
    }

    init(
        id: String = UUID().uuidString,
        title: String = "Untitled Memory",
        category: String = "Other",
        actionItems: [String] = [],
        completedItems: [Int] = [],
        mood: String = "neutral",
        transcript: String = "",
        createdAt: Date = .now,
        pinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.actionItems = actionItems
        self.completedItems = completedItems
        self.mood = mood
        self.transcript = transcript
        self.createdAt = createdAt
        self.pinned = pinned
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        actionItems = try container.decode([String].self, forKey: .actionItems)
        completedItems = try container.decodeIfPresent([Int].self, forKey: .completedItems) ?? []
        mood = try container.decode(String.self, forKey: .mood)
        transcript = try container.decode(String.self, forKey: .transcript)
        pinned = try container.decode(Bool.self, forKey: .pinned)

        let timestampMillis = try container.decode(Double.self, forKey: .createdAt)
        createdAt = Date(timeIntervalSince1970: timestampMillis / 1_000)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encode(actionItems, forKey: .actionItems)
        try container.encode(completedItems, forKey: .completedItems)
        try container.encode(mood, forKey: .mood)
        try container.encode(transcript, forKey: .transcript)
        try container.encode(createdAt.timeIntervalSince1970 * 1_000, forKey: .createdAt)
        try container.encode(pinned, forKey: .pinned)
    }
}
