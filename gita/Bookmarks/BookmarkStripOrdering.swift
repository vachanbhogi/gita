import Foundation

enum BookmarkStripOrdering {
  static func sorted(_ records: [BookmarkRecord]) -> [BookmarkRecord] {
    // ⚡ Bolt Optimization: Use dedicated pre-allocated arrays instead of chaining .filter
    // to avoid O(N) allocation churn on the rendering path.
    var pinned: [BookmarkRecord] = []
    var library: [BookmarkRecord] = []

    pinned.reserveCapacity(min(records.count, 10))
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

    return pinned + library
  }
}
