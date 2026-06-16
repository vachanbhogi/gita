import SwiftUI

@main
struct GitaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Clear background to reveal the window visual effect vibrancy
                .background(Color.clear)
        }
        .windowStyle(.hiddenTitleBar)
        // Keeps the layout behavior standard while allowing the full-size content view
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            // New / Close Tab commands
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    BrowserEngine.shared.addNewTab()
                }
                
                Button("Close Tab") {
                    BrowserEngine.shared.closeTab(id: BrowserEngine.shared.activeTabId)
                }
            }
            
            // Focus location field
            CommandGroup(after: .sidebar) {
                Button("Open Location…") {
                    BrowserEngine.shared.isAddressBarFocused = true
                }
            }

            // Web Navigation commands
            CommandMenu("Navigation") {
                Button("Go Back") {
                    BrowserEngine.shared.activeTab?.goBack()
                }
                
                Button("Go Forward") {
                    BrowserEngine.shared.activeTab?.goForward()
                }
                
                Button("Reload Page") {
                    BrowserEngine.shared.activeTab?.reload()
                }
            }
        }
    }
}
