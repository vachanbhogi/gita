import Foundation

enum BookmarksGrouper {
  static func sections(
    from records: [BookmarkRecord]
  ) -> (pinned: [BookmarkRecord], library: [BookmarkRecord]) {
    // ⚡ Bolt Optimization: Use a single iterative loop and pre-allocated local arrays
    // instead of chaining multiple .filter calls to avoid O(N) allocation churn.
    var pinned: [BookmarkRecord] = []
    var library: [BookmarkRecord] = []

    let capacity = records.count
    pinned.reserveCapacity(capacity / 4)
    library.reserveCapacity(capacity)

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
