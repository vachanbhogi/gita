import XCTest
import SwiftData
@testable import gita

@MainActor
final class BookmarkStoreTests: XCTestCase {
  var container: ModelContainer!
  var context: ModelContext!
  var store: BookmarkStore!

  override func setUpWithError() throws {
    let schema = Schema([VisitRecord.self, BookmarkRecord.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    container = try ModelContainer(for: schema, configurations: [config])
    context = container.mainContext
    store = BookmarkStore(context: context)
  }

  override func tearDownWithError() throws {
    store = nil
    context = nil
    container = nil
  }

  func testSaveNewBookmark() throws {
    let url = URL(string: "https://example.com/test")!
    let title = "Example Test"
    let note = "A test note"
    let isPinned = true
    let expiration = BookmarkExpiration.sevenDays

    let record = try store.save(
      url: url,
      title: title,
      note: note,
      isPinned: isPinned,
      expiration: expiration
    )

    XCTAssertEqual(record.canonicalURL, "https://example.com/test")
    XCTAssertEqual(record.title, title)
    XCTAssertEqual(record.note, note)
    XCTAssertTrue(record.isPinned)
    XCTAssertNotNil(record.expiresAt)

    let savedRecord = store.bookmark(for: url)
    XCTAssertNotNil(savedRecord)
    XCTAssertEqual(savedRecord?.canonicalURL, "https://example.com/test")
  }

  func testSaveExistingBookmarkUpdatesProperties() throws {
    let url = URL(string: "https://example.com/test")!

    // Save initially
    try store.save(
      url: url,
      title: "Initial Title",
      note: "Initial Note",
      isPinned: false,
      expiration: .permanent
    )

    // Save again with new properties
    let updatedRecord = try store.save(
      url: url,
      title: "Updated Title",
      note: "Updated Note",
      isPinned: true,
      expiration: .oneDay
    )

    XCTAssertEqual(updatedRecord.title, "Updated Title")
    XCTAssertEqual(updatedRecord.note, "Updated Note")
    XCTAssertTrue(updatedRecord.isPinned)
    XCTAssertNotNil(updatedRecord.expiresAt)

    // Verify it didn't create a duplicate
    let descriptor = FetchDescriptor<BookmarkRecord>()
    let records = try context.fetch(descriptor)
    XCTAssertEqual(records.count, 1)
  }

  func testSaveInvalidURLThrowsError() {
    let url = URL(string: "not-a-valid-url")!

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
}
