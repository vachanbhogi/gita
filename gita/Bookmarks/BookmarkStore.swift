import Foundation
import SwiftData

enum BookmarkStoreError: Error {
  case invalidURL
  case pinLimitReached
}

@MainActor
final class BookmarkStore {
  static let shared = BookmarkStore()

  private let injectedContext: ModelContext?

  private var context: ModelContext {
    injectedContext ?? BrowserDataStore.shared.container.mainContext
  }

  init(context: ModelContext? = nil) {
    self.injectedContext = context
    pruneExpired()
  }

  func bookmark(for url: URL) -> BookmarkRecord? {
    guard let canonical = URLCanonicalizer.canonicalString(for: url) else { return nil }
    guard let record = fetchOne(canonicalURL: canonical) else { return nil }
    guard BookmarkRecordStatus.isActive(record) else { return nil }
    return record
  }

  func isBookmarked(url: URL) -> Bool {
    bookmark(for: url) != nil
  }

  func pruneExpired() {
    BookmarkExpirationPruner.pruneExpired(in: context)
  }

  @discardableResult
  func save(
    url: URL,
    title: String,
    note: String,
    isPinned: Bool,
    expiration: BookmarkExpiration
  ) throws -> BookmarkRecord {
    pruneExpired()

    // ⚡ Bolt Optimization: Parse URL once to avoid redundant URLComponents allocations and string manipulation.
    guard let canonicalizedURL = URLCanonicalizer.canonicalize(url) else {
      throw BookmarkStoreError.invalidURL
    }
    let canonical = canonicalizedURL.absoluteString

    let domain = canonicalizedURL.host?.lowercased() ?? url.host?.lowercased() ?? ""
    let pageTitle = title.isEmpty ? domain : title
    let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
    let expiresAt = BookmarkExpirationDate.expiresAt(for: expiration)

    if let existing = fetchOne(canonicalURL: canonical) {
      existing.title = pageTitle
      existing.note = trimmedNote
      existing.expiresAt = expiresAt
      try applyPinState(isPinned, to: existing)
      try context.save()
      return existing
    }

    let record = BookmarkRecord(
      canonicalURL: canonical,
      title: pageTitle,
      domain: domain,
      note: trimmedNote,
      isPinned: false,
      pinOrder: -1,
      expiresAt: expiresAt
    )
    context.insert(record)
    try applyPinState(isPinned, to: record)
    try context.save()
    return record
  }

  func delete(_ record: BookmarkRecord) {
    context.delete(record)
    try? context.save()
  }

  func togglePin(_ record: BookmarkRecord) throws {
    try applyPinState(!record.isPinned, to: record)
    try context.save()
  }

  func recordOpened(_ record: BookmarkRecord) {
    record.lastOpenedAt = Date()
    try? context.save()
  }

  func pinnedBookmarks() -> [BookmarkRecord] {
    let descriptor = FetchDescriptor<BookmarkRecord>(
      predicate: #Predicate { $0.isPinned },
      sortBy: [SortDescriptor(\.pinOrder)]
    )
    let records = (try? context.fetch(descriptor)) ?? []
    return BookmarkQueryFilter.active(from: records)
  }

  private func fetchOne(canonicalURL: String) -> BookmarkRecord? {
    let descriptor = FetchDescriptor<BookmarkRecord>(
      predicate: #Predicate { $0.canonicalURL == canonicalURL }
    )
    return try? context.fetch(descriptor).first
  }

  private func applyPinState(_ shouldPin: Bool, to record: BookmarkRecord) throws {
    if shouldPin {
      guard !record.isPinned else { return }
      let pinned = pinnedBookmarks()
      guard BookmarkPinPolicy.canPin(currentPinnedCount: pinned.count) else {
        throw BookmarkStoreError.pinLimitReached
      }
      record.isPinned = true
      record.pinOrder = BookmarkPinPolicy.nextPinOrder(among: pinned)
    } else {
      record.isPinned = false
      record.pinOrder = -1
    }
  }
}
