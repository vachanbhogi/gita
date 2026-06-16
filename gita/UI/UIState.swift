import Observation

@Observable
@MainActor
class UIState {
  var isAddressBarFocused: Bool = false
  var isVerticalTabs: Bool = false
  var sidebarVisible: Bool = true
  var isSidebarFocused: Bool = false
  var sidebarFocusedIndex: Int = 0
}
