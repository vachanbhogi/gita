import Foundation

enum BookmarkExpiration: String, CaseIterable, Identifiable {
  case permanent = "Keep"
  case oneDay = "1 Day"
  case sevenDays = "7 Days"
  case thirtyDays = "30 Days"

  var id: String { rawValue }
}
