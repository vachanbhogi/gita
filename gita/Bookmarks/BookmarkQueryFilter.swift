import Foundation

enum BookmarkQueryFilter {
  static func active(from records: [BookmarkRecord], now: Date = Date()) -> [BookmarkRecord] {
    records.filter { BookmarkRecordStatus.isActive($0, now: now) }
  }
}
