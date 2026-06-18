import Foundation
import SwiftData

enum BookmarkExpirationPruner {
  @MainActor
  static func pruneExpired(in context: ModelContext, now: Date = Date()) {
    let descriptor = FetchDescriptor<BookmarkRecord>()

    do {
      let expired = try context.fetch(descriptor).filter { record in
        guard let expiresAt = record.expiresAt else { return false }
        return expiresAt <= now
      }
      guard !expired.isEmpty else { return }
      for record in expired {
        context.delete(record)
      }
      try context.save()
    } catch {
      print("BookmarkExpirationPruner failed: \(error)")
    }
  }
}
