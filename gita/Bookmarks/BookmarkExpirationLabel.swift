import Foundation

enum BookmarkExpirationLabel {
  static func remainingDays(until expiresAt: Date, now: Date = Date()) -> Int {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: now)
    let end = calendar.startOfDay(for: expiresAt)
    return max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 0)
  }

  static func shortLabel(for record: BookmarkRecord, now: Date = Date()) -> String? {
    guard let expiresAt = record.expiresAt else { return nil }
    guard expiresAt > now else { return nil }

    let days = remainingDays(until: expiresAt, now: now)
    if days == 0 { return "Today" }
    if days == 1 { return "1d" }
    return "\(days)d"
  }
}
