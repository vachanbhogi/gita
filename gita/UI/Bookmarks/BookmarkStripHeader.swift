import SwiftUI

struct BookmarkStripHeader: View {
  let count: Int
  let onShowAll: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      Text("BOOKMARKS")
        .font(.system(size: 9.5, weight: .bold))
        .foregroundStyle(.secondary.opacity(0.8))

      Text("\(count)")
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.tertiary)

      Spacer()

      if count > 5 {
        Button("All", action: onShowAll)
          .buttonStyle(.plain)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(.secondary)
          .help("Show all bookmarks")
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 8)
    .padding(.bottom, 4)
  }
}
