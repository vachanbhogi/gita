import WebKit

enum AdBlockWebViewConfigurator {
  @MainActor
  static func apply(to configuration: WKWebViewConfiguration) {
    AdBlockManager.shared.applyContentRules(to: configuration)
  }
}
