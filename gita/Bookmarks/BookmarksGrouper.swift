import Foundation

enum BookmarksGrouper {
  static func sections(
    from records: [BookmarkRecord]
  ) -> (pinned: [BookmarkRecord], library: [BookmarkRecord]) {
    // ⚡ Bolt Optimization: Use a single iterative loop with pre-allocated arrays to avoid O(N) allocation churn from multiple `.filter` calls
    var pinned: [BookmarkRecord] = []
    var library: [BookmarkRecord] = []

    // Estimate capacities based on typical user behavior to avoid reallocations
    pinned.reserveCapacity(min(records.count, 20))
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
