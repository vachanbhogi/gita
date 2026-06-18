import SwiftUI

struct BookmarkRow: View {
  let record: BookmarkRecord
  let onOpen: () -> Void
  let onDelete: () -> Void

  @State private var hovered = false

  var body: some View {
    HStack(spacing: 10) {
      Button(action: onOpen) {
        HStack(spacing: 10) {
          FaviconView(
            url: FaviconURLBuilder.url(forDomain: record.domain),
            size: 16,
            iconSize: 10
          )

          VStack(alignment: .leading, spacing: 2) {
            Text(record.title)
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(.primary)
              .lineLimit(1)

            if record.note.isEmpty {
              Text(record.domain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            } else {
              Text(record.note)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }

          Spacer(minLength: 8)

          if record.isPinned {
            Image(systemName: "pin.fill")
              .font(.system(size: 9))
              .foregroundStyle(.tertiary)
          }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      if hovered {
        Button(action: onDelete) {
          Image(systemName: "xmark")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.primary.opacity(0.65))
            .frame(width: 18, height: 18)
            .background(Circle().fill(Color.primary.opacity(0.1)))
        }
        .buttonStyle(PressableButtonStyle())
        .help("Delete")
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
      }
    }
    .padding(.vertical, 4)
    .onHover { hovered = $0 }
  }
}
