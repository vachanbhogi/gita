import SwiftUI

struct HistoryEmptyState: View {
  let hasSearchQuery: Bool

  var body: some View {
    ContentUnavailableView(
      hasSearchQuery ? "No Results" : "No History",
      systemImage: "clock",
      description: Text(
        hasSearchQuery
          ? "Try a different search term."
          : "Pages you visit will appear here. Entries auto-delete after 30 days."
      )
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
