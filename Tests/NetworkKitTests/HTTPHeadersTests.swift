import Testing
import Foundation
@testable import NetworkKit

@Suite("HTTPHeaders")
struct HTTPHeadersTests {

    @Test("case-insensitive access")
    func caseInsensitive() {
        let headers = HTTPHeaders(["Content-Type": "application/json"])
        #expect(headers["content-type"] == "application/json")
        #expect(headers["CONTENT-TYPE"] == "application/json")
        #expect(headers["Content-Type"] == "application/json")
    }

    @Test("multi-value support")
    func multiValue() {
        let headers = HTTPHeaders(["Set-Cookie": "a=1", "set-cookie": "b=2"])
        let values = headers.values(for: "Set-Cookie")
        #expect(values.count == 2)
    }

    @Test("missing header returns nil")
    func missingHeader() {
        let headers = HTTPHeaders(["X-Foo": "bar"])
        #expect(headers["X-Missing"] == nil)
        #expect(headers.values(for: "X-Missing").isEmpty)
    }
}
