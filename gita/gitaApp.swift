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
                .keyboardShortcut("t", modifiers: .command)
                
                Button("Close Tab") {
                    BrowserEngine.shared.closeTab(id: BrowserEngine.shared.activeTabId)
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            
            // Focus location field
            CommandGroup(after: .sidebar) {
                Button("Open Location…") {
                    BrowserEngine.shared.isAddressBarFocused = true
                }
                .keyboardShortcut("l", modifiers: .command)
            }

            // Web Navigation commands
            CommandMenu("Navigation") {
                Button("Go Back") {
                    BrowserEngine.shared.activeTab?.goBack()
                }
                .keyboardShortcut("[", modifiers: .command)
                
                Button("Go Forward") {
                    BrowserEngine.shared.activeTab?.goForward()
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Button("Reload Page") {
                    BrowserEngine.shared.activeTab?.reload()
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            // Tab Switching & Sidebar Focus Menu
            CommandMenu("Tab") {
                Button("Next Tab") {
                    BrowserEngine.shared.selectNextTab()
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Next Tab (Ctrl+Tab)") {
                    BrowserEngine.shared.selectNextTab()
                }
                .keyboardShortcut(.tab, modifiers: .control)
                
                Button("Previous Tab") {
                    BrowserEngine.shared.selectPreviousTab()
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Button("Previous Tab (Ctrl+Shift+Tab)") {
                    BrowserEngine.shared.selectPreviousTab()
                }
                .keyboardShortcut(.tab, modifiers: [.control, .shift])
                
                Divider()

                Button("Focus Sidebar") {
                    BrowserEngine.shared.toggleSidebarFocus()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])

                Button("Toggle Sidebar") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        if !BrowserEngine.shared.isVerticalTabs {
                            BrowserEngine.shared.isVerticalTabs = true
                            BrowserEngine.shared.sidebarVisible = true
                        } else {
                            BrowserEngine.shared.sidebarVisible.toggle()
                        }
                    }
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                
                Divider()
                
                ForEach(1...8, id: \.self) { num in
                    Button("Switch to Tab \(num)") {
                        BrowserEngine.shared.selectTab(at: num - 1)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(num)")), modifiers: .command)
                }
                
                Button("Switch to Last Tab") {
                    BrowserEngine.shared.selectLastTab()
                }
                .keyboardShortcut("9", modifiers: .command)
            }
        }
    }
}
