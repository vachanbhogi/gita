import SwiftUI

struct BookmarkStarButton: View {
  let tab: Tab
  let uiState: UIState

  @State private var isBookmarked = false

  var body: some View {
    Button(action: handleTap) {
      Image(systemName: isBookmarked ? "star.fill" : "star")
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(isBookmarked ? Color.yellow.opacity(0.9) : Color.primary.opacity(0.35))
        .frame(width: 18, height: 18)
    }
    .buttonStyle(.plain)
    .help(isBookmarked ? "Edit Bookmark" : "Add Bookmark (⌘D)")
    .onAppear { refreshState() }
    .onChange(of: tab.url) { _, _ in refreshState() }
    .onChange(of: uiState.bookmarkSheetContext?.id) { _, _ in refreshState() }
  }

  private func refreshState() {
    guard let url = URL(string: tab.url) else {
      isBookmarked = false
      return
    }
    isBookmarked = BookmarkStore.shared.isBookmarked(url: url)
  }

  private func handleTap() {
    uiState.presentBookmarkSheet(for: tab)
  }
}
