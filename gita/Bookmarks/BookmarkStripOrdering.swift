import Foundation

enum BookmarkStripOrdering {
  static func sorted(_ records: [BookmarkRecord]) -> [BookmarkRecord] {
    // ⚡ Bolt Optimization: Use BookmarksGrouper to avoid duplicated filtering logic and O(N) allocation churn
    let sections = BookmarksGrouper.sections(from: records)
    return sections.pinned + sections.library
  }
}
