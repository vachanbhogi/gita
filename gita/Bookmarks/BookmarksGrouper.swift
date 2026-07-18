import Foundation

enum BookmarksGrouper {
  // ⚡ Bolt Optimization: Replace multiple `.filter` passes with a single loop and
  // pre-allocated arrays to avoid O(N) allocation churn on rendering paths.
  static func sections(
    from records: [BookmarkRecord]
  ) -> (pinned: [BookmarkRecord], library: [BookmarkRecord]) {
    var pinned: [BookmarkRecord] = []
    var library: [BookmarkRecord] = []

    // Estimate capacities to minimize reallocation overhead
    pinned.reserveCapacity(min(records.count, 8)) // Typically up to 8 pinned
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
