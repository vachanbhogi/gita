import SwiftUI

struct AppCommands: Commands {
  let engine: BrowserEngine
  let uiState: UIState

  var body: some Commands {
    CommandGroup(replacing: .newItem) {
      Button("New Tab") { engine.addNewTab(uiState: uiState) }
        .keyboardShortcut("t", modifiers: .command)

      Button("Close Tab") { engine.closeTab(id: engine.activeTabId, uiState: uiState) }
        .keyboardShortcut("w", modifiers: .command)
    }

    CommandGroup(after: .sidebar) {
      Button("Open Location…") { uiState.isAddressBarFocused = true }
        .keyboardShortcut("l", modifiers: .command)
    }

    CommandMenu("Navigation") {
      Button("Go Back") { engine.activeTab?.goBack() }
        .keyboardShortcut("[", modifiers: .command)

      Button("Go Forward") { engine.activeTab?.goForward() }
        .keyboardShortcut("]", modifiers: .command)

      Button("Reload Page") { engine.activeTab?.reload() }
        .keyboardShortcut("r", modifiers: .command)

      Divider()

      Button("Show History") { uiState.isHistoryVisible = true }
        .keyboardShortcut("y", modifiers: .command)
    }

    CommandMenu("History") {
      ForEach(HistoryClearRange.allCases) { range in
        Button("Clear \(range.rawValue)…") {
          uiState.pendingClearHistoryRange = range
          uiState.showClearHistoryConfirmation = true
        }
      }
    }

    CommandMenu("Tab") {
      tabSwitchingGroup
      sidebarGroup
      numberedTabsGroup
    }
  }

  @ViewBuilder
  private var tabSwitchingGroup: some View {
    Button("Next Tab") { engine.selectNextTab() }
      .keyboardShortcut("]", modifiers: [.command, .shift])

    Button("Next Tab (Ctrl+Tab)") { engine.selectNextTab() }
      .keyboardShortcut(.tab, modifiers: .control)

    Button("Previous Tab") { engine.selectPreviousTab() }
      .keyboardShortcut("[", modifiers: [.command, .shift])

    Button("Previous Tab (Ctrl+Shift+Tab)") { engine.selectPreviousTab() }
      .keyboardShortcut(.tab, modifiers: [.control, .shift])

    Divider()
  }

  @ViewBuilder
  private var sidebarGroup: some View {
    Button("Focus Sidebar") { engine.toggleSidebarFocus(uiState: uiState) }
      .keyboardShortcut("s", modifiers: [.command, .option])

    Button("Toggle Sidebar") {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
        if !uiState.isVerticalTabs {
          uiState.isVerticalTabs = true
          uiState.sidebarVisible = true
        } else {
          uiState.sidebarVisible.toggle()
        }
      }
    }
    .keyboardShortcut("l", modifiers: [.command, .shift])

    Divider()
  }

  @ViewBuilder
  private var numberedTabsGroup: some View {
    ForEach(1...8, id: \.self) { num in
      Button("Switch to Tab \(num)") {
        engine.selectTab(at: num - 1)
      }
      .keyboardShortcut(KeyEquivalent(Character("\(num)")), modifiers: .command)
    }

    Button("Switch to Last Tab") {
      engine.selectLastTab()
    }
    .keyboardShortcut("9", modifiers: .command)
  }
}
