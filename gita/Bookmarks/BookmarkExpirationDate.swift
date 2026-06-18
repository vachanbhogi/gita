import Foundation

enum BookmarkExpirationDate {
  static func expiresAt(for expiration: BookmarkExpiration, from start: Date = Date()) -> Date? {
    let calendar = Calendar.current
    switch expiration {
    case .permanent:
      return nil
    case .oneDay:
      return calendar.date(byAdding: .day, value: 1, to: start)
    case .sevenDays:
      return calendar.date(byAdding: .day, value: 7, to: start)
    case .thirtyDays:
      return calendar.date(byAdding: .day, value: 30, to: start)
    }
  }
}
