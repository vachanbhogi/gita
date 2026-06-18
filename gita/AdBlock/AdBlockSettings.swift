import Foundation

@MainActor
final class AdBlockSettings {
  static let shared = AdBlockSettings()

  private static let enabledKey = "gita.adblockEnabled"

  private init() {}

  var isEnabled: Bool {
    get {
      if UserDefaults.standard.object(forKey: Self.enabledKey) == nil { return true }
      return UserDefaults.standard.bool(forKey: Self.enabledKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
    }
  }
}
