import SwiftUI

struct BookmarkHoverCard: View {
  let record: BookmarkRecord

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(record.title)
        .font(.system(size: 12, weight: .semibold))
        .lineLimit(2)

      if !record.note.isEmpty {
        Text(record.note)
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
          .lineLimit(4)
      }

      Text(record.domain)
        .font(.system(size: 10))
        .foregroundStyle(.tertiary)
        .lineLimit(1)
    }
    .frame(maxWidth: 220, alignment: .leading)
  }
}
