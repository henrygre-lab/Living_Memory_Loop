import Foundation

nonisolated struct ProcessMemoryRequest: Codable, Sendable {
    let audio: String
}

nonisolated struct ProcessMemoryResponse: Codable, Equatable, Sendable {
    let transcript: String
    let title: String
    let category: String
    let actionItems: [String]
    let mood: String

    enum CodingKeys: String, CodingKey {
        case transcript
        case title
        case category
        case actionItems = "action_items"
        case mood
    }
}

nonisolated enum APIError: LocalizedError, Equatable, Sendable {
    case invalidBaseURL(String)
    case invalidResponse
    case badRequest(String)
    case tooLarge(String)
    case serverError(String)
    case transport(String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case let .invalidBaseURL(message):
            return message
        case .invalidResponse:
            return "Invalid server response."
        case let .badRequest(message):
            return message
        case let .tooLarge(message):
            return message
        case let .serverError(message):
            return message
        case let .transport(message):
            return message
        case let .decoding(message):
            return message
        }
    }
}
