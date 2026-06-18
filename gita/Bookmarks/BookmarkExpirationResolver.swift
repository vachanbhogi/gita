import Foundation

enum BookmarkExpirationResolver {
  static func expiration(for record: BookmarkRecord) -> BookmarkExpiration {
    guard let expiresAt = record.expiresAt else { return .permanent }

    let remainingDays = BookmarkExpirationLabel.remainingDays(until: expiresAt)
    if remainingDays <= 1 { return .oneDay }
    if remainingDays <= 7 { return .sevenDays }
    return .thirtyDays
  }
}
