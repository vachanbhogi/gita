import Foundation

enum BookmarkPinPolicy {
  static let maxPinnedCount = 8

  static func canPin(currentPinnedCount: Int) -> Bool {
    currentPinnedCount < maxPinnedCount
  }

  static func nextPinOrder(among pinned: [BookmarkRecord]) -> Int {
    let used = Set(pinned.map(\.pinOrder).filter { $0 >= 0 })
    for order in 0..<maxPinnedCount where !used.contains(order) {
      return order
    }
    return maxPinnedCount - 1
  }
}
