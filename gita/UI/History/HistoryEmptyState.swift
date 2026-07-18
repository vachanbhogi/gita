import SwiftUI

struct HistoryEmptyState: View {
  @Binding var searchText: String

  var body: some View {
    ContentUnavailableView {
      Label(!searchText.isEmpty ? "No Results" : "No History", systemImage: "clock")
    } description: {
      Text(
        !searchText.isEmpty
          ? "Try a different search term."
          : "Pages you visit will appear here. Entries auto-delete after 30 days."
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
