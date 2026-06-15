import Foundation
import WebKit

extension BrowserEngine {
    func createNewTab(with urlString: String = "https://duckduckgo.com") -> TabItem {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        
        let fallbackUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
        webView.customUserAgent = fallbackUA
        
        let tab = TabItem(
            id: UUID(),
            title: "New Tab",
            url: urlString,
            isSecure: false,
            lastActiveTime: Date(),
            webView: webView
        )
        
        upgradeToNativeUserAgent(for: webView)
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        
        return tab
    }

    func addNewTab(urlString: String = "https://duckduckgo.com") {
        let tab = createNewTab(with: urlString)
        tabs.append(tab)
        selectTab(id: tab.id)
    }

    func selectTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        activeTabId = id
        tabs[index].lastActiveTime = Date()
        
        if tabs[index].webView == nil {
            restoreTab(at: index)
        }
        
        if let webView = tabs[index].webView {
            self.activeWebView = webView
            self.currentURL = webView.url?.absoluteString ?? ""
            self.isLoading = webView.isLoading
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
            self.pageTitle = webView.title ?? ""
            self.isSecure = webView.hasOnlySecureContent
            
            setupObservations(for: webView)
        }
        
        enforceLRULimit()
    }

    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let closedTab = tabs.remove(at: index)
        closedTab.webView?.stopLoading()
        closedTab.webView?.navigationDelegate = nil
        
        if activeTabId == id {
            if !tabs.isEmpty {
                let newIndex = min(index, tabs.count - 1)
                selectTab(id: tabs[newIndex].id)
            } else {
                addNewTab()
            }
        }
    }

    func restoreTab(at index: Int) {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        
        let fallbackUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
        webView.customUserAgent = fallbackUA
        
        tabs[index].webView = webView
        upgradeToNativeUserAgent(for: webView)
        
        if let state = tabs[index].interactionState {
            webView.interactionState = state
        } else if let url = URL(string: tabs[index].url) {
            webView.load(URLRequest(url: url))
        }
    }

    func suspendTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        guard tabs[index].id != activeTabId else { return }
        guard let webView = tabs[index].webView else { return }
        
        tabs[index].interactionState = webView.interactionState
        webView.stopLoading()
        webView.navigationDelegate = nil
        tabs[index].webView = nil
        print("Suspended background tab: \(tabs[index].title)")
    }

    func enforceLRULimit() {
        let activeTabs = tabs.filter { $0.webView != nil && $0.id != activeTabId }
        guard activeTabs.count > 3 else { return } // Max 4 active (1 active, 3 background)
        
        if let oldest = activeTabs.min(by: { $0.lastActiveTime < $1.lastActiveTime }),
           let index = tabs.firstIndex(where: { $0.id == oldest.id }) {
            suspendTab(at: index)
        }
    }

    func startInactivityTimer() {
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            for i in 0..<self.tabs.count {
                let tab = self.tabs[i]
                if tab.id != self.activeTabId && tab.webView != nil {
                    let idleTime = now.timeIntervalSince(tab.lastActiveTime)
                    if idleTime > 600 { // 10 minutes
                        self.suspendTab(at: i)
                    }
                }
            }
        }
    }

    func setupMemoryPressureListener() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: DispatchQueue.main)
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            print("Low memory signal. Suspending all background tabs.")
            self.suspendAllBackgroundTabs()
        }
        source.resume()
        self.memoryPressureSource = source
    }

    func suspendAllBackgroundTabs() {
        for i in 0..<tabs.count {
            if tabs[i].id != activeTabId {
                suspendTab(at: i)
            }
        }
    }

    func upgradeToNativeUserAgent(for webView: WKWebView) {
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

            DispatchQueue.main.async {
                webView.customUserAgent = productionUA
                print("Strategy A Active. Production UA: \(productionUA)")
            }
        }
    }

    func extractWebKitVersion(from ua: String) -> String? {
        guard let range = ua.range(of: "AppleWebKit/") else { return nil }
        let subString = ua[range.upperBound...]
        if let spaceIndex = subString.firstIndex(of: " ") {
            return String(subString[..<spaceIndex])
        }
        return String(subString)
    }

    func updateTabState(for webView: WKWebView) {
        let title = webView.title ?? ""
        let url = webView.url?.absoluteString ?? ""
        let isSecure = webView.hasOnlySecureContent
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let index = self.tabs.firstIndex(where: { $0.webView === webView }) else { return }
            
            self.tabs[index].title = title.isEmpty ? "New Tab" : title
            self.tabs[index].url = url
            self.tabs[index].isSecure = isSecure
            
            if self.tabs[index].id == self.activeTabId {
                self.currentURL = url
                self.pageTitle = title
                self.isSecure = isSecure
            }
        }
    }
}
