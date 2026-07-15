import Foundation

enum BookmarkStripOrdering {
  static func sorted(_ records: [BookmarkRecord]) -> [BookmarkRecord] {
    // ⚡ Bolt Optimization: Use a single iterative loop with dedicated arrays
    // to avoid multiple O(N) filter passes over the same dataset.
    var pinnedRecords: [BookmarkRecord] = []
    var libraryRecords: [BookmarkRecord] = []

    pinnedRecords.reserveCapacity(records.count / 10)
    libraryRecords.reserveCapacity(records.count)

    for record in records {
      if record.isPinned {
        pinnedRecords.append(record)
      } else {
        libraryRecords.append(record)
      }
    }

    let pinned = pinnedRecords.sorted { $0.pinOrder < $1.pinOrder }

    let library = libraryRecords.sorted { lhs, rhs in
      let lhsDate = lhs.lastOpenedAt ?? lhs.createdAt
      let rhsDate = rhs.lastOpenedAt ?? rhs.createdAt
      return lhsDate > rhsDate
    }

    return pinned + library
  }
}
