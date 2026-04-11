import Testing
import Foundation
@testable import NetworkKit

@Suite("HTTPClient", .serialized)
struct HTTPClientTests {

    private func makeClient(interceptors: [any Interceptor] = []) -> HTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        return HTTPClient(baseURL: URL(string: "http://localhost")!, session: session, interceptors: interceptors)
    }

    private func stubResponse(
        statusCode: Int = 200,
        data: Data = Data(),
        headers: [String: String] = [:]
    ) {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!
            return (data, response)
        }
    }

    @Test("decodes successful JSON response")
    func decodedResponse() async throws {
        let json = try JSONEncoder().encode(TestUser(id: 1, name: "Taha"))
        stubResponse(data: json)

        let client = makeClient()
        let user: TestUser = try await client.request(TestEndpoint.simple)
        #expect(user.id == 1)
        #expect(user.name == "Taha")
    }

    @Test("throws decodingFailed on invalid JSON")
    func decodingFailed() async {
        stubResponse(data: Data("not json".utf8))
        let client = makeClient()
        do {
            let _: TestUser = try await client.request(TestEndpoint.simple)
            Issue.record("Should have thrown")
        } catch let error as NetworkError {
            if case .decodingFailed = error { } else {
                Issue.record("Expected .decodingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected NetworkError")
        }
    }

    @Test("returns raw response")
    func rawResponse() async throws {
        let data = Data("hello".utf8)
        stubResponse(data: data)
        let client = makeClient()
        let response = try await client.requestRaw(TestEndpoint.simple)
        #expect(response.data == data)
        #expect(response.statusCode == 200)
    }

    @Test("send completes without error on 200")
    func sendVoid() async throws {
        stubResponse(statusCode: 204)
        let client = makeClient()
        try await client.send(TestEndpoint.simple)
    }

    @Test("throws unauthorized on 401")
    func unauthorized() async {
        stubResponse(statusCode: 401)
        let client = makeClient()
        do {
            try await client.send(TestEndpoint.simple)
            Issue.record("Should have thrown")
        } catch let error as NetworkError {
            if case .unauthorized = error { } else {
                Issue.record("Expected .unauthorized, got \(error)")
            }
        } catch {
            Issue.record("Expected NetworkError")
        }
    }

    @Test("throws notFound on 404")
    func notFound() async {
        stubResponse(statusCode: 404)
        let client = makeClient()
        do {
            try await client.send(TestEndpoint.simple)
            Issue.record("Should have thrown")
        } catch let error as NetworkError {
            if case .notFound = error { } else {
                Issue.record("Expected .notFound, got \(error)")
            }
        } catch {
            Issue.record("Expected NetworkError")
        }
    }

    @Test("throws serverError on 500")
    func serverError() async {
        stubResponse(statusCode: 500)
        let client = makeClient()
        do {
            try await client.send(TestEndpoint.simple)
            Issue.record("Should have thrown")
        } catch let error as NetworkError {
            if case .serverError(let code) = error {
                #expect(code == 500)
            } else {
                Issue.record("Expected .serverError, got \(error)")
            }
        } catch {
            Issue.record("Expected NetworkError")
        }
    }

    @Test("retry interceptor retries on failure then succeeds")
    func retryThenSucceed() async throws {
        var callCount = 0
        let json = try JSONEncoder().encode(TestUser(id: 1, name: "OK"))
        MockURLProtocol.handler = { request in
            callCount += 1
            let statusCode = callCount == 1 ? 500 : 200
            let data = callCount == 1 ? Data() : json
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }

        let client = makeClient(interceptors: [RetryInterceptor(maxRetries: 2, baseDelay: 0.01)])
        let user: TestUser = try await client.request(TestEndpoint.simple)
        #expect(user.name == "OK")
        #expect(callCount == 2)
    }
}
