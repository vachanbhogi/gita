import SwiftUI

@MainActor
struct ShieldsButton: View {
  var engine: BrowserEngine
  @Bindable private var adBlock = AdBlockManager.shared

  private var state: AdBlockShieldState {
    _ = adBlock.revision
    return adBlock.shieldState(for: engine.activeTab)
  }

  private var icon: String {
    switch state {
    case .loading: "shield"
    case .active: "shield.fill"
    case .off, .allowedForSite: "shield.slash"
    }
  }

  private var tooltip: String {
    switch state {
    case .loading: "Shields loading…"
    case .active: "Shields up — ads and trackers blocked"
    case .off: "Shields down — blocking disabled"
    case .allowedForSite: "Shields down for this site"
    }
  }

  private var isSiteAllowed: Bool {
    guard let urlString = engine.activeTab?.url,
      let host = URL(string: urlString)?.host
    else { return false }
    return AdBlockSiteSettings.shared.isAllowed(host: host)
  }

  var body: some View {
    ChromeButton(icon: icon, size: 12.5, tooltip: tooltip) {
      AdBlockManager.shared.toggleEnabled(reloadWebView: engine.activeTab?.webView)
    }
    .contextMenu {
      Button(AdBlockSettings.shared.isEnabled ? "Turn Shields Off" : "Turn Shields On") {
        AdBlockManager.shared.toggleEnabled(reloadWebView: engine.activeTab?.webView)
      }

      if let tab = engine.activeTab {
        Divider()

        if isSiteAllowed {
          Button("Enable Shields on This Site") {
            AdBlockManager.shared.enableOnCurrentSite(tab: tab)
          }
        } else {
          Button("Disable Shields on This Site") {
            AdBlockManager.shared.disableOnCurrentSite(tab: tab)
          }
        }
      }
    }
    .opacity(state == .loading ? 0.55 : 1)
  }
}
