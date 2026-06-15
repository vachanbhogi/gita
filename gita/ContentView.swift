import SwiftUI

struct ContentView: View {
    @StateObject private var engine = BrowserEngine()

    var body: some View {
        VStack(spacing: 0) {
            TabBar(engine: engine)
            Divider()
            if let activeTab = engine.activeTab {
                AddressBar(tab: activeTab)
                if let webView = activeTab.webView {
                    BrowserView(webView: webView)
                        .id(activeTab.id)
                } else {
                    ProgressView()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
