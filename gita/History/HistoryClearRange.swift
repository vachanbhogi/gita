import Foundation

enum HistoryClearRange: String, CaseIterable, Identifiable {
  case lastHour = "Last Hour"
  case today = "Today"
  case all = "All History"

  var id: String { rawValue }
}
