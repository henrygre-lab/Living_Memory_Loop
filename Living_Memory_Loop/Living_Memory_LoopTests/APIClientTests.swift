import XCTest
@testable import Living_Memory_Loop

final class APIClientTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.lastRequest = nil
        MockURLProtocol.lastRequestBody = nil
    }

    func testProcessMemorySuccessDecodesSnakeCaseResponse() async throws {
        let session = makeSession()
        let baseURL = URL(string: "https://api.example.com")!
        let client = APIClient(baseURL: baseURL, session: session, timeoutInterval: 15)

        MockURLProtocol.requestHandler = { request in
            let data = """
            {
              "transcript": "Buy milk this afternoon",
              "title": "Afternoon Grocery Plan",
              "category": "Shopping",
              "action_items": ["Buy milk"],
              "mood": "determined"
            }
            """.data(using: .utf8)!

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, data)
        }

        let response = try await client.processMemory(audioBase64: "abc123")
        let request = try XCTUnwrap(MockURLProtocol.lastRequest)
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/api/process-memory")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.timeoutInterval, 15, accuracy: 0.001)

        let body = try XCTUnwrap(MockURLProtocol.lastRequestBody)
        let payload = try JSONSerialization.jsonObject(with: body) as? [String: String]
        XCTAssertEqual(payload?["audio"], "abc123")

        XCTAssertEqual(response.title, "Afternoon Grocery Plan")
        XCTAssertEqual(response.actionItems, ["Buy milk"])
        XCTAssertEqual(response.mood, "determined")
    }

    func testProcessMemoryMaps400ToBadRequest() async {
        let session = makeSession()
        let client = APIClient(baseURL: URL(string: "https://api.example.com")!, session: session)

        MockURLProtocol.requestHandler = { request in
            let data = #"{"error":"Could not transcribe audio. Please try again."}"#.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        do {
            _ = try await client.processMemory(audioBase64: "abc123")
            XCTFail("Expected APIError.badRequest")
        } catch let error as APIError {
            XCTAssertEqual(error, .badRequest("Could not transcribe audio. Please try again."))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessMemoryMaps413ToTooLarge() async {
        let session = makeSession()
        let client = APIClient(baseURL: URL(string: "https://api.example.com")!, session: session)

        MockURLProtocol.requestHandler = { request in
            let data = #"{"error":"Recording was too long. Please keep it under 60 seconds."}"#.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 413,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        do {
            _ = try await client.processMemory(audioBase64: "abc123")
            XCTFail("Expected APIError.tooLarge")
        } catch let error as APIError {
            XCTAssertEqual(error, .tooLarge("Recording was too long. Please keep it under 60 seconds."))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessMemoryMapsServerErrorPlainTextMessage() async {
        let session = makeSession()
        let client = APIClient(baseURL: URL(string: "https://api.example.com")!, session: session)

        MockURLProtocol.requestHandler = { request in
            let data = Data("oops".utf8)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        do {
            _ = try await client.processMemory(audioBase64: "abc123")
            XCTFail("Expected APIError.serverError")
        } catch let error as APIError {
            XCTAssertEqual(error, .serverError("oops"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessMemoryMapsServerErrorStripsHTML() async {
        let session = makeSession()
        let client = APIClient(baseURL: URL(string: "https://api.example.com")!, session: session)

        MockURLProtocol.requestHandler = { request in
            let data = Data("<html><body><h1>500 Server Error</h1></body></html>".utf8)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        do {
            _ = try await client.processMemory(audioBase64: "abc123")
            XCTFail("Expected APIError.serverError")
        } catch let error as APIError {
            XCTAssertEqual(error, .serverError("500 Server Error"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastRequestBody: Data?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            fatalError("Set MockURLProtocol.requestHandler before using this mock.")
        }

        do {
            Self.lastRequest = request
            Self.lastRequestBody = Self.bodyData(from: request)
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func bodyData(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)

        while true {
            let readCount = stream.read(&buffer, maxLength: buffer.count)
            if readCount > 0 {
                data.append(buffer, count: readCount)
            } else {
                break
            }
        }

        return data.isEmpty ? nil : data
    }
}
