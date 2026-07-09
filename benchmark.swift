import Foundation

struct BookmarkRecord {
  var isPinned: Bool
  var pinOrder: Int
  var createdAt: Date
  var lastOpenedAt: Date?
}

func generateRecords(count: Int) -> [BookmarkRecord] {
  var records = [BookmarkRecord]()
  for i in 0..<count {
    records.append(BookmarkRecord(
      isPinned: i % 100 == 0,
      pinOrder: i % 8,
      createdAt: Date(),
      lastOpenedAt: i % 2 == 0 ? Date() : nil
    ))
  }
  return records
}

func testOld(_ records: [BookmarkRecord]) {
  let pinned = records.filter(\.isPinned).sorted { $0.pinOrder < $1.pinOrder }
  let library = records.filter { !$0.isPinned }.sorted { lhs, rhs in
    let lhsDate = lhs.lastOpenedAt ?? lhs.createdAt
    let rhsDate = rhs.lastOpenedAt ?? rhs.createdAt
    return lhsDate > rhsDate
  }
}

func testNew(_ records: [BookmarkRecord]) {
  var pinned: [BookmarkRecord] = []
  var library: [BookmarkRecord] = []
  pinned.reserveCapacity(8)
  library.reserveCapacity(records.count)

  for record in records {
    if record.isPinned {
      pinned.append(record)
    } else {
      library.append(record)
    }
  }

  pinned.sort { $0.pinOrder < $1.pinOrder }
  library.sort { lhs, rhs in
    let lhsDate = lhs.lastOpenedAt ?? lhs.createdAt
    let rhsDate = rhs.lastOpenedAt ?? rhs.createdAt
    return lhsDate > rhsDate
  }
}

let records = generateRecords(count: 100_000)

let start1 = CFAbsoluteTimeGetCurrent()
for _ in 0..<10 { testOld(records) }
let end1 = CFAbsoluteTimeGetCurrent()
print("Old time: \((end1 - start1) / 10) s")

let start2 = CFAbsoluteTimeGetCurrent()
for _ in 0..<10 { testNew(records) }
let end2 = CFAbsoluteTimeGetCurrent()
print("New time: \((end2 - start2) / 10) s")
