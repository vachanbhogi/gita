import Foundation

enum HistorySection: String, CaseIterable {
  case today = "Today"
  case yesterday = "Yesterday"
  case thisWeek = "This Week"
  case older = "Older"
}

enum HistoryGrouper {
  static func grouped(
    records: [VisitRecord]
  ) -> [(HistorySection, [VisitRecord])] {
    let calendar = Calendar.current
    let now = Date()
    let startOfToday = calendar.startOfDay(for: now)
    let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
    let startOfWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday)!

    var buckets: [HistorySection: [VisitRecord]] = [:]
    for record in records {
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
}
