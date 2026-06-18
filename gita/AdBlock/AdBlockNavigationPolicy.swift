import Foundation
import WebKit

enum AdBlockNavigationPolicy {
  static func shouldBlock(
    navigationAction: WKNavigationAction,
    sourceURL: URL?
  ) -> Bool {
    guard navigationAction.targetFrame?.isMainFrame ?? false else { return false }
    guard let requestURL = navigationAction.request.url else { return false }
    guard let scheme = requestURL.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
      return false
    }

    let host = requestURL.host ?? ""
    guard !AdBlockSiteSettings.shared.isAllowed(host: host) else { return false }

    let source = sourceURL?.absoluteString ?? requestURL.absoluteString
    do {
      return try checkNetworkUrl(
        requestURL.absoluteString,
        source,
        "main_frame"
      )
    } catch {
      return false
    }
  }
}
