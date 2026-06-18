import SwiftData

@MainActor
final class BrowserDataStore {
  static let shared = BrowserDataStore()

  let container: ModelContainer

  private init() {
    let schema = Schema([VisitRecord.self, BookmarkRecord.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      container = try ModelContainer(for: schema, configurations: [config])
    } catch {
      fatalError("Failed to create browser data store: \(error)")
    }
  }
}
