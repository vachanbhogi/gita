import Foundation
import WebKit

extension BrowserEngine {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if webView === self.activeWebView {
                self.failedURL = nil
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error, for: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error, for: webView)
    }

    func handleNavigationError(_ error: Error, for webView: WKWebView) {
        let nsError = error as NSError
        let title: String
        let message: String
        let url = (nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL)?.absoluteString
            ?? (webView.url?.absoluteString ?? "")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if webView === self.activeWebView {
                self.failedURL = url
            }
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

        showErrorPage(title: title, message: message, url: url, on: webView)
    }

    func showErrorPage(title: String, message: String, url: String, on webView: WKWebView) {
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
