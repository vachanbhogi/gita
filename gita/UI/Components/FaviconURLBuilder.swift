import Foundation

enum FaviconURLBuilder {
  static func url(forDomain domain: String) -> URL? {
    guard !domain.isEmpty else { return nil }
    return URL(string: "https://www.google.com/s2/favicons?sz=32&domain=\(domain)")
  }
}
