import Foundation
import WebKit

@MainActor
final class AdBlockManager {
  static let shared = AdBlockManager()

  private let ruleInstaller = ContentRuleInstaller()
  private var manifest: FiltersVersionManifest?
  private var engineLoaded = false
  private var rulesReadyHandlers: [() -> Void] = []

  private init() {}

  var isRulesReady: Bool { ruleInstaller.isReady }

  func start(bundle: Bundle = .main) async {
    guard AdBlockSettings.shared.isEnabled else { return }

    do {
      let manifest = try FiltersVersionManifest.load(from: bundle)
      self.manifest = manifest
      try loadEngineIfNeeded(bundle: bundle)
      try await ruleInstaller.prepare(manifest: manifest, bundle: bundle)
      notifyRulesReady()
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
    guard isActive else { return }
    let controller = configuration.userContentController
    for list in ruleInstaller.compiledRuleLists {
      controller.add(list)
    }
  }

  func retrofitContentRules(on webViews: [WKWebView]) {
    guard isActive, ruleInstaller.isReady else { return }
    for webView in webViews {
      applyContentRules(to: webView.configuration)
    }
  }

  func prepareCosmetics(for webView: WKWebView, url: URL) {
    guard isActive(for: url) else { return }

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

  private var isActive: Bool {
    AdBlockSettings.shared.isEnabled && engineLoaded
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
}
