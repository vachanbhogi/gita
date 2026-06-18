import SwiftData
import SwiftUI

@MainActor
struct HistoryView: View {
  let engine: BrowserEngine
  let uiState: UIState
  @Binding var isPresented: Bool

  @Query(sort: \VisitRecord.lastVisitedAt, order: .reverse) private var records: [VisitRecord]
  @State private var searchText = ""
  @State private var showClearConfirmation = false
  @State private var clearRange: HistoryClearRange = .today
  @State private var historyEnabled = HistoryStore.shared.isEnabled

  private var filteredRecords: [VisitRecord] {
    guard !searchText.isEmpty else { return records }
    // ⚡ Bolt Optimization: Use localizedStandardContains instead of lowercased().contains()
    // This avoids creating new String allocations for every record during search.
    return records.filter {
      $0.title.localizedStandardContains(searchText)
        || $0.domain.localizedStandardContains(searchText)
        || $0.canonicalURL.localizedStandardContains(searchText)
    }
  }

  var body: some View {
    RecallPanelChrome {
      VStack(spacing: 0) {
        HistoryPanelHeader(
          historyEnabled: $historyEnabled,
          onClearRequest: { range in
            clearRange = range
            showClearConfirmation = true
          },
          onClose: { isPresented = false }
        )

        RecallSearchField(
          placeholder: "Search history",
          text: $searchText,
          isDisabled: !historyEnabled
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 10)

        Rectangle()
          .fill(Color.primary.opacity(0.08))
          .frame(height: 0.5)

        if !historyEnabled {
          HistoryDisabledState()
        } else if filteredRecords.isEmpty {
          HistoryEmptyState(hasSearchQuery: !searchText.isEmpty)
        } else {
          historyList
        }
      }
    }
    .confirmationDialog(
      "Clear \(clearRange.rawValue)?",
      isPresented: $showClearConfirmation,
      titleVisibility: .visible
    ) {
      Button("Clear \(clearRange.rawValue)", role: .destructive) {
        HistoryStore.shared.clear(range: clearRange)
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This cannot be undone.")
    }
    .onAppear {
      historyEnabled = HistoryStore.shared.isEnabled
    }
    .onChange(of: historyEnabled) { _, enabled in
      HistoryStore.shared.setEnabled(enabled)
    }
  }

  private var historyList: some View {
    List {
      ForEach(HistoryGrouper.grouped(records: filteredRecords), id: \.0) {
        section, sectionRecords in
        Section {
          ForEach(sectionRecords) { record in
            HistoryRow(
              record: record,
              onOpen: { open(record, newTab: false) },
              onDelete: { HistoryStore.shared.deleteRecord(record) }
            )
            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 10))
            .listRowSeparator(.visible)
            .listRowBackground(Color.clear)
            .contextMenu {
              Button("Open") { open(record, newTab: false) }
              Button("Open in New Tab") { open(record, newTab: true) }
              Divider()
              Button("Forget “\(record.domain)”", role: .destructive) {
                HistoryStore.shared.forgetDomain(record.domain)
              }
              Button("Delete", role: .destructive) {
                HistoryStore.shared.deleteRecord(record)
              }
            }
          }
        } header: {
          Text(section.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  private func open(_ record: VisitRecord, newTab: Bool) {
    if newTab {
      engine.addNewTab(urlString: record.canonicalURL, uiState: uiState)
    } else if let tab = engine.activeTab {
      tab.navigate(to: record.canonicalURL)
    } else {
      engine.addNewTab(urlString: record.canonicalURL, uiState: uiState)
    }
    isPresented = false
  }
}
