import XCTest
@testable import gita

final class URLCanonicalizerTests: XCTestCase {

    func testStripBasicAuthCredentials() {
        let urlWithAuth = URL(string: "https://user:password@example.com/path?q=1")!
        let canonicalizedURL = URLCanonicalizer.canonicalize(urlWithAuth)

        XCTAssertNotNil(canonicalizedURL)
        XCTAssertEqual(canonicalizedURL?.absoluteString, "https://example.com/path?q=1")
    }

    func testKeepHostAndPath() {
        let url = URL(string: "https://www.example.com/path/")!
        let canonicalizedURL = URLCanonicalizer.canonicalize(url)

        XCTAssertNotNil(canonicalizedURL)
        XCTAssertEqual(canonicalizedURL?.absoluteString, "https://example.com/path")
    }
}
