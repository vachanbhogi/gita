import SwiftData
import SwiftUI

@main
struct GitaApp: App {
  @State private var engine = BrowserEngine()
  @State private var uiState = UIState()

  var body: some Scene {
    WindowGroup {
      ContentView(engine: engine, uiState: uiState)
        .frame(minWidth: 1100, minHeight: 720)
        .modelContainer(HistoryStore.shared.container)
    }
    .commands { AppCommands(engine: engine, uiState: uiState) }
    .windowStyle(.hiddenTitleBar)
  }
}
