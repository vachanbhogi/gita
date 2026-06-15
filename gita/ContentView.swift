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

class BrowserEngine: ObservableObject {
    let webView: WKWebView
    
    init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        
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
}

struct ContentView: View {
    @StateObject private var engine = BrowserEngine()
    
    var body: some View {
        BrowserView(webView: engine.webView)
            .frame(minWidth: 800, minHeight: 600)
    }
}

struct BrowserView: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
