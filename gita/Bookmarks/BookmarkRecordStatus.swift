import Foundation

enum BookmarkRecordStatus {
  static func isActive(_ record: BookmarkRecord, now: Date = Date()) -> Bool {
    guard let expiresAt = record.expiresAt else { return true }
    return expiresAt > now
  }
}
