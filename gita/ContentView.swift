import SwiftUI
import WebKit
import Combine

@main
struct GitaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class BrowserEngine: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView

    // make sure to update SwiftUI after WKWebView updates
    @Published var currentURL: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var pageTitle: String = ""
    @Published var isSecure: Bool = false

    private var observations: [NSKeyValueObservation] = []

    override init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        self.webView.navigationDelegate = self

        observations = [
            webView.observe(\.url) { [weak self] webView, _ in
                self?.currentURL = webView.url?.absoluteString ?? ""
            },
            webView.observe(\.isLoading) { [weak self] webView, _ in
                self?.isLoading = webView.isLoading
            },
            webView.observe(\.canGoBack) { [weak self] webView, _ in
                self?.canGoBack = webView.canGoBack
            },
            webView.observe(\.canGoForward) { [weak self] webView, _ in
                self?.canGoForward = webView.canGoForward
            },
            webView.observe(\.title) { [weak self] webView, _ in
                self?.pageTitle = webView.title ?? ""
            },
        ]

        // doesn't look like an unidentifiable bot
        let fallbackUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
        self.webView.customUserAgent = fallbackUA

        // upgrade if possible
        self.upgradeToNativeUserAgent()

        // upgradeToNativeUserAgent is async, user may start as fallback agent before upgrading to user agent
        if let url = URL(string: "https://duckduckgo.com") {
            self.webView.load(URLRequest(url: url))
        }
    }

    private func upgradeToNativeUserAgent() {
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
                self.webView.customUserAgent = productionUA
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

    func goBack() { webView.goBack() }
    func goForward() { webView.goForward() }
    func reload() { webView.reload() }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        isSecure = webView.url?.scheme == "https"
    }
}

struct ContentView: View {
    @StateObject private var engine = BrowserEngine()

    var body: some View {
        VStack(spacing: 0) {
            AddressBar(engine: engine)
            BrowserView(webView: engine.webView)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct AddressBar: View {
    @ObservedObject var engine: BrowserEngine
    @State private var textFieldURL: String = ""

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
        .onChange(of: engine.currentURL) { _, newValue in
            textFieldURL = newValue
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
