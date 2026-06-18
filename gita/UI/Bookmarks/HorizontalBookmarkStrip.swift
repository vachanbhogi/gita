import SwiftData
import SwiftUI

@MainActor
struct HorizontalBookmarkStrip: View {
  let engine: BrowserEngine
  let uiState: UIState

  @Query(sort: \BookmarkRecord.createdAt, order: .reverse) private var records: [BookmarkRecord]

  private var sortedRecords: [BookmarkRecord] {
    BookmarkStripOrdering.sorted(records)
  }

  private var density: BookmarkStripDensity {
    BookmarkStripDensity.horizontal(forCount: sortedRecords.count)
  }

  var body: some View {
    if !sortedRecords.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 3) {
          ForEach(sortedRecords) { record in
            BookmarkStripItem(
              record: record,
              density: density,
              layout: .horizontal,
              onOpen: { newTab in
                BookmarkNavigator.open(
                  record: record,
                  newTab: newTab,
                  engine: engine,
                  uiState: uiState
                )
              },
              onEdit: { uiState.presentBookmarkEdit(for: record) },
              onDelete: { BookmarkStore.shared.delete(record) },
              onTogglePin: { try? BookmarkStore.shared.togglePin(record) }
            )
          }

          if sortedRecords.count > 20 {
            panelShortcut
          }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
      }
      .frame(height: density.stripHeight + 6)
      .background(Color.primary.opacity(0.02))
      .overlay(alignment: .top) {
        Rectangle()
          .fill(Color.primary.opacity(0.05))
          .frame(height: 0.5)
      }
    }
  }

  private var panelShortcut: some View {
    Button {
      uiState.isBookmarksVisible = true
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 22, height: 22)
        .background(
          RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Color.primary.opacity(0.05))
        )
    }
    .buttonStyle(.plain)
    .help("Open bookmarks library")
  }
}
