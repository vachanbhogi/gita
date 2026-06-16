import SwiftUI
import WebKit

struct BrowserView: NSViewRepresentable {
  let webView: WKWebView

  func makeNSView(context: Context) -> NSView {
    let container = NSView()
    addWebView(webView, to: container)
    return container
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    guard nsView.subviews.first !== webView else { return }
    nsView.subviews.forEach { $0.removeFromSuperview() }
    addWebView(webView, to: nsView)
  }

  private func addWebView(_ wv: WKWebView, to container: NSView) {
    wv.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(wv)
    NSLayoutConstraint.activate([
      wv.topAnchor.constraint(equalTo: container.topAnchor),
      wv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      wv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      wv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }
}
