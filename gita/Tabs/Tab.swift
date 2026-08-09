import Foundation
import Observation
import WebKit

@Observable
@MainActor
class Tab: NSObject, WKNavigationDelegate, Identifiable {
  let id: UUID
  var title: String
  var state: TabState
  var lastActiveTime: Date
  private var observations: [NSKeyValueObservation] = []
  private var pendingNavigationType: WKNavigationType?
  var failedURL: String?

  var url: String = "" {
    didSet {
      updateHost()
    }
  }
  var host: String = ""
  var isSecure: Bool = false
  var canGoBack: Bool = false
  var canGoForward: Bool = false
  var faviconURL: URL? = nil

  init(id: UUID = UUID(), title: String = "New Tab", state: TabState, lastActiveTime: Date = Date())
  {
    self.id = id
    self.title = title
    self.state = state
    self.lastActiveTime = lastActiveTime
    super.init()

    if let webView = self.webView {
      webView.navigationDelegate = self
      setupObservations(for: webView)

      self.url = webView.url?.absoluteString ?? ""
      self.updateHost()
      if let host = webView.url?.host {
        self.faviconURL = URL(string: "https://www.google.com/s2/favicons?sz=32&domain=\(host)")
      }
      self.isSecure = webView.hasOnlySecureContent
      self.canGoBack = webView.canGoBack
      self.canGoForward = webView.canGoForward
    } else {
      self.updateHost()
    }
  }

  private func updateHost() {
    // ⚡ Bolt Optimization: Cache derived host directly on the @Observable model.
    // This prevents expensive repetitive URL(string:) parsing in SwiftUI rendering loops.
    guard !url.isEmpty, let parsedURL = URL(string: url), let parsedHost = parsedURL.host else {
      self.host = ""
      return
    }
    self.host = parsedHost.hasPrefix("www.") ? String(parsedHost.dropFirst(4)) : parsedHost
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

  var isSuspended: Bool {
    if case .suspended = state { return true }
    return false
  }

  func setupObservations(for webView: WKWebView) {
    for observation in observations { observation.invalidate() }
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
          let title = webView.title ?? ""
          self.title = title.isEmpty ? "New Tab" : title
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

    // Prevent direct execution of javascript or access to local files from address bar.
    // Parse the URL securely and check the scheme instead of relying on String.hasPrefix()
    // to catch bypasses using obfuscation with invisible characters (e.g. zero-width space).
    if let parsedURL = URL(string: trimmed), let scheme = parsedURL.scheme?.lowercased() {
      if scheme == "javascript" || scheme == "file" {
        return
      }
    }

    // Heuristic: contains a dot without a space → likely a hostname, not a search query
    let url: URL
    if trimmed.contains("://") || trimmed.contains(".") && !trimmed.contains(" ") {
      let withScheme = trimmed.contains("://") ? trimmed : "https://" + trimmed
      guard let resolved = URL(string: withScheme) else { return }
      url = resolved
    } else {
      guard let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        let searchURL = URL(string: "https://duckduckgo.com/?q=\(query)")
      else { return }
      url = searchURL
    }

    // Defense in depth: Verify the final resolved URL scheme is not malicious
    if let scheme = url.scheme?.lowercased(), scheme == "javascript" || scheme == "file" {
      return
    }

    webView.load(URLRequest(url: url))
  }

  func goBack() {
    failedURL = nil
    webView?.goBack()
  }

  func goForward() {
    failedURL = nil
    webView?.goForward()
  }

  func go(to item: WKBackForwardListItem) {
    failedURL = nil
    webView?.go(to: item)
  }

  var backMenuItems: [WKBackForwardListItem] {
    guard let list = webView?.backForwardList else { return [] }
    return Self.collapsedStackItems(Array(list.backList.reversed()))
  }

  var forwardMenuItems: [WKBackForwardListItem] {
    guard let list = webView?.backForwardList else { return [] }
    return Self.collapsedStackItems(Array(list.forwardList))
  }

  private static func collapsedStackItems(_ items: [WKBackForwardListItem])
    -> [WKBackForwardListItem]
  {
    guard !items.isEmpty else { return [] }
    var result: [WKBackForwardListItem] = []
    // ⚡ Bolt Optimization: Cache repeated string transformations like `.lowercased()`
    // to prevent O(N) allocation churn inside the loop.
    var lastDomain = ""
    for item in items {
      let domain = item.url.host?.lowercased() ?? ""
      if !result.isEmpty, lastDomain == domain, !domain.isEmpty {
        result[result.count - 1] = item
      } else {
        result.append(item)
        lastDomain = domain
      }
    }
    return result
  }

  func reload() {
    if let failedURL, !failedURL.isEmpty {
      navigate(to: failedURL)
      self.failedURL = nil
    } else {
      webView?.reload()
    }
  }

  func stopLoading() {
    webView?.stopLoading()
  }

  // MARK: - WKNavigationDelegate

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    if let url = navigationAction.request.url {
      let scheme = url.scheme?.lowercased()

      if scheme == "gita" && url.host == "reload" {
        decisionHandler(.cancel)
        self.reload()
        return
      }

      if scheme == "javascript" || scheme == "file" {
        decisionHandler(.cancel)
        return
      }
    }

    if AdBlockManager.shared.shouldBlock(
      navigationAction: navigationAction,
      sourceURL: webView.url
    ) {
      decisionHandler(.cancel)
      return
    }

    if navigationAction.targetFrame?.isMainFrame == true,
      let targetURL = navigationAction.request.url
    {
      AdBlockManager.shared.syncPolicy(for: webView, url: targetURL)
    }

    pendingNavigationType = navigationAction.navigationType
    decisionHandler(.allow)
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    Task { @MainActor [weak self] in
      self?.failedURL = nil
      if let wv = self?.webView {
        self?.state = .loading(wv, progress: 0)
      }
    }
  }

  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    Task { @MainActor [weak self] in
      guard self != nil, let url = webView.url else { return }
      AdBlockManager.shared.syncPolicy(for: webView, url: url)
    }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    Task { @MainActor [weak self] in
      guard let self = self else { return }

      let navigationType = self.pendingNavigationType ?? .other
      self.pendingNavigationType = nil
      let isErrorPage = if case .failed = self.state { true } else { false }

      if !isErrorPage {
        self.state = .active(webView)
        let title = webView.title ?? ""
        self.title = title.isEmpty ? "New Tab" : title
      }

      guard !isErrorPage, self.failedURL == nil, let url = webView.url else { return }
      HistoryStore.shared.recordVisit(url: url, title: self.title, navigationType: navigationType)
    }
  }

  func webView(
    _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    handleNavigationError(error, for: webView)
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    handleNavigationError(error, for: webView)
  }

  private func handleNavigationError(_ error: Error, for webView: WKWebView) {
    let nsError = error as NSError

    // Ignore cancelled errors (e.g. from our decidePolicyFor blocking)
    if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
      return
    }

    let url =
      (nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL)?.absoluteString
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

    ErrorPageRenderer.show(title: title, message: message, url: url, on: webView)
  }
}
