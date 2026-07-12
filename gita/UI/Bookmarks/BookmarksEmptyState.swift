import SwiftUI

struct BookmarksEmptyState: View {
  @Binding var searchText: String

  var body: some View {
    let hasSearchQuery = !searchText.isEmpty
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
          searchText = ""
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
