import XCTest
@testable import gita

class URLCanonicalizerTests: XCTestCase {
  func testStripsBasicAuthCredentials() {
    let url = URL(string: "https://user:password123@example.com/path?utm_source=test")!
    let canonical = URLCanonicalizer.canonicalize(url)

    XCTAssertEqual(canonical?.absoluteString, "https://example.com/path")
  }
}
