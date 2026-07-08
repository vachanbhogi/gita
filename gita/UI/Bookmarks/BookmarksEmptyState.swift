import SwiftUI

struct BookmarksEmptyState: View {
  let hasSearchQuery: Bool
  var onClearSearch: (() -> Void)? = nil

  var body: some View {
    ContentUnavailableView {
      Label(hasSearchQuery ? "No Results" : "No Bookmarks", systemImage: "bookmark")
    } description: {
      Text(
        hasSearchQuery
          ? "Try a different search term."
          : "Press ⌘D or tap the star to save pages you want to keep."
      )
    } actions: {
      if hasSearchQuery {
        Button("Clear Search") {
          onClearSearch?()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
