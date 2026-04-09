import Testing
import Foundation
@testable import NetworkKit

@Suite("URLRequest+Endpoint")
struct URLRequestEndpointTests {

    private let encoder = JSONEncoder()

    @Test("builds correct URL from base + path")
    func urlConstruction() throws {
        let request = try URLRequest(TestEndpoint.simple, encoder: encoder)
        #expect(request.url?.absoluteString == "https://api.test.com/test")
    }

    @Test("appends query items")
    func queryItems() throws {
        let request = try URLRequest(TestEndpoint.withQuery(page: 3), encoder: encoder)
        #expect(request.url?.query == "page=3")
    }

    @Test("empty query items don't add ?")
    func noQueryItems() throws {
        let request = try URLRequest(TestEndpoint.simple, encoder: encoder)
        #expect(request.url?.query == nil)
    }

    @Test("sets HTTP method")
    func httpMethod() throws {
        let get = try URLRequest(TestEndpoint.simple, encoder: encoder)
        let post = try URLRequest(TestEndpoint.withJSON(TestBody(name: "a", age: 1)), encoder: encoder)
        #expect(get.httpMethod == "GET")
        #expect(post.httpMethod == "POST")
    }

    @Test("sets custom headers")
    func customHeaders() throws {
        let request = try URLRequest(TestEndpoint.withHeaders, encoder: encoder)
        #expect(request.value(forHTTPHeaderField: "X-Custom") == "value")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("encodes JSON body")
    func jsonBody() throws {
        let body = TestBody(name: "Taha", age: 25)
        let request = try URLRequest(TestEndpoint.withJSON(body), encoder: encoder)
        let decoded = try JSONDecoder().decode(TestBody.self, from: request.httpBody!)
        #expect(decoded.name == "Taha")
        #expect(decoded.age == 25)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("encodes form URL body")
    func formBody() throws {
        let request = try URLRequest(TestEndpoint.withForm(["key": "val"]), encoder: encoder)
        let bodyString = String(data: request.httpBody!, encoding: .utf8)!
        #expect(bodyString.contains("key=val"))
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }

    @Test("sets raw data body")
    func dataBody() throws {
        let data = Data([0x89, 0x50, 0x4E, 0x47])
        let request = try URLRequest(TestEndpoint.withData(data), encoder: encoder)
        #expect(request.httpBody == data)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "image/png")
    }
}
