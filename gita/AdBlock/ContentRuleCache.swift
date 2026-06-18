import Foundation

struct ContentRuleCache: Codable, Equatable {
  let fingerprint: String
  let ruleListIdentifiers: [String]

  private static var cacheURL: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let folder = base.appendingPathComponent("Gita/AdBlock", isDirectory: true)
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder.appendingPathComponent("content-rule-cache.json")
  }

  static func load() -> ContentRuleCache? {
    guard let data = try? Data(contentsOf: cacheURL) else { return nil }
    return try? JSONDecoder().decode(ContentRuleCache.self, from: data)
  }

  func save() {
    guard let data = try? JSONEncoder().encode(self) else { return }
    try? data.write(to: Self.cacheURL, options: .atomic)
  }

  static func isValid(for manifest: FiltersVersionManifest) -> Bool {
    guard let cached = load() else { return false }
    return cached.fingerprint == manifest.cacheFingerprint && !cached.ruleListIdentifiers.isEmpty
  }

  static func identifiers(for manifest: FiltersVersionManifest) -> [String]? {
    guard let cached = load(), cached.fingerprint == manifest.cacheFingerprint else { return nil }
    return cached.ruleListIdentifiers
  }
}
