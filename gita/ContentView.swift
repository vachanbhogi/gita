import SwiftUI

struct ContentView: View {
    @State private var engine = BrowserEngine.shared

    var body: some View {
        ZStack(alignment: .top) {
            // True liquid glass: transparent window blends with desktop
            TransparentWindow()

            // Main base layer: Single full-window material blur
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Unified Safari-style chrome bar inside the title bar space
                ChromeBar(engine: engine)

                // Web content — fills everything below
                webContent
            }
        }
        .frame(minWidth: 1100, minHeight: 720)
        // CRITICAL: Tells macOS to draw your SwiftUI views over the title bar area
        .ignoresSafeArea(.container, edges: .top)
    }

    @ViewBuilder
    private var webContent: some View {
        if let activeTab = engine.activeTab {
            if let webView = activeTab.webView {
                BrowserView(webView: webView)
                    .id(activeTab.id)
                    // Solid canvas background under webpage (Safari separate sheet style)
                    .background(Color(NSColor.windowBackgroundColor))
            } else {
                ZStack {
                    Color(NSColor.windowBackgroundColor)
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.secondary)
                        Text("Restoring tab…")
                            .font(.system(size: 12.5, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "No Tabs Open",
                systemImage: "safari",
                description: Text("Press Cmd+T or click '+' to open a new tab and start browsing.")
            )
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}
