import Foundation

@MainActor
final class AdBlockSiteSettings {
  static let shared = AdBlockSiteSettings()

  private static let allowlistKey = "gita.adblockSiteAllowlist"

  // ⚡ Bolt Optimization: In-memory cache to avoid repeated disk reads and string allocations on the critical navigation path
  private var cachedAllowlist: Set<String>?
  private let lock = NSLock()

  private init() {}

  private var allowlistedHosts: Set<String> {
    get {
      lock.lock()
      defer { lock.unlock() }

      if let cached = cachedAllowlist {
        return cached
      }
      let stored = UserDefaults.standard.stringArray(forKey: Self.allowlistKey) ?? []
      let parsed = Set(stored.map { $0.lowercased() })
      cachedAllowlist = parsed
      return parsed
    }
    set {
      lock.lock()
      defer { lock.unlock() }

      cachedAllowlist = newValue
      UserDefaults.standard.set(Array(newValue).sorted(), forKey: Self.allowlistKey)
    }
  }

  func isAllowed(host: String) -> Bool {
    let normalized = host.lowercased()
    guard !normalized.isEmpty else { return false }
    return allowlistedHosts.contains(normalized)
  }

  func allow(host: String) {
    var hosts = allowlistedHosts
    hosts.insert(host.lowercased())
    allowlistedHosts = hosts
  }

  func remove(host: String) {
    var hosts = allowlistedHosts
    hosts.remove(host.lowercased())
    allowlistedHosts = hosts
  }
}
