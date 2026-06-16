import SwiftUI

@main
struct GitaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1100, minHeight: 720)
        }
        .commands { AppCommands() }
        .windowStyle(.hiddenTitleBar)
    }
}
