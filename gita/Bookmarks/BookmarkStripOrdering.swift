import Foundation

enum BookmarkStripOrdering {
  static func sorted(_ records: [BookmarkRecord]) -> [BookmarkRecord] {
    // ⚡ Bolt Optimization: Reuse the optimized single-pass grouping logic from
    // BookmarksGrouper to avoid redundant filtering and allocations.
    let sections = BookmarksGrouper.sections(from: records)
    return sections.pinned + sections.library
  }
}
