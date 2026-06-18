import SwiftUI

struct BookmarkExpirationBadge: View {
  let record: BookmarkRecord

  var body: some View {
    if let label = BookmarkExpirationLabel.shortLabel(for: record) {
      Text(label)
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
          Capsule()
            .fill(Color.primary.opacity(0.07))
        )
        .help("Expires in \(label)")
    }
  }
}
