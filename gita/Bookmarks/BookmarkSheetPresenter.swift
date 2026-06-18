import Foundation

@MainActor
enum BookmarkSheetPresenter {
  static func context(for tab: Tab) -> BookmarkSheetContext? {
    guard let url = URL(string: tab.url) else { return nil }
    let existing = BookmarkStore.shared.bookmark(for: url)
    return BookmarkSheetContext(
      url: url,
      defaultTitle: tab.title,
      existing: existing
    )
  }

  static func context(for record: BookmarkRecord) -> BookmarkSheetContext? {
    guard let url = URL(string: record.canonicalURL) else { return nil }
    return BookmarkSheetContext(
      url: url,
      defaultTitle: record.title,
      existing: record
    )
  }
}
