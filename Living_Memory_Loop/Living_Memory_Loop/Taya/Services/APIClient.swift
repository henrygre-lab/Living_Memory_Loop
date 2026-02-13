import Foundation

nonisolated struct APIClient: Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let timeoutInterval: TimeInterval

    init(
        baseURL: URL,
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 30
    ) {
        self.baseURL = baseURL
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    init(
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 30
    ) throws {
        self.init(
            baseURL: try APIConfiguration.baseURL(),
            session: session,
            timeoutInterval: timeoutInterval
        )
    }

    func processMemory(audioBase64: String) async throws -> ProcessMemoryResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/process-memory"))
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ProcessMemoryRequest(audio: audioBase64))

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            let host = baseURL.host ?? baseURL.absoluteString
            throw APIError.transport("Network error connecting to \(host): \(error.localizedDescription)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(ProcessMemoryResponse.self, from: data)
            } catch {
                throw APIError.decoding("Invalid response payload.")
            }
        case 400:
            throw APIError.badRequest(
                extractErrorMessage(from: data, fallback: "Could not process audio")
            )
        case 413:
            throw APIError.tooLarge(
                extractErrorMessage(
                    from: data,
                    fallback: "Recording was too long. Please keep it under 60 seconds."
                )
            )
        default:
            throw APIError.serverError(
                extractErrorMessage(
                    from: data,
                    fallback: "Failed to process memory. Please try again."
                )
            )
        }
    }

    private func extractErrorMessage(from data: Data, fallback: String) -> String {
        guard !data.isEmpty else { return fallback }
        if
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = (json["error"] as? String) ?? (json["message"] as? String),
            !message.isEmpty
        {
            return message
        }

        if let text = String(data: data, encoding: .utf8) {
            let withoutTags = text.replacingOccurrences(
                of: "<[^>]+>",
                with: " ",
                options: .regularExpression
            )
            let normalized = withoutTags.replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            if !normalized.isEmpty {
                return String(normalized.prefix(220))
            }
        }

        return fallback
    }
}

nonisolated enum APIConfiguration {
    private static let key = "API_BASE_URL"

    static func baseURL() throws -> URL {
        if
            let value = ProcessInfo.processInfo.environment[key],
            let url = URL(string: value),
            url.scheme != nil
        {
            return url
        }

        if
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            let url = URL(string: value),
            url.scheme != nil
        {
            return url
        }

        #if DEBUG
        return URL(string: "http://127.0.0.1:5000")!
        #else
        throw APIError.invalidBaseURL(
            "Missing API_BASE_URL configuration. Set API_BASE_URL in Info.plist or environment."
        )
        #endif
    }
}
