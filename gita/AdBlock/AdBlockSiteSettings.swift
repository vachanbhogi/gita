import Foundation

@MainActor
final class AdBlockSiteSettings {
  static let shared = AdBlockSiteSettings()

  private static let allowlistKey = "gita.adblockSiteAllowlist"

  private init() {}

  private var allowlistedHosts: Set<String> {
    get {
      let stored = UserDefaults.standard.stringArray(forKey: Self.allowlistKey) ?? []
      return Set(stored.map { $0.lowercased() })
    }
    set {
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
