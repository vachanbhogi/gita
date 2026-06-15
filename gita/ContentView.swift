import SwiftUI
import WebKit
import Combine
import Network

@main
struct GitaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct TabItem: Identifiable {
    let id: UUID
    var title: String
    var url: String
    var isSecure: Bool
    var lastActiveTime: Date
    var interactionState: Any? = nil
    var webView: WKWebView?
}

class BrowserEngine: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var tabs: [TabItem] = []
    @Published var activeTabId: UUID = UUID()
    @Published var activeWebView: WKWebView = WKWebView()

    // make sure to update SwiftUI after WKWebView updates
    @Published var currentURL: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var pageTitle: String = ""
    @Published var isSecure: Bool = false
    @Published var isOnline: Bool = true

    private var observations: [NSKeyValueObservation] = []
    private var failedURL: String?
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "connectivity")
    
    private var inactivityTimer: Timer?
    private var memoryPressureSource: DispatchSourceMemoryPressure?

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

    private func setupObservations(for webView: WKWebView) {
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

    private func restoreTab(at index: Int) {
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

    private func suspendTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        guard tabs[index].id != activeTabId else { return }
        guard let webView = tabs[index].webView else { return }
        
        tabs[index].interactionState = webView.interactionState
        webView.navigationDelegate = nil
        tabs[index].webView = nil
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

    private func setupMemoryPressureListener() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: DispatchQueue.main)
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            print("Low memory signal. Suspending all background tabs.")
            self.suspendAllBackgroundTabs()
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

            DispatchQueue.main.async {
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

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.failedURL = nil
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    private func handleNavigationError(_ error: Error) {
        let nsError = error as NSError
        let title: String
        let message: String
        let url = (nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL)?.absoluteString
            ?? (activeWebView.url?.absoluteString ?? "")

        DispatchQueue.main.async {
            self.failedURL = url
        }

        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                title = "No Connection"
                message = "You are offline. Check your network and try again."
            case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
                title = "Server Not Found"
                message = "Could not resolve the server address."
            case NSURLErrorTimedOut:
                title = "Connection Timed Out"
                message = "The server did not respond in time."
            case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateUntrusted:
                title = "Secure Connection Failed"
                message = "Could not establish a secure connection."
            default:
                title = "Failed to Load"
                message = error.localizedDescription
            }
        } else {
            title = "Failed to Load"
            message = error.localizedDescription
        }

        showErrorPage(title: title, message: message, url: url)
    }

    private func updateTabState(for webView: WKWebView) {
        guard let index = tabs.firstIndex(where: { $0.webView === webView }) else { return }
        
        let title = webView.title ?? ""
        let url = webView.url?.absoluteString ?? ""
        let isSecure = webView.hasOnlySecureContent
        
        DispatchQueue.main.async {
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

    private func showErrorPage(title: String, message: String, url: String) {
        let html = """
        <html>
        <body style="font-family:system-ui,-apple-system;padding:2em 1.5em;background:#f5f5f7;color:#1d1d1f">
        <h2 style="font-weight:600;font-size:1.3em">\(title)</h2>
        <p style="color:#86868b">\(message)</p>
        <p style="font-size:0.85em;color:#aeaeb2;word-break:break-all">\(url)</p>
        </body>
        </html>
        """
        activeWebView.loadHTMLString(html, baseURL: nil)
    }
}

struct ContentView: View {
    @StateObject private var engine = BrowserEngine()

    var body: some View {
        VStack(spacing: 0) {
            TabBar(engine: engine)
            Divider()
            AddressBar(engine: engine)
            BrowserView(webView: engine.activeWebView)
                .id(engine.activeTabId)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct TabBar: View {
    @ObservedObject var engine: BrowserEngine

    var body: some View {
        HStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(engine.tabs) { tab in
                        HStack(spacing: 6) {
                            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                                .font(.system(size: 11, weight: tab.id == engine.activeTabId ? .semibold : .regular))
                                .foregroundColor(tab.id == engine.activeTabId ? .primary : .secondary)
                                .lineLimit(1)
                                .frame(maxWidth: 120)

                            Button(action: {
                                engine.closeTab(id: tab.id)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .padding(2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tab.id == engine.activeTabId ? Color(.controlBackgroundColor) : Color.clear)
                        .cornerRadius(4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            engine.selectTab(id: tab.id)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            Button(action: {
                engine.addNewTab()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.plain)
            .padding(6)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.windowBackgroundColor))
    }
}

struct AddressBar: View {
    @ObservedObject var engine: BrowserEngine
    @State private var textFieldURL: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: engine.goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!engine.canGoBack)

            Button(action: engine.goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!engine.canGoForward)

            Button(action: engine.reload) {
                Image(systemName: "arrow.clockwise")
            }

            Image(systemName: engine.isSecure ? "lock.fill" : "lock.open")
                .foregroundColor(engine.isSecure ? .secondary : .orange)
                .font(.caption)

            TextField("Search or enter address", text: $textFieldURL)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.textBackgroundColor))
                .cornerRadius(6)
                .onSubmit {
                    engine.navigate(to: textFieldURL)
                }

            if engine.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16)
            }
        }
        .padding(8)
        .background(.bar)
        .onChange(of: engine.currentURL) { newValue in
            if !isFocused { textFieldURL = newValue }
        }
    }
}

struct BrowserView: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
