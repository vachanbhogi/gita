import Foundation

enum BookmarkStripHoverText {
  static func make(for record: BookmarkRecord) -> String {
    var lines = [record.title]
    if !record.note.isEmpty {
      lines.append(record.note)
    }
    if let label = BookmarkExpirationLabel.shortLabel(for: record) {
      lines.append("Expires in \(label)")
    }
    return lines.joined(separator: "\n")
  }
}
