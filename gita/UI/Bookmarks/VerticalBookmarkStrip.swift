import SwiftData
import SwiftUI

@MainActor
struct VerticalBookmarkStrip: View {
  let engine: BrowserEngine
  let uiState: UIState

  @Query(sort: \BookmarkRecord.createdAt, order: .reverse) private var records: [BookmarkRecord]

  private var sortedRecords: [BookmarkRecord] {
    BookmarkStripOrdering.sorted(records)
  }

  private var density: BookmarkStripDensity {
    BookmarkStripDensity.vertical(forCount: sortedRecords.count)
  }

  private var stripHeight: CGFloat {
    let rowHeight = density.verticalRowHeight
    let total = CGFloat(sortedRecords.count) * rowHeight
    return min(total, density.maxVerticalStripHeight)
  }

  var body: some View {
    if !sortedRecords.isEmpty {
      VStack(spacing: 0) {
        Rectangle()
          .fill(Color.primary.opacity(0.08))
          .frame(height: 0.5)
          .padding(.horizontal, 8)

        BookmarkStripHeader(count: sortedRecords.count) {
          uiState.isBookmarksVisible = true
        }

        ScrollView {
          LazyVStack(spacing: 2) {
            ForEach(sortedRecords) { record in
              BookmarkStripItem(
                record: record,
                density: density,
                layout: .vertical,
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
          }
          .padding(.horizontal, 8)
          .padding(.bottom, 6)
        }
        .frame(height: stripHeight)
        .scrollIndicators(sortedRecords.count > 5 ? .automatic : .hidden)
      }
    }
  }
}
