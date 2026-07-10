import Foundation

enum BookmarkStripOrdering {
  static func sorted(_ records: [BookmarkRecord]) -> [BookmarkRecord] {
    // ⚡ Bolt Optimization: Reuse BookmarksGrouper to avoid redundant .filter passes
    // and array allocations over the same dataset.
    let sections = BookmarksGrouper.sections(from: records)
    return sections.pinned + sections.library
  }
}
