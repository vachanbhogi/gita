import Foundation

struct BookmarkSheetContext: Identifiable {
  let id = UUID()
  let url: URL
  let defaultTitle: String
  let existing: BookmarkRecord?
}
