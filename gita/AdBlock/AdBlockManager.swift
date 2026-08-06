import Foundation
import Observation
import WebKit

enum AdBlockShieldState: Equatable {
  case loading
  case active
  case off
  case allowedForSite
}

@Observable
@MainActor
final class AdBlockManager {
  static let shared = AdBlockManager()

  private(set) var revision = 0

  private let ruleInstaller = ContentRuleInstaller()
  private var manifest: FiltersVersionManifest?
  private var engineLoaded = false
  private var rulesReadyHandlers: [() -> Void] = []
  private var webViewProvider: (() -> [WKWebView])?

  private init() {}

  var isRulesReady: Bool { ruleInstaller.isReady }

  func registerWebViewProvider(_ provider: @escaping () -> [WKWebView]) {
    webViewProvider = provider
  }

  func shieldState(for tab: Tab?) -> AdBlockShieldState {
    guard AdBlockSettings.shared.isEnabled else { return .off }
    guard isRulesReady, engineLoaded else { return .loading }
    guard let host = tab?.host else { return .active }
    if AdBlockSiteSettings.shared.isAllowed(host: host) { return .allowedForSite }
    return .active
  }

  func setEnabled(_ enabled: Bool) {
    AdBlockSettings.shared.isEnabled = enabled
  }

  func disableOnCurrentSite(tab: Tab?) {
    guard let host = tab?.host, !host.isEmpty else {
      return
    }
    AdBlockSiteSettings.shared.allow(host: host)
    applyPolicyToAllTabs(reloadWebView: tab?.webView)
  }

  func enableOnCurrentSite(tab: Tab?) {
    guard let host = tab?.host, !host.isEmpty else {
      return
    }
    AdBlockSiteSettings.shared.remove(host: host)
    applyPolicyToAllTabs(reloadWebView: tab?.webView)
  }

  func toggleEnabled(reloadWebView: WKWebView? = nil) {
    setEnabled(!AdBlockSettings.shared.isEnabled)
    applyPolicyToAllTabs(reloadWebView: reloadWebView)
  }

  func start(bundle: Bundle = .main) async {
    guard AdBlockSettings.shared.isEnabled else { return }

    do {
      let manifest = try FiltersVersionManifest.load(from: bundle)
      self.manifest = manifest
      try loadEngineIfNeeded(bundle: bundle)
      try await ruleInstaller.prepare(manifest: manifest, bundle: bundle)
      notifyRulesReady()
      applyPolicyToAllTabs()
      bumpRevision()
    } catch {
      print("AdBlockManager.start failed: \(error.localizedDescription)")
    }
  }

  func onRulesReady(_ handler: @escaping () -> Void) {
    if ruleInstaller.isReady {
      handler()
    } else {
      rulesReadyHandlers.append(handler)
    }
  }

  func applyContentRules(to configuration: WKWebViewConfiguration) {
    guard shouldApplyNetworkRules else { return }
    let controller = configuration.userContentController
    for list in ruleInstaller.compiledRuleLists {
      controller.add(list)
    }
  }

  func retrofitContentRules(on webViews: [WKWebView]) {
    guard shouldApplyNetworkRules, ruleInstaller.isReady else { return }
    for webView in webViews {
      syncContentRules(on: webView)
    }
  }

  func syncPolicy(for webView: WKWebView, url: URL) {
    syncContentRules(on: webView, targetURL: url)
    prepareCosmetics(for: webView, url: url)
  }

  func prepareCosmetics(for webView: WKWebView, url: URL) {
    guard isActive(for: url) else {
      webView.configuration.userContentController.removeAllUserScripts()
      return
    }

    let host = url.host ?? ""
    do {
      let injections = try cosmeticInjections(url.absoluteString, host, true)
      let controller = webView.configuration.userContentController
      controller.removeAllUserScripts()

      for script in try CosmeticInjector.userScripts(url: url.absoluteString, tabHost: host) {
        controller.addUserScript(script)
      }

      if webView.url != nil {
        CosmeticInjector.injectIntoPage(injections, in: webView)
      }
    } catch {
      print("AdBlock cosmetic injection failed: \(error.localizedDescription)")
    }
  }

  func shouldBlock(navigationAction: WKNavigationAction, sourceURL: URL?) -> Bool {
    guard isActive else { return false }
    return AdBlockNavigationPolicy.shouldBlock(
      navigationAction: navigationAction,
      sourceURL: sourceURL
    )
  }

  private var shouldApplyNetworkRules: Bool {
    AdBlockSettings.shared.isEnabled && engineLoaded && ruleInstaller.isReady
  }

  private var isActive: Bool {
    shouldApplyNetworkRules
  }

  private func isActive(for url: URL) -> Bool {
    guard isActive else { return false }
    guard let host = url.host else { return false }
    return !AdBlockSiteSettings.shared.isAllowed(host: host)
  }

  private func loadEngineIfNeeded(bundle: Bundle) throws {
    guard !engineLoaded else { return }
    guard
      let url = AdBlockResourcePaths.url(
        forResource: "engine",
        withExtension: "dat",
        bundle: bundle
      )
    else {
      throw AdBlockError.missingResource("engine.dat")
    }

    let data = try Data(contentsOf: url)
    try loadEngine(data)
    engineLoaded = true
  }

  private func notifyRulesReady() {
    let handlers = rulesReadyHandlers
    rulesReadyHandlers.removeAll()
    for handler in handlers {
      handler()
    }
  }

  private func applyPolicyToAllTabs(reloadWebView: WKWebView? = nil) {
    let webViews = webViewProvider?() ?? []
    for webView in webViews {
      syncContentRules(on: webView)
      if let url = webView.url {
        prepareCosmetics(for: webView, url: url)
      }
    }
    reloadWebView?.reload()
    bumpRevision()
  }

  private func bumpRevision() {
    revision += 1
  }

  private func syncContentRules(on webView: WKWebView, targetURL: URL? = nil) {
    let controller = webView.configuration.userContentController
    controller.removeAllContentRuleLists()

    guard shouldApplyNetworkRules else { return }
    let url = targetURL ?? webView.url
    guard let url, isActive(for: url) else { return }

    for list in ruleInstaller.compiledRuleLists {
      controller.add(list)
    }
  }
}
