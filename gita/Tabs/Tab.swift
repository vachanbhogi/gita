import Foundation
import WebKit
import Observation

enum TabState {
    case active(WKWebView)
    case loading(WKWebView, progress: Double)
    case suspended(interactionState: Any?, lastURL: URL)
    case failed(title: String, message: String, failingURL: URL)
}

@Observable
@MainActor
class Tab: NSObject, WKNavigationDelegate, Identifiable {
    let id: UUID
    var title: String
    var state: TabState
    var lastActiveTime: Date
    private var observations: [NSKeyValueObservation] = []
    var failedURL: String?
    
    var url: String = ""
    var isSecure: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var faviconURL: URL? = nil
    
    init(id: UUID = UUID(), title: String = "New Tab", state: TabState, lastActiveTime: Date = Date()) {
        self.id = id
        self.title = title
        self.state = state
        self.lastActiveTime = lastActiveTime
        super.init()
        
        if let webView = self.webView {
            webView.navigationDelegate = self
            setupObservations(for: webView)
            
            self.url = webView.url?.absoluteString ?? ""
            if let host = webView.url?.host {
                self.faviconURL = URL(string: "https://www.google.com/s2/favicons?sz=32&domain=\(host)")
            }
            self.isSecure = webView.hasOnlySecureContent
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
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

    func setupObservations(for webView: WKWebView) {
        observations.forEach { $0.invalidate() }
        observations = [
            webView.observe(\.url) { [weak self] webView, _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let urlString = webView.url?.absoluteString ?? ""
                    self.url = urlString
                    if let url = webView.url, let host = url.host {
                        self.faviconURL = URL(string: "https://www.google.com/s2/favicons?sz=32&domain=\(host)")
                    } else {
                        self.faviconURL = nil
                    }
                    self.updateMetadata(for: webView)
                }
            },
            webView.observe(\.isLoading) { [weak self] webView, _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.updateMetadata(for: webView)
                }
            },
            webView.observe(\.canGoBack) { [weak self] webView, _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.canGoBack = webView.canGoBack
                }
            },
            webView.observe(\.canGoForward) { [weak self] webView, _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.canGoForward = webView.canGoForward
                }
            },
            webView.observe(\.title) { [weak self] webView, _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.updateMetadata(for: webView)
                }
            },
            webView.observe(\.hasOnlySecureContent) { [weak self] webView, _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.isSecure = webView.hasOnlySecureContent
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
        Task { @MainActor [weak self] in
            self?.failedURL = nil
            if let wv = self?.webView {
                self?.state = .loading(wv, progress: 0)
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor [weak self] in
            self?.state = .active(webView)
            let title = webView.title ?? ""
            self?.title = title.isEmpty ? "New Tab" : title
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

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.failedURL = url
            self.state = .failed(title: title, message: message, failingURL: failingURL)
        }

        showErrorPage(title: title, message: message, url: url, on: webView)
    }

    private func showErrorPage(title: String, message: String, url: String, on webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f7;
            color: #1d1d1f;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            text-align: center;
        }
        .container {
            max-width: 480px;
            padding: 40px 20px;
        }
        h1 {
            font-size: 22px;
            font-weight: 600;
            margin-bottom: 8px;
            color: #1d1d1f;
        }
        p {
            font-size: 14px;
            color: #86868b;
            line-height: 1.4;
            margin-top: 0;
            margin-bottom: 24px;
        }
        .url-text {
            font-size: 12px;
            color: #aeaeb2;
            word-break: break-all;
            margin-bottom: 32px;
        }
        .button {
            display: inline-block;
            background-color: #0071e3;
            color: #ffffff;
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 500;
            text-decoration: none;
            transition: background-color 0.15s ease;
        }
        .button:hover {
            background-color: #0077ed;
        }
        .button:active {
            background-color: #0062c3;
        }
        @media (prefers-color-scheme: dark) {
            body {
                background-color: #1e1e1f;
                color: #f5f5f7;
            }
            h1 {
                color: #f5f5f7;
            }
            p {
                color: #86868b;
            }
            .url-text {
                color: #636366;
            }
            .button {
                background-color: #0a84ff;
            }
            .button:hover {
                background-color: #2094ff;
            }
            .button:active {
                background-color: #006cdb;
            }
        }
        </style>
        </head>
        <body>
        <div class="container">
            <h1>\(title)</h1>
            <p>\(message)</p>
            <div class="url-text">\(url)</div>
            <a class="button" href="javascript:window.location.reload()">Reload Page</a>
        </div>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
