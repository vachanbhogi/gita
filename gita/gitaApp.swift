import SwiftUI

@main
struct GitaApp: App {
  let engine = BrowserEngine()

  var body: some Scene {
    WindowGroup {
      ContentView(engine: engine)
        .frame(minWidth: 1100, minHeight: 720)
    }
    .commands { AppCommands(engine: engine) }
    .windowStyle(.hiddenTitleBar)
  }
}
