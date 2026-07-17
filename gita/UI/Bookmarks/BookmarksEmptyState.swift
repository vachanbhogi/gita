import SwiftUI

struct BookmarksEmptyState: View {
  @Binding var searchText: String

  var body: some View {
    ContentUnavailableView {
      Label(!searchText.isEmpty ? "No Results" : "No Bookmarks", systemImage: "bookmark")
    } description: {
      Text(
        !searchText.isEmpty
          ? "Try a different search term."
          : "Press ⌘D or tap the star to save pages you want to keep."
      )
    } actions: {
      if !searchText.isEmpty {
        Button("Clear Search") {
          searchText = ""
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
