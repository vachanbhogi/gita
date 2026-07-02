import XCTest
@testable import gita

class gitaTests: XCTestCase {

    func testURLCanonicalizerStripsBasicAuth() {
        let urlWithAuth = URL(string: "https://user:password123@example.com/path?utm_source=test")!
        let canonicalizedURL = URLCanonicalizer.canonicalize(urlWithAuth)

        XCTAssertNotNil(canonicalizedURL)
        XCTAssertEqual(canonicalizedURL?.absoluteString, "https://example.com/path")
        XCTAssertNil(canonicalizedURL?.user)
        XCTAssertNil(canonicalizedURL?.password)
    }
}
