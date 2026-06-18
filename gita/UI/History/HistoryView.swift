import SwiftData
import SwiftUI

private enum HistorySection: String, CaseIterable {
  case today = "Today"
  case yesterday = "Yesterday"
  case thisWeek = "This Week"
  case older = "Older"
}

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
    let query = searchText.lowercased()
    return records.filter {
      $0.title.lowercased().contains(query)
        || $0.domain.lowercased().contains(query)
        || $0.canonicalURL.lowercased().contains(query)
    }
  }

  private var groupedRecords: [(HistorySection, [VisitRecord])] {
    let calendar = Calendar.current
    let now = Date()
    let startOfToday = calendar.startOfDay(for: now)
    let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
    let startOfWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday)!

    var buckets: [HistorySection: [VisitRecord]] = [:]
    for record in filteredRecords {
      let visited = record.lastVisitedAt
      let section: HistorySection
      if visited >= startOfToday {
        section = .today
      } else if visited >= startOfYesterday {
        section = .yesterday
      } else if visited >= startOfWeek {
        section = .thisWeek
      } else {
        section = .older
      }
      buckets[section, default: []].append(record)
    }

    return HistorySection.allCases.compactMap { section in
      guard let items = buckets[section], !items.isEmpty else { return nil }
      return (section, items)
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      titleBar
      searchBar
        .padding(.horizontal, 14)
        .padding(.bottom, 10)

      Rectangle()
        .fill(Color.primary.opacity(0.08))
        .frame(height: 0.5)

      if !historyEnabled {
        disabledState
      } else if filteredRecords.isEmpty {
        emptyState
      } else {
        historyList
      }
    }
    .frame(width: 420, height: 520)
    .background {
      VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
    }
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
    }
    .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
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
  }

  private var titleBar: some View {
    VStack(spacing: 8) {
      HStack(spacing: 10) {
        Text("History")
          .font(.system(size: 15, weight: .semibold))

        Spacer()

        Menu {
          ForEach(HistoryClearRange.allCases) { range in
            Button("Clear \(range.rawValue)…") {
              clearRange = range
              showClearConfirmation = true
            }
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .help("Clear history")

        Button {
          isPresented = false
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Close")
      }

      HStack(spacing: 8) {
        Toggle("Save history", isOn: $historyEnabled)
          .toggleStyle(.switch)
          .controlSize(.small)
          .font(.system(size: 12))
          .onChange(of: historyEnabled) { _, enabled in
            HistoryStore.shared.setEnabled(enabled)
          }

        Spacer()

        Text("Auto-deletes after 30 days")
          .font(.system(size: 11))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 14)
    .padding(.bottom, 10)
  }

  private var searchBar: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 12))
        .foregroundStyle(.tertiary)

      TextField("Search history", text: $searchText)
        .textFieldStyle(.plain)
        .font(.system(size: 13))
        .disabled(!historyEnabled)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .background {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.primary.opacity(0.06))
        .overlay {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        }
    }
  }

  private var historyList: some View {
    List {
      ForEach(groupedRecords, id: \.0) { section, sectionRecords in
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

  private var emptyState: some View {
    ContentUnavailableView(
      searchText.isEmpty ? "No History" : "No Results",
      systemImage: "clock",
      description: Text(
        searchText.isEmpty
          ? "Pages you visit will appear here. Entries auto-delete after 30 days."
          : "Try a different search term."
      )
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var disabledState: some View {
    ContentUnavailableView(
      "History Paused",
      systemImage: "clock.badge.xmark",
      description: Text(
        "Browsing history is off. Turn on “Save Browsing History” in the menu above to start recording again."
      )
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

private struct HistoryRow: View {
  let record: VisitRecord
  let onOpen: () -> Void
  let onDelete: () -> Void

  @State private var hovered = false

  private var faviconURL: URL? {
    guard !record.domain.isEmpty else { return nil }
    return URL(string: "https://www.google.com/s2/favicons?sz=32&domain=\(record.domain)")
  }

  var body: some View {
    HStack(spacing: 10) {
      Button(action: onOpen) {
        HStack(spacing: 10) {
          FaviconView(url: faviconURL, size: 16, iconSize: 10)

          VStack(alignment: .leading, spacing: 2) {
            Text(record.title)
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(.primary)
              .lineLimit(1)

            Text(record.domain)
              .font(.system(size: 11))
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }

          Spacer(minLength: 8)

          VStack(alignment: .trailing, spacing: 2) {
            Text(record.lastVisitedAt, style: .time)
              .font(.system(size: 11))
              .foregroundStyle(.tertiary)

            if record.visitCount > 1 {
              Text("\(record.visitCount) visits")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)
            }
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
