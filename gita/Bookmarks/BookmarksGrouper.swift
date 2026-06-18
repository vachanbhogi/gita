import Foundation

enum BookmarksGrouper {
  static func sections(
    from records: [BookmarkRecord]
  ) -> (pinned: [BookmarkRecord], library: [BookmarkRecord]) {
    let pinned =
      records
      .filter(\.isPinned)
      .sorted { $0.pinOrder < $1.pinOrder }

    let library =
      records
      .filter { !$0.isPinned }
      .sorted { lhs, rhs in
        let lhsDate = lhs.lastOpenedAt ?? lhs.createdAt
        let rhsDate = rhs.lastOpenedAt ?? rhs.createdAt
        return lhsDate > rhsDate
      }

    return (pinned, library)
  }
}
