import SwiftUI

struct BookmarksPanelHeader: View {
  let onClose: () -> Void

  var body: some View {
    HStack(spacing: 10) {
      Text("Bookmarks")
        .font(.system(size: 15, weight: .semibold))

      Spacer()

      Text("Saved until you delete")
        .font(.system(size: 11))
        .foregroundStyle(.tertiary)

      Button(action: onClose) {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 16))
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .help("Close")
    }
    .padding(.horizontal, 16)
    .padding(.top, 14)
    .padding(.bottom, 10)
  }
}
