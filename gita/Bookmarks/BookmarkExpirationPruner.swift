import Foundation
import SwiftData

enum BookmarkExpirationPruner {
  @MainActor
  static func pruneExpired(in context: ModelContext, now: Date = Date()) {
    do {
      // ⚡ Bolt: Use SQLite batch deletion to avoid N+1 iteration and fetching non-expired records into memory.
      if #available(macOS 15.0, iOS 18.0, *) {
        try context.delete(
          model: BookmarkRecord.self,
          where: #Predicate { record in
            if let expiresAt = record.expiresAt {
              return expiresAt <= now
            } else {
              return false
            }
          }
        )
      } else {
        let descriptor = FetchDescriptor<BookmarkRecord>(
          predicate: #Predicate { record in
            if let expiresAt = record.expiresAt {
              return expiresAt <= now
            } else {
              return false
            }
          }
        )
        let expired = try context.fetch(descriptor)
        guard !expired.isEmpty else { return }
        for record in expired {
          context.delete(record)
        }
      }
      try context.save()
    } catch {
      print("BookmarkExpirationPruner failed: \(error)")
    }
  }
}
