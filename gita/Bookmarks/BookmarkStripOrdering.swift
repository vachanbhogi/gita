import Foundation

enum BookmarkStripOrdering {
  // ⚡ Bolt Optimization: Replace multiple `.filter` passes with a single loop and
  // pre-allocated arrays to avoid O(N) allocation churn on rendering paths.
  static func sorted(_ records: [BookmarkRecord]) -> [BookmarkRecord] {
    var pinned: [BookmarkRecord] = []
    var library: [BookmarkRecord] = []

    pinned.reserveCapacity(min(records.count, 8))
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
