import Foundation

@MainActor
final class AdBlockSettings {
  static let shared = AdBlockSettings()

  private static let enabledKey = "gita.adblockEnabled"
  private var cachedIsEnabled: Bool?
  private let lock = NSLock()

  private init() {}

  // ⚡ Bolt: Cache `isEnabled` to avoid repeated UserDefaults access on WKNavigationDelegate critical paths.
  // We use NSLock for thread safety since these callbacks can execute concurrently from background threads.
  var isEnabled: Bool {
    get {
      lock.lock()
      defer { lock.unlock() }

      if let cached = cachedIsEnabled {
        return cached
      }

      let value: Bool
      if UserDefaults.standard.object(forKey: Self.enabledKey) == nil {
        value = true
      } else {
        value = UserDefaults.standard.bool(forKey: Self.enabledKey)
      }

      cachedIsEnabled = value
      return value
    }
    set {
      lock.lock()
      cachedIsEnabled = newValue
      UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
      lock.unlock()
    }
  }
}
