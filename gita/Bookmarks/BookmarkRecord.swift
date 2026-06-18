import Foundation
import SwiftData

@Model
final class BookmarkRecord {
  @Attribute(.unique) var canonicalURL: String
  var title: String
  var domain: String
  var note: String
  var isPinned: Bool
  var pinOrder: Int
  var createdAt: Date
  var lastOpenedAt: Date?
  var expiresAt: Date?

  init(
    canonicalURL: String,
    title: String,
    domain: String,
    note: String = "",
    isPinned: Bool = false,
    pinOrder: Int = -1,
    createdAt: Date = Date(),
    lastOpenedAt: Date? = nil,
    expiresAt: Date? = nil
  ) {
    self.canonicalURL = canonicalURL
    self.title = title
    self.domain = domain
    self.note = note
    self.isPinned = isPinned
    self.pinOrder = pinOrder
    self.createdAt = createdAt
    self.lastOpenedAt = lastOpenedAt
    self.expiresAt = expiresAt
  }
}
