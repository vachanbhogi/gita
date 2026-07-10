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
      if hasSearchQuery {
        Button("Clear Search") {
          onClearSearch?()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
