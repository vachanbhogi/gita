import SwiftData
import SwiftUI

@MainActor
struct BookmarksView: View {
  let engine: BrowserEngine
  let uiState: UIState
  @Binding var isPresented: Bool
  var onEdit: (BookmarkRecord) -> Void

  @Query(sort: \BookmarkRecord.createdAt, order: .reverse) private var records: [BookmarkRecord]
  @State private var searchText = ""

  private var activeRecords: [BookmarkRecord] {
    BookmarkQueryFilter.active(from: records)
  }

  private var filteredRecords: [BookmarkRecord] {
    let base = activeRecords
    guard !searchText.isEmpty else { return base }
    // ⚡ Bolt Optimization: Use localizedStandardContains instead of lowercased().contains()
    // This avoids creating new String allocations for every record during search.
    return base.filter {
      $0.title.localizedStandardContains(searchText)
        || $0.domain.localizedStandardContains(searchText)
        || $0.note.localizedStandardContains(searchText)
        || $0.canonicalURL.localizedStandardContains(searchText)
    }
  }

  private var sections: (pinned: [BookmarkRecord], library: [BookmarkRecord]) {
    BookmarksGrouper.sections(from: filteredRecords)
  }

  var body: some View {
    RecallPanelChrome {
      VStack(spacing: 0) {
        BookmarksPanelHeader(onClose: { isPresented = false })

        RecallSearchField(placeholder: "Search bookmarks", text: $searchText)
          .padding(.horizontal, 14)
          .padding(.bottom, 10)

        Rectangle()
          .fill(Color.primary.opacity(0.08))
          .frame(height: 0.5)

        if filteredRecords.isEmpty {
          BookmarksEmptyState(
            hasSearchQuery: !searchText.isEmpty,
            clearSearch: { searchText = "" }
          )
        } else {
          bookmarksList
        }
      }
    }
  }

  private var bookmarksList: some View {
    List {
      if !sections.pinned.isEmpty {
        Section {
          ForEach(sections.pinned) { record in
            bookmarkRow(record)
          }
        } header: {
          sectionHeader("Pinned")
        }
      }

      if !sections.library.isEmpty {
        Section {
          ForEach(sections.library) { record in
            bookmarkRow(record)
          }
        } header: {
          sectionHeader(sections.pinned.isEmpty ? "Bookmarks" : "All Bookmarks")
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(.secondary)
      .textCase(.uppercase)
  }

  private func bookmarkRow(_ record: BookmarkRecord) -> some View {
    BookmarkRow(
      record: record,
      onOpen: {
        BookmarkNavigator.open(record: record, newTab: false, engine: engine, uiState: uiState)
        isPresented = false
      },
      onDelete: { BookmarkStore.shared.delete(record) }
    )
    .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 10))
    .listRowSeparator(.visible)
    .listRowBackground(Color.clear)
    .contextMenu {
      Button("Open") {
        BookmarkNavigator.open(record: record, newTab: false, engine: engine, uiState: uiState)
        isPresented = false
      }
      Button("Open in New Tab") {
        BookmarkNavigator.open(record: record, newTab: true, engine: engine, uiState: uiState)
        isPresented = false
      }
      Button("Edit…") {
        isPresented = false
        onEdit(record)
      }
      Divider()
      Button(record.isPinned ? "Unpin" : "Pin to Bar") {
        try? BookmarkStore.shared.togglePin(record)
      }
      Button("Delete", role: .destructive) {
        BookmarkStore.shared.delete(record)
      }
    }
  }
}
