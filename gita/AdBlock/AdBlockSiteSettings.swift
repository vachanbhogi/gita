import Foundation

@MainActor
final class AdBlockSiteSettings {
  static let shared = AdBlockSiteSettings()

  private static let allowlistKey = "gita.adblockSiteAllowlist"
  private var cachedAllowlistedHosts: Set<String>?
  private let lock = NSLock()

  private init() {}

  // ⚡ Bolt: Cache `allowlistedHosts` to avoid repeated UserDefaults access and implicit `Set`
  // allocations on WKNavigationDelegate critical paths. We use NSLock for thread safety.
  private var allowlistedHosts: Set<String> {
    get {
      lock.lock()
      defer { lock.unlock() }

      if let cached = cachedAllowlistedHosts {
        return cached
      }

      let stored = UserDefaults.standard.stringArray(forKey: Self.allowlistKey) ?? []
      let value = Set(stored.map { $0.lowercased() })
      cachedAllowlistedHosts = value
      return value
    }
    set {
      lock.lock()
      cachedAllowlistedHosts = newValue
      UserDefaults.standard.set(Array(newValue).sorted(), forKey: Self.allowlistKey)
      lock.unlock()
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
