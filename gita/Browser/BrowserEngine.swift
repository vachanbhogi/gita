import Foundation
import Observation
import SwiftUI
import WebKit

@Observable
@MainActor
class BrowserEngine {
  var tabs: [Tab] = []
  var activeTabId: UUID = UUID()
  var activeTab: Tab? = nil

  private var inactivityTimer: Timer?
  private var memoryPressureSource: DispatchSourceMemoryPressure?

  private static let fallbackUserAgent =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
  private static var cachedUserAgent: String?

  init() {
    // Initialize with a default tab
    AdBlockManager.shared.onRulesReady { [weak self] in
      guard let self else { return }
      self.retrofitAdBlockRules()
    }
    let defaultTab = createNewTab(with: "https://duckduckgo.com")
    self.tabs = [defaultTab]
    self.activeTabId = defaultTab.id
    self.activeTab = defaultTab
    setup()
  }

  private func setup() {
    AdBlockManager.shared.registerWebViewProvider { [weak self] in
      self?.tabs.compactMap(\.webView) ?? []
    }
    startInactivityTimer()
    setupMemoryPressureListener()
  }

  func createNewTab(with urlString: String = "https://duckduckgo.com") -> Tab {
    let config = WKWebViewConfiguration()
    // 🛡️ Sentinel: Enable Safe Browsing to block known phishing and malware sites.
    if #available(macOS 10.15, *) {
      config.preferences.isFraudulentWebsiteWarningEnabled = true
    }
    AdBlockWebViewConfigurator.apply(to: config)
    let webView = WKWebView(frame: .zero, configuration: config)
    webView.setValue(true, forKey: "drawsBackground")

    // Set a Safari-matching UA immediately so page requests get the right UA.
    // upgradeToNativeUserAgent replaces this with the real native UA once it loads.
    webView.customUserAgent = Self.fallbackUserAgent

    let tab = Tab(
      id: UUID(),
      title: "New Tab",
      state: .active(webView),
      lastActiveTime: Date()
    )

    upgradeToNativeUserAgent(for: webView)
    if let url = URL(string: urlString) {
      // Defense in depth: Verify the final resolved URL scheme is not malicious
      let scheme = url.scheme?.lowercased()
      if scheme != "javascript" && scheme != "file" {
        webView.load(URLRequest(url: url))
      }
    }

