import Foundation
import WebKit

enum TabState {
  case active(WKWebView)
  case loading(WKWebView, progress: Double)
  case suspended(interactionState: Any?, lastURL: URL)
  case failed(title: String, message: String, failingURL: URL)
}
