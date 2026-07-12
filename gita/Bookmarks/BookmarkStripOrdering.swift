import Foundation

enum BookmarkStripOrdering {
  static func sorted(_ records: [BookmarkRecord]) -> [BookmarkRecord] {
    let sections = BookmarksGrouper.sections(from: records)
    return sections.pinned + sections.library
  }
}
