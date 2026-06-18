import Foundation
import SwiftData
import WebKit

enum HistoryClearRange: String, CaseIterable, Identifiable {
  case lastHour = "Last Hour"
  case today = "Today"
  case all = "All History"

  var id: String { rawValue }
}

@MainActor
final class HistoryStore {
  static let shared = HistoryStore()

  private static let enabledKey = "gita.historyEnabled"
  private static let retentionDays = 30

  let container: ModelContainer

  private let debounceInterval: TimeInterval = 30
  private var lastRecordedCanonicalURL: String?
  private var lastRecordedAt: Date?

  var isEnabled: Bool {
    get {
      if UserDefaults.standard.object(forKey: Self.enabledKey) == nil { return true }
      return UserDefaults.standard.bool(forKey: Self.enabledKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
    }
  }

  private init() {
    let schema = Schema([VisitRecord.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      container = try ModelContainer(for: schema, configurations: [config])
    } catch {
      fatalError("Failed to create history store: \(error)")
    }
    pruneExpiredRecords()
  }

  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
    if !enabled {
      lastRecordedCanonicalURL = nil
      lastRecordedAt = nil
    }
  }

  func recordVisit(url: URL, title: String, navigationType: WKNavigationType) {
    guard isEnabled else { return }
    guard navigationType != .backForward else { return }
    guard let canonical = URLCanonicalizer.canonicalString(for: url) else { return }

    let scheme = url.scheme?.lowercased() ?? ""
    if scheme == "gita" || scheme == "javascript" || scheme == "file" { return }

    let now = Date()
    if lastRecordedCanonicalURL == canonical,
      let lastRecordedAt,
      now.timeIntervalSince(lastRecordedAt) < debounceInterval
    {
      return
    }

    lastRecordedCanonicalURL = canonical
    lastRecordedAt = now

    let context = container.mainContext
    let domain = URLCanonicalizer.domain(for: url)
    let pageTitle = title.isEmpty ? domain : title

    let descriptor = FetchDescriptor<VisitRecord>(
      predicate: #Predicate { $0.canonicalURL == canonical }
    )

    do {
      if let existing = try context.fetch(descriptor).first {
        existing.title = pageTitle
        existing.lastVisitedAt = now
        existing.visitCount += 1
      } else {
        let record = VisitRecord(
          canonicalURL: canonical,
          title: pageTitle,
          domain: domain,
          firstVisitedAt: now,
          lastVisitedAt: now
        )
        context.insert(record)
      }
      try context.save()
    } catch {
      print("HistoryStore recordVisit failed: \(error)")
    }
  }

  func deleteRecord(_ record: VisitRecord) {
    let context = container.mainContext
    context.delete(record)
    try? context.save()
  }

  func forgetDomain(_ domain: String) {
    let context = container.mainContext
    let normalized = domain.lowercased()
    let descriptor = FetchDescriptor<VisitRecord>(
      predicate: #Predicate { $0.domain == normalized }
    )
    do {
      let records = try context.fetch(descriptor)
      for record in records {
        context.delete(record)
      }
      try? context.save()
    } catch {
      print("HistoryStore forgetDomain failed: \(error)")
    }
  }

  func clear(range: HistoryClearRange) {
    let context = container.mainContext
    let cutoff = cutoffDate(for: range)
    let descriptor: FetchDescriptor<VisitRecord>

    if let cutoff {
      descriptor = FetchDescriptor<VisitRecord>(
        predicate: #Predicate { $0.lastVisitedAt >= cutoff }
      )
    } else {
      descriptor = FetchDescriptor<VisitRecord>()
    }

    do {
      let records = try context.fetch(descriptor)
      for record in records {
        context.delete(record)
      }
      try context.save()
      lastRecordedCanonicalURL = nil
      lastRecordedAt = nil
    } catch {
      print("HistoryStore clear failed: \(error)")
    }
  }

  func pruneExpiredRecords() {
    let context = container.mainContext
    guard
      let cutoff = Calendar.current.date(
        byAdding: .day, value: -Self.retentionDays, to: Date())
    else { return }

    let descriptor = FetchDescriptor<VisitRecord>(
      predicate: #Predicate { $0.lastVisitedAt < cutoff }
    )

    do {
      let expired = try context.fetch(descriptor)
      guard !expired.isEmpty else { return }
      for record in expired {
        context.delete(record)
      }
      try context.save()
    } catch {
      print("HistoryStore prune failed: \(error)")
    }
  }

  private func cutoffDate(for range: HistoryClearRange) -> Date? {
    let calendar = Calendar.current
    let now = Date()
    switch range {
    case .lastHour:
      return calendar.date(byAdding: .hour, value: -1, to: now)
    case .today:
      return calendar.startOfDay(for: now)
    case .all:
      return nil
    }
  }
}
