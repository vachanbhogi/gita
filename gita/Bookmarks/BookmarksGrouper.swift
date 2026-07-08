import Foundation

enum BookmarksGrouper {
  static func sections(
    from records: [BookmarkRecord]
  ) -> (pinned: [BookmarkRecord], library: [BookmarkRecord]) {
    // ⚡ Bolt Optimization: Use dedicated pre-allocated local arrays and a single pass
    // to group items into known categories, avoiding O(N) allocation churn on critical
    // rendering paths from calling `filter` multiple times.
    var pinned: [BookmarkRecord] = []
    var library: [BookmarkRecord] = []

    pinned.reserveCapacity(min(records.count, BookmarkPinPolicy.maxPinnedCount))
    library.reserveCapacity(records.count)

    for record in records {
      if record.isPinned {
        pinned.append(record)
      } else {
        library.append(record)
      }
    }

    pinned.sort { $0.pinOrder < $1.pinOrder }
    library.sort { lhs, rhs in
      let lhsDate = lhs.lastOpenedAt ?? lhs.createdAt
      let rhsDate = rhs.lastOpenedAt ?? rhs.createdAt
      return lhsDate > rhsDate
    }

    return (pinned, library)
  }
}
