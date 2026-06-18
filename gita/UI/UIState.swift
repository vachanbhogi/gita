import Observation

@Observable
@MainActor
class UIState {
  var isAddressBarFocused: Bool = false
  var isVerticalTabs: Bool = false
  var sidebarVisible: Bool = true
  var isSidebarFocused: Bool = false
  var sidebarFocusedIndex: Int = 0
  var isHistoryVisible: Bool = false
  var showClearHistoryConfirmation: Bool = false
  var pendingClearHistoryRange: HistoryClearRange = .today
  var isBookmarksVisible: Bool = false
  var bookmarkSheetContext: BookmarkSheetContext?

  func presentBookmarkSheet(for tab: Tab) {
    bookmarkSheetContext = BookmarkSheetPresenter.context(for: tab)
  }

  func presentBookmarkEdit(for record: BookmarkRecord) {
    bookmarkSheetContext = BookmarkSheetPresenter.context(for: record)
  }

  func dismissBookmarkSheet() {
    bookmarkSheetContext = nil
  }
}
