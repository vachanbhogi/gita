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

    // ⚡ Bolt Optimization: Use dedicated pre-allocated local arrays instead of Dictionary grouping.
    // Avoids hashing overhead and O(N) allocation churn of `buckets[section, default: []]`
    // on the critical UI rendering path.
    var todayRecords: [VisitRecord] = []
    var yesterdayRecords: [VisitRecord] = []
    var thisWeekRecords: [VisitRecord] = []
    var olderRecords: [VisitRecord] = []

    for record in records {
      let visited = record.lastVisitedAt
      if visited >= startOfToday {
        todayRecords.append(record)
      } else if visited >= startOfYesterday {
        yesterdayRecords.append(record)
      } else if visited >= startOfWeek {
        thisWeekRecords.append(record)
      } else {
        olderRecords.append(record)
      }
    }

    var result: [(HistorySection, [VisitRecord])] = []
    if !todayRecords.isEmpty { result.append((.today, todayRecords)) }
    if !yesterdayRecords.isEmpty { result.append((.yesterday, yesterdayRecords)) }
    if !thisWeekRecords.isEmpty { result.append((.thisWeek, thisWeekRecords)) }
    if !olderRecords.isEmpty { result.append((.older, olderRecords)) }
    return result
  }
}
