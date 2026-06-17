import WebKit

// Generates error HTML pages and loads them into a WKWebView.
// Separated from Tab to keep model/delegate logic free of presentation concerns.
enum ErrorPageRenderer {
  static func show(title: String, message: String, url: String, on webView: WKWebView) {
    let escapedTitle = htmlEscape(title)
    let escapedMessage = htmlEscape(message)
    let escapedURL = htmlEscape(url)

    let html = """
      <!DOCTYPE html>
      <html>
      <head>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline';">
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
          <h1>\(escapedTitle)</h1>
          <p>\(escapedMessage)</p>
          <div class="url-text">\(escapedURL)</div>
          <a class="button" href="gita://reload">Reload Page</a>
      </div>
      </body>
      </html>
      """
    webView.loadHTMLString(html, baseURL: nil)
  }

  private static func htmlEscape(_ s: String) -> String {
    var result = s
    result = result.replacingOccurrences(of: "&", with: "&amp;")
    result = result.replacingOccurrences(of: "<", with: "&lt;")
    result = result.replacingOccurrences(of: ">", with: "&gt;")
    result = result.replacingOccurrences(of: "\"", with: "&quot;")
    result = result.replacingOccurrences(of: "'", with: "&#39;")
    return result
  }
}
