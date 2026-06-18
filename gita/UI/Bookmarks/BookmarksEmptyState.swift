import SwiftUI

struct BookmarksEmptyState: View {
  let hasSearchQuery: Bool

  var body: some View {
    ContentUnavailableView(
      hasSearchQuery ? "No Results" : "No Bookmarks",
      systemImage: "bookmark",
      description: Text(
        hasSearchQuery
          ? "Try a different search term."
          : "Press ⌘D or tap the star to save pages you want to keep."
      )
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
