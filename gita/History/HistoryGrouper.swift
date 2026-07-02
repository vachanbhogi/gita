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

    // ⚡ Bolt Optimization: Use dedicated arrays instead of Dictionary hashing
    // to prevent O(N) allocation churn and dictionary lookups on the UI render path.
    var today: [VisitRecord] = []
    var yesterday: [VisitRecord] = []
    var thisWeek: [VisitRecord] = []
    var older: [VisitRecord] = []

    for record in records {
      let visited = record.lastVisitedAt
      if visited >= startOfToday {
        today.append(record)
      } else if visited >= startOfYesterday {
        yesterday.append(record)
      } else if visited >= startOfWeek {
        thisWeek.append(record)
      } else {
        older.append(record)
      }
    }

    var result: [(HistorySection, [VisitRecord])] = []
    if !today.isEmpty { result.append((.today, today)) }
    if !yesterday.isEmpty { result.append((.yesterday, yesterday)) }
    if !thisWeek.isEmpty { result.append((.thisWeek, thisWeek)) }
    if !older.isEmpty { result.append((.older, older)) }

    return result
  }
}
