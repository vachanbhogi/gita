import Foundation
import WebKit
import Network
import Observation
import SwiftUI

@Observable
@MainActor
class BrowserEngine {
    static let shared: BrowserEngine = {
        let engine = BrowserEngine()
        engine.setup()
        return engine
    }()
    
    var tabs: [Tab] = []
    var activeTabId: UUID = UUID()
    var activeTab: Tab? = nil
    
    var isOnline: Bool = true
    var isAddressBarFocused: Bool = false
    var isVerticalTabs: Bool = false
    var sidebarVisible: Bool = true

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "connectivity")
    
    private var inactivityTimer: Timer?
    private var memoryPressureSource: DispatchSourceMemoryPressure?

    init() {
        // Initialize with a default tab
        let defaultTab = createNewTab(with: "https://duckduckgo.com")
        self.tabs = [defaultTab]
        self.activeTabId = defaultTab.id
        self.activeTab = defaultTab
    }
    
    private func setup() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)

        startInactivityTimer()
        setupMemoryPressureListener()
    }
    
    func createNewTab(with urlString: String = "https://duckduckgo.com") -> Tab {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(true, forKey: "drawsBackground")
        
        let fallbackUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
        webView.customUserAgent = fallbackUA
        
        let tab = Tab(
            id: UUID(),
            title: "New Tab",
            state: .active(webView),
            lastActiveTime: Date()
        )
        
        upgradeToNativeUserAgent(for: webView)
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        
        return tab
    }

    func addNewTab(urlString: String = "https://duckduckgo.com") {
        let tab = createNewTab(with: urlString)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            tabs.append(tab)
            selectTab(id: tab.id)
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

    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
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
    }

    private func restoreTab(at index: Int) {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(true, forKey: "drawsBackground")
        
        let fallbackUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
        webView.customUserAgent = fallbackUA
        
        let savedState = tabs[index].interactionState
        let savedURL = tabs[index].url
        
        webView.navigationDelegate = tabs[index]
        tabs[index].state = .active(webView)
        tabs[index].setupObservations(for: webView)
        upgradeToNativeUserAgent(for: webView)
        
        if let state = savedState {
            webView.interactionState = state
        } else if let url = URL(string: savedURL) {
            webView.load(URLRequest(url: url))
        }
    }

    private func suspendTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        guard tabs[index].id != activeTabId else { return }
        guard let webView = tabs[index].webView else { return }
        
        let interactionState = webView.interactionState
        let lastURL = webView.url ?? URL(string: tabs[index].url) ?? URL(string: "https://duckduckgo.com")!
        
        webView.stopLoading()
        webView.navigationDelegate = nil
        
        tabs[index].state = .suspended(interactionState: interactionState, lastURL: lastURL)
        print("Suspended background tab: \(tabs[index].title)")
    }

    private func enforceLRULimit() {
        let activeTabs = tabs.filter { $0.webView != nil && $0.id != activeTabId }
        guard activeTabs.count > 3 else { return } // Max 4 active (1 active, 3 background)
        
        if let oldest = activeTabs.min(by: { $0.lastActiveTime < $1.lastActiveTime }),
           let index = tabs.firstIndex(where: { $0.id == oldest.id }) {
            suspendTab(at: index)
        }
    }

    private func startInactivityTimer() {
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
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
    }

    private func setupMemoryPressureListener() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: DispatchQueue.main)
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

            Task { @MainActor in
                webView.customUserAgent = productionUA
                print("Strategy A Active. Production UA: \(productionUA)")
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
}
