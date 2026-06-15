import Foundation
import WebKit

struct TabItem: Identifiable {
    let id: UUID
    var title: String
    var url: String
    var isSecure: Bool
    var lastActiveTime: Date
    var interactionState: Any? = nil
    var webView: WKWebView?
}
