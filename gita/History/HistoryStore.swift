import Foundation
import SwiftData
import WebKit

@MainActor
final class HistoryStore {
  static let shared = HistoryStore()

  private static let enabledKey = "gita.historyEnabled"
  private static let retentionDays = 30

  private let debounceInterval: TimeInterval = 30
  private var lastRecordedCanonicalURL: String?
  private var lastRecordedAt: Date?

  private var context: ModelContext {
    BrowserDataStore.shared.container.mainContext
  }

  private var cachedIsEnabled: Bool?
  private let lock = NSLock()

  // ⚡ Bolt: Cache `isEnabled` to avoid repeated UserDefaults access on WKNavigationDelegate critical paths.
  // We use NSLock for thread safety.
  var isEnabled: Bool {
    get {
      lock.lock()
      defer { lock.unlock() }

      if let cached = cachedIsEnabled {
        return cached
      }

      let value: Bool
      if UserDefaults.standard.object(forKey: Self.enabledKey) == nil {
        value = true
      } else {
        value = UserDefaults.standard.bool(forKey: Self.enabledKey)
      }

      cachedIsEnabled = value
      return value
    }
    set {
      lock.lock()
      cachedIsEnabled = newValue
      UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
      lock.unlock()
    }
  }

  private init() {
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

    // ⚡ Bolt: Parse URL once via canonicalize to avoid redundant URLComponents parsing and allocations
    guard let canonicalizedURL = URLCanonicalizer.canonicalize(url) else { return }
    let canonical = canonicalizedURL.absoluteString

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

    let domain = canonicalizedURL.host?.lowercased() ?? url.host?.lowercased() ?? ""
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
    context.delete(record)
    try? context.save()
  }

  func forgetDomain(_ domain: String) {
    let normalized = domain.lowercased()
    do {
      if #available(macOS 15.0, iOS 18.0, *) {
        try context.delete(
          model: VisitRecord.self,
          where: #Predicate { $0.domain == normalized }
        )
      } else {
        let descriptor = FetchDescriptor<VisitRecord>(
          predicate: #Predicate { $0.domain == normalized }
        )
        let records = try context.fetch(descriptor)
        for record in records {
          context.delete(record)
        }
      }
      try context.save()

      // 🛡️ Sentinel: Remove persistent tracking data to prevent privacy leaks after history deletion
      Task { @MainActor in
        WKWebsiteDataStore.default().fetchDataRecords(
          ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()
        ) { records in
          let recordsToDelete = records.filter { record in
            let recordDomain = record.displayName.lowercased()
            return recordDomain == normalized || recordDomain.hasSuffix(".\(normalized)")
          }
          WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: recordsToDelete
          ) {}
        }
      }
    } catch {
      print("HistoryStore forgetDomain failed: \(error)")
    }
  }

  func clear(range: HistoryClearRange) {
    let cutoff = cutoffDate(for: range)

    do {
      if #available(macOS 15.0, iOS 18.0, *) {
        if let cutoff {
          try context.delete(
            model: VisitRecord.self,
            where: #Predicate { $0.lastVisitedAt >= cutoff }
          )
        } else {
          try context.delete(model: VisitRecord.self)
        }
      } else {
        let descriptor: FetchDescriptor<VisitRecord>
        if let cutoff {
          descriptor = FetchDescriptor<VisitRecord>(
            predicate: #Predicate { $0.lastVisitedAt >= cutoff }
          )
        } else {
          descriptor = FetchDescriptor<VisitRecord>()
        }
        let records = try context.fetch(descriptor)
        for record in records {
          context.delete(record)
        }
      }
      try context.save()
      lastRecordedCanonicalURL = nil
      lastRecordedAt = nil

      // 🛡️ Sentinel: Remove persistent tracking data to prevent privacy leaks after history deletion
      Task { @MainActor in
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = cutoff ?? Date.distantPast
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: date) {}
      }
    } catch {
      print("HistoryStore clear failed: \(error)")
    }
  }

  func pruneExpiredRecords() {
    guard
      let cutoff = Calendar.current.date(
        byAdding: .day, value: -Self.retentionDays, to: Date())
    else { return }

    do {
      if #available(macOS 15.0, iOS 18.0, *) {
        try context.delete(
          model: VisitRecord.self,
          where: #Predicate { $0.lastVisitedAt < cutoff }
        )
      } else {
        let descriptor = FetchDescriptor<VisitRecord>(
          predicate: #Predicate { $0.lastVisitedAt < cutoff }
        )
        let expired = try context.fetch(descriptor)
        guard !expired.isEmpty else { return }
        for record in expired {
          context.delete(record)
        }
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
