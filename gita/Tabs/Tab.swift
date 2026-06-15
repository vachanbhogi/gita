import Foundation
import WebKit
import Combine

enum TabState {
    case active(WKWebView)
    case loading(WKWebView, progress: Double)
    case suspended(interactionState: Any?, lastURL: URL)
    case failed(title: String, message: String, failingURL: URL)
}

class Tab: NSObject, ObservableObject, WKNavigationDelegate, Identifiable {
    let id: UUID
    @Published var title: String
    @Published var state: TabState
    var lastActiveTime: Date
    private var observations: [NSKeyValueObservation] = []
    var failedURL: String?
    
    init(id: UUID = UUID(), title: String = "New Tab", state: TabState, lastActiveTime: Date = Date()) {
        self.id = id
        self.title = title
        self.state = state
        self.lastActiveTime = lastActiveTime
        super.init()
        
        if let webView = self.webView {
            webView.navigationDelegate = self
            setupObservations(for: webView)
        }
    }
    
    var webView: WKWebView? {
        switch state {
        case .active(let wv), .loading(let wv, _):
            return wv
        default:
            return nil
        }
    }

    var url: String {
        switch state {
        case .active(let wv), .loading(let wv, _):
            return wv.url?.absoluteString ?? ""
        case .suspended(_, let lastURL):
            return lastURL.absoluteString
        case .failed(_, _, let failingURL):
            return failingURL.absoluteString
        }
    }

    var isSecure: Bool {
        switch state {
        case .active(let wv), .loading(let wv, _):
            return wv.hasOnlySecureContent
        default:
            return false
        }
    }

    var interactionState: Any? {
        switch state {
        case .suspended(let interactionState, _):
            return interactionState
        default:
            return nil
        }
    }

    var isLoading: Bool {
        switch state {
        case .loading:
            return true
        default:
            return false
        }
    }

    var canGoBack: Bool {
        webView?.canGoBack ?? false
    }

    var canGoForward: Bool {
        webView?.canGoForward ?? false
    }

    func setupObservations(for webView: WKWebView) {
        observations.forEach { $0.invalidate() }
        observations = [
            webView.observe(\.url) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                    self?.updateMetadata(for: webView)
                }
            },
            webView.observe(\.isLoading) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            },
            webView.observe(\.canGoBack) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            },
            webView.observe(\.canGoForward) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            },
            webView.observe(\.title) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                    self?.updateMetadata(for: webView)
                }
            },
            webView.observe(\.hasOnlySecureContent) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                    self?.updateMetadata(for: webView)
                }
            },
        ]
    }
    
    private func updateMetadata(for webView: WKWebView) {
        let title = webView.title ?? ""
        self.title = title.isEmpty ? "New Tab" : title
        
        let progress = webView.estimatedProgress
        if webView.isLoading {
            self.state = .loading(webView, progress: progress)
        } else {
            self.state = .active(webView)
        }
    }
    
    func navigate(to input: String) {
        failedURL = nil
        guard let webView = webView else { return }
        
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

        webView.load(URLRequest(url: url))
    }

    func goBack() { failedURL = nil; webView?.goBack() }
    func goForward() { failedURL = nil; webView?.goForward() }
    
    func reload() {
        if let failedURL, !failedURL.isEmpty {
            navigate(to: failedURL)
            self.failedURL = nil
        } else {
            webView?.reload()
        }
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            self?.failedURL = nil
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error, for: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error, for: webView)
    }

    private func handleNavigationError(_ error: Error, for webView: WKWebView) {
        let nsError = error as NSError
        let url = (nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL)?.absoluteString
            ?? (webView.url?.absoluteString ?? "")
        let failingURL = URL(string: url) ?? URL(string: "https://duckduckgo.com")!

        let title: String
        let message: String

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

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.failedURL = url
            self.state = .failed(title: title, message: message, failingURL: failingURL)
        }

        showErrorPage(title: title, message: message, url: url, on: webView)
    }

    private func showErrorPage(title: String, message: String, url: String, on webView: WKWebView) {
        let html = """
        <html>
        <body style="font-family:system-ui,-apple-system;padding:2em 1.5em;background:#f5f5f7;color:#1d1d1f">
        <h2 style="font-weight:600;font-size:1.3em">\(title)</h2>
        <p style="color:#86868b">\(message)</p>
        <p style="font-size:0.85em;color:#aeaeb2;word-break:break-all">\(url)</p>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
