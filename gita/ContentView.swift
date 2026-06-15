import SwiftUI

struct ContentView: View {
    @StateObject private var engine = BrowserEngine()

    var body: some View {
        VStack(spacing: 0) {
            TabBar(engine: engine)
            Divider()
            AddressBar(engine: engine)
            BrowserView(webView: engine.activeWebView)
                .id(engine.activeTabId)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
