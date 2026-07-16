import SwiftUI

struct HistoryEmptyState: View {
  let hasSearchQuery: Bool
  var onClearSearch: (() -> Void)? = nil

  var body: some View {
    ContentUnavailableView {
      Label(hasSearchQuery ? "No Results" : "No History", systemImage: "clock")
    } description: {
      Text(
        hasSearchQuery
          ? "Try a different search term."
          : "Pages you visit will appear here. Entries auto-delete after 30 days."
      )
    } actions: {
      if hasSearchQuery, let onClearSearch = onClearSearch {
        Button("Clear Search", action: onClearSearch)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
