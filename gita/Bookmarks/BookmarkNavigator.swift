import Foundation

@MainActor
enum BookmarkNavigator {
  static func open(
    record: BookmarkRecord,
    newTab: Bool,
    engine: BrowserEngine,
    uiState: UIState
  ) {
    BookmarkStore.shared.recordOpened(record)
    if newTab {
      engine.addNewTab(urlString: record.canonicalURL, uiState: uiState)
    } else if let tab = engine.activeTab {
      tab.navigate(to: record.canonicalURL)
    } else {
      engine.addNewTab(urlString: record.canonicalURL, uiState: uiState)
    }
  }
}
