import Foundation

enum BookmarkStripHoverText {
  static func make(for record: BookmarkRecord) -> String {
    if record.note.isEmpty {
      return record.title
    }
    return "\(record.title)\n\(record.note)"
  }
}
