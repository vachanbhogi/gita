import XCTest
import SwiftData
@testable import gita

@MainActor
final class BookmarkStoreTests: XCTestCase {
  var container: ModelContainer!
  var context: ModelContext!
  var store: BookmarkStore!

  override func setUp() async throws {
    let schema = Schema([VisitRecord.self, BookmarkRecord.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    container = try ModelContainer(for: schema, configurations: [config])
    context = container.mainContext
    store = BookmarkStore(context: context)
  }

  override func tearDown() async throws {
    store = nil
    context = nil
    container = nil
  }

  func testSaveNewBookmark() throws {
    let url = URL(string: "https://example.com/page")!
    let title = "Example Page"
    let note = "Test Note"

    let record = try store.save(
      url: url,
      title: title,
      note: note,
      isPinned: true,
      expiration: .permanent
    )

    XCTAssertEqual(record.title, title)
    XCTAssertEqual(record.note, note)
    XCTAssertEqual(record.domain, "example.com")
    XCTAssertEqual(record.isPinned, true)
    XCTAssertNil(record.expiresAt)
    XCTAssertTrue(store.isBookmarked(url: url))
  }

  func testSaveExistingBookmarkUpdatesProperties() throws {
    let url = URL(string: "https://example.com/page")!

    // First save
    try store.save(
      url: url,
      title: "Old Title",
      note: "Old Note",
      isPinned: false,
      expiration: .permanent
    )

    // Save again to update
    let record = try store.save(
      url: url,
      title: "New Title",
      note: "New Note",
      isPinned: true,
      expiration: .oneDay
    )

    XCTAssertEqual(record.title, "New Title")
    XCTAssertEqual(record.note, "New Note")
    XCTAssertEqual(record.isPinned, true)
    XCTAssertNotNil(record.expiresAt)
  }

  func testSaveWithEmptyTitleFallsBackToDomain() throws {
    let url = URL(string: "https://example.com/page")!

    let record = try store.save(
      url: url,
      title: "",
      note: "",
      isPinned: false,
      expiration: .permanent
    )

    XCTAssertEqual(record.title, "example.com")
  }

  func testSaveInvalidURLThrowsError() {
    let url = URL(string: "invalid-url")!

    XCTAssertThrowsError(try store.save(
      url: url,
      title: "Title",
      note: "",
      isPinned: false,
      expiration: .permanent
    )) { error in
      XCTAssertEqual(error as? BookmarkStoreError, BookmarkStoreError.invalidURL)
    }
  }

  func testSaveEnforcesPinLimit() throws {
    // Fill up to max pins
    for i in 0..<BookmarkPinPolicy.maxPinnedCount {
      let url = URL(string: "https://example.com/page\(i)")!
      try store.save(
        url: url,
        title: "Page \(i)",
        note: "",
        isPinned: true,
        expiration: .permanent
      )
    }

    // Try to pin one more
    let extraUrl = URL(string: "https://example.com/extra")!

    XCTAssertThrowsError(try store.save(
      url: extraUrl,
      title: "Extra Page",
      note: "",
      isPinned: true,
      expiration: .permanent
    )) { error in
      XCTAssertEqual(error as? BookmarkStoreError, BookmarkStoreError.pinLimitReached)
    }

    // Should still save successfully if not pinned
    let record = try store.save(
      url: extraUrl,
      title: "Extra Page",
      note: "",
      isPinned: false,
      expiration: .permanent
    )

    XCTAssertFalse(record.isPinned)
  }
}