    return tab
  }

  func addNewTab(urlString: String = "https://duckduckgo.com", uiState: UIState) {
    let tab = createNewTab(with: urlString)
    _ = withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
      tabs.append(tab)
      selectTab(id: tab.id)
      uiState.sidebarFocusedIndex = tabs.count - 1
    }
  }

  func selectTab(id: UUID) {
    guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
    activeTabId = id
    activeTab = tabs[index]
    tabs[index].lastActiveTime = Date()

    if tabs[index].webView == nil {
      restoreTab(at: index)
    }

    enforceLRULimit()
  }

  func closeTab(id: UUID, uiState: UIState) {
    guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
    let closedTab = tabs[index]
    closedTab.webView?.stopLoading()
    closedTab.webView?.navigationDelegate = nil

    _ = withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
      tabs.remove(at: index)
    }

    if activeTabId == id {
      if !tabs.isEmpty {
        let newIndex = min(index, tabs.count - 1)
        selectTab(id: tabs[newIndex].id)
      } else {
        addNewTab(uiState: uiState)
      }
    }

    if uiState.sidebarFocusedIndex >= tabs.count {
      uiState.sidebarFocusedIndex = max(0, tabs.count - 1)
    }
  }

  func selectNextTab() {
    guard !tabs.isEmpty else { return }
    if let currentIndex = tabs.firstIndex(where: { $0.id == activeTabId }) {
      let nextIndex = (currentIndex + 1) % tabs.count
      selectTab(id: tabs[nextIndex].id)
    }
  }

  func selectPreviousTab() {
    guard !tabs.isEmpty else { return }
    if let currentIndex = tabs.firstIndex(where: { $0.id == activeTabId }) {
      let prevIndex = (currentIndex - 1 + tabs.count) % tabs.count
      selectTab(id: tabs[prevIndex].id)
    }
  }

  func selectTab(at index: Int) {
    guard index >= 0 && index < tabs.count else { return }
    selectTab(id: tabs[index].id)
  }

  func selectLastTab() {
    guard !tabs.isEmpty else { return }
    selectTab(id: tabs[tabs.count - 1].id)
  }

  func toggleSidebarFocus(uiState: UIState) {
    if uiState.isSidebarFocused {
      uiState.isSidebarFocused = false
    } else {
      focusSidebar(uiState: uiState)
    }
  }

  func focusSidebar(uiState: UIState) {
    if !uiState.isVerticalTabs {
      _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
        uiState.isVerticalTabs = true
        uiState.sidebarVisible = true
      }
    } else if !uiState.sidebarVisible {
      _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
        uiState.sidebarVisible = true
      }
    }

    if let activeIndex = tabs.firstIndex(where: { $0.id == activeTabId }) {
      uiState.sidebarFocusedIndex = activeIndex
    } else {
      uiState.sidebarFocusedIndex = 0
    }

    uiState.isSidebarFocused = true
  }

  private func restoreTab(at index: Int) {
    let config = WKWebViewConfiguration()
    // 🛡️ Sentinel: Enable Safe Browsing to block known phishing and malware sites.
    if #available(macOS 10.15, *) {
      config.preferences.isFraudulentWebsiteWarningEnabled = true
    }
    AdBlockWebViewConfigurator.apply(to: config)
    let webView = WKWebView(frame: .zero, configuration: config)
    webView.setValue(true, forKey: "drawsBackground")

    webView.customUserAgent = Self.fallbackUserAgent

    let savedState = tabs[index].interactionState
    let savedURL = tabs[index].url

    webView.navigationDelegate = tabs[index]
    tabs[index].state = .active(webView)
    tabs[index].setupObservations(for: webView)
    upgradeToNativeUserAgent(for: webView)

    if let state = savedState {
      webView.interactionState = state
    } else if let url = URL(string: savedURL) {
      // Defense in depth: Verify the final resolved URL scheme is not malicious
      let scheme = url.scheme?.lowercased()
      if scheme != "javascript" && scheme != "file" {
        webView.load(URLRequest(url: url))
      }
    }
  }

  private func suspendTab(at index: Int) {
    guard index >= 0 && index < tabs.count else { return }
    guard tabs[index].id != activeTabId else { return }
    guard let webView = tabs[index].webView else { return }

    let interactionState = webView.interactionState
    let lastURL =
      webView.url ?? URL(string: tabs[index].url) ?? URL(string: "https://duckduckgo.com")!

    webView.stopLoading()
    webView.navigationDelegate = nil

    tabs[index].state = .suspended(interactionState: interactionState, lastURL: lastURL)
    print("Suspended background tab: \(tabs[index].title)")
  }

  private func enforceLRULimit() {
    // Keep at most 4 tabs loaded (1 active + 3 background), suspend the oldest
    var activeBackgroundCount = 0
    var oldestIndex: Int?
    var oldestTime: Date?

    for (index, tab) in tabs.enumerated() {
      if tab.webView != nil && tab.id != activeTabId {
        activeBackgroundCount += 1

        let time = tab.lastActiveTime
        if oldestTime == nil || time < oldestTime! {
          oldestTime = time
          oldestIndex = index
        }
      }
    }

    if activeBackgroundCount > 3, let indexToSuspend = oldestIndex {
      suspendTab(at: indexToSuspend)
    }
  }

  // Suspend background tabs idle for 10+ minutes to reclaim resources
  private func startInactivityTimer() {
    inactivityTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      Task { @MainActor [weak self] in
        guard let self = self else { return }
        let now = Date()
        for i in 0..<self.tabs.count {
          let tab = self.tabs[i]
          if tab.id != self.activeTabId && tab.webView != nil {
            let idleTime = now.timeIntervalSince(tab.lastActiveTime)
            if idleTime > 600 {  // 10 minutes
              self.suspendTab(at: i)
            }
          }
        }
      }
    }
  }

  private func setupMemoryPressureListener() {
    let source = DispatchSource.makeMemoryPressureSource(
      eventMask: [.warning, .critical], queue: DispatchQueue.main)
    source.setEventHandler { [weak self] in
      Task { @MainActor [weak self] in
        guard let self = self else { return }
        print("Low memory signal. Suspending all background tabs.")
        self.suspendAllBackgroundTabs()
      }
    }
    source.resume()
    self.memoryPressureSource = source
  }

  private func suspendAllBackgroundTabs() {
    for i in 0..<tabs.count {
      if tabs[i].id != activeTabId {
        suspendTab(at: i)
      }
    }
  }

  private func upgradeToNativeUserAgent(for webView: WKWebView) {
    if let cached = Self.cachedUserAgent {
      webView.customUserAgent = cached
      return
    }

    webView.evaluateJavaScript("navigator.userAgent") { [weak self] result, error in
      guard let self = self, let nativeUA = result as? String else { return }

      var productionUA = nativeUA

      if let appTokenRange = productionUA.range(of: " gita/") {
        productionUA = String(productionUA[..<appTokenRange.lowerBound])
      }

      if !productionUA.contains("Safari/") {
        let webKitVersion = self.extractWebKitVersion(from: productionUA) ?? "605.1.15"
        productionUA += " Version/18.0 Safari/\(webKitVersion)"
      }

      Self.cachedUserAgent = productionUA
      Task { @MainActor in
        webView.customUserAgent = productionUA
      }
    }
  }

  private func extractWebKitVersion(from ua: String) -> String? {
    guard let range = ua.range(of: "AppleWebKit/") else { return nil }
    let subString = ua[range.upperBound...]
    if let spaceIndex = subString.firstIndex(of: " ") {
      return String(subString[..<spaceIndex])
    }
    return String(subString)
  }

  private func retrofitAdBlockRules() {
    let webViews = tabs.compactMap(\.webView)
    AdBlockManager.shared.retrofitContentRules(on: webViews)
  }
}
