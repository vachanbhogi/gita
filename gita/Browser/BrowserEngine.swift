import Foundation
import WebKit
import Combine
import Network

class BrowserEngine: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var tabs: [TabItem] = []
    @Published var activeTabId: UUID = UUID()
    @Published var activeWebView: WKWebView!

    // make sure to update SwiftUI after WKWebView updates
    @Published var currentURL: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var pageTitle: String = ""
    @Published var isSecure: Bool = false
    @Published var isOnline: Bool = true

    var observations: [NSKeyValueObservation] = []
    var failedURL: String?
    let monitor = NWPathMonitor()
    let monitorQueue = DispatchQueue(label: "connectivity")
    
    var inactivityTimer: Timer?
    var memoryPressureSource: DispatchSourceMemoryPressure?

    override init() {
        super.init()

        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)

        // Initialize with a default tab
        let defaultTab = createNewTab(with: "https://duckduckgo.com")
        self.tabs = [defaultTab]
        self.activeTabId = defaultTab.id
        self.activeWebView = defaultTab.webView!
        
        setupObservations(for: defaultTab.webView!)
        
        startInactivityTimer()
        setupMemoryPressureListener()
    }
    
    deinit {
        inactivityTimer?.invalidate()
        memoryPressureSource?.cancel()
    }

    func setupObservations(for webView: WKWebView) {
        observations.forEach { $0.invalidate() }
        observations = [
            webView.observe(\.url) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.currentURL = webView.url?.absoluteString ?? ""
                    self?.updateTabState(for: webView)
                }
            },
            webView.observe(\.isLoading) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.isLoading = webView.isLoading
                }
            },
            webView.observe(\.canGoBack) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.canGoBack = webView.canGoBack
                }
            },
            webView.observe(\.canGoForward) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.canGoForward = webView.canGoForward
                }
            },
            webView.observe(\.title) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.pageTitle = webView.title ?? ""
                    self?.updateTabState(for: webView)
                }
            },
            webView.observe(\.hasOnlySecureContent) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.isSecure = webView.hasOnlySecureContent
                    self?.updateTabState(for: webView)
                }
            },
        ]
    }

    func navigate(to input: String) {
        failedURL = nil
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let url: URL
        if trimmed.contains("://") || trimmed.contains(".") && !trimmed.contains(" ") {
            let withScheme = trimmed.contains("://") ? trimmed : "https://" + trimmed
            guard let resolved = URL(string: withScheme) else { return }
            url = resolved
        } else {
            guard let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let searchURL = URL(string: "https://duckduckgo.com/?q=\(query)") else { return }
            url = searchURL
        }

        activeWebView.load(URLRequest(url: url))
    }

    func goBack() { failedURL = nil; activeWebView.goBack() }
    func goForward() { failedURL = nil; activeWebView.goForward() }
    
    func reload() {
        if let failedURL, !failedURL.isEmpty {
            navigate(to: failedURL)
            self.failedURL = nil
        } else {
            activeWebView.reload()
        }
    }
}
