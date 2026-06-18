import Foundation
import SwiftData

@Model
final class VisitRecord {
  @Attribute(.unique) var canonicalURL: String
  var title: String
  var domain: String
  var firstVisitedAt: Date
  var lastVisitedAt: Date
  var visitCount: Int

  init(
    canonicalURL: String,
    title: String,
    domain: String,
    firstVisitedAt: Date = Date(),
    lastVisitedAt: Date = Date(),
    visitCount: Int = 1
  ) {
    self.canonicalURL = canonicalURL
    self.title = title
    self.domain = domain
    self.firstVisitedAt = firstVisitedAt
    self.lastVisitedAt = lastVisitedAt
    self.visitCount = visitCount
  }
}
