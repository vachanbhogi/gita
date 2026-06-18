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
}
