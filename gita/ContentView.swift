import SwiftUI

struct ContentView: View {
  let engine: BrowserEngine
  let uiState: UIState

  var body: some View {
    ZStack(alignment: .top) {
      TransparentWindow()

      Color.clear
        .background(.ultraThinMaterial)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        ChromeBar(engine: engine, uiState: uiState)

        HStack(spacing: 0) {
          if uiState.isVerticalTabs && uiState.sidebarVisible {
            SidebarView(engine: engine, uiState: uiState)
              .transition(.move(edge: .leading))
          }

          // Web content — fills everything below
          webContent
        }
      }
    }
    .frame(minWidth: 1100, minHeight: 720)
    // CRITICAL: Tells macOS to draw your SwiftUI views over the title bar area
    .ignoresSafeArea(.container, edges: .top)
    .sheet(isPresented: Bindable(uiState).isHistoryVisible) {
      HistoryView(
        engine: engine,
        uiState: uiState,
        isPresented: Bindable(uiState).isHistoryVisible
      )
      .presentationBackground(.clear)
    }
    .sheet(isPresented: Bindable(uiState).isBookmarksVisible) {
      BookmarksView(
        engine: engine,
        uiState: uiState,
        isPresented: Bindable(uiState).isBookmarksVisible,
        onEdit: { record in uiState.presentBookmarkEdit(for: record) }
      )
      .presentationBackground(.clear)
    }
    .sheet(item: Bindable(uiState).bookmarkSheetContext) { context in
      SaveBookmarkSheet(context: context) {
        uiState.dismissBookmarkSheet()
      }
      .presentationBackground(.clear)
    }
    .confirmationDialog(
      "Clear \(uiState.pendingClearHistoryRange.rawValue)?",
      isPresented: Bindable(uiState).showClearHistoryConfirmation,
      titleVisibility: .visible
    ) {
      Button("Clear \(uiState.pendingClearHistoryRange.rawValue)", role: .destructive) {
        HistoryStore.shared.clear(range: uiState.pendingClearHistoryRange)
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This cannot be undone.")
    }
  }

  @ViewBuilder
  private var webContent: some View {
    if let activeTab = engine.activeTab {
      if let webView = activeTab.webView {
        BrowserView(webView: webView)
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
