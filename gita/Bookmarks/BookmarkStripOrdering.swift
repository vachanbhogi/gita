import Foundation

enum BookmarkStripOrdering {
  static func sorted(_ records: [BookmarkRecord]) -> [BookmarkRecord] {
    // ⚡ Bolt Optimization: Reuse the logic in BookmarksGrouper to avoid redundant O(N) loops.
    let sections = BookmarksGrouper.sections(from: records)
    return sections.pinned + sections.library
  }
}
