import SwiftUI

final class SendableCache<KeyType: AnyObject, ObjectType: AnyObject>: @unchecked Sendable {
  private let cache = NSCache<KeyType, ObjectType>()

  var countLimit: Int {
    get { cache.countLimit }
    set { cache.countLimit = newValue }
  }

  func object(forKey key: KeyType) -> ObjectType? {
    cache.object(forKey: key)
  }

  func setObject(_ obj: ObjectType, forKey key: KeyType) {
    cache.setObject(obj, forKey: key)
  }
}

actor FaviconCache {
  static let shared = FaviconCache()
  private let cache = SendableCache<NSURL, NSImage>()
  // ⚡ Bolt Optimization: Track inflight network requests to deduplicate concurrent fetches.
  private var tasks = [URL: Task<NSImage?, Never>]()

  // 🛡️ Sentinel: Custom ephemeral URLSession with short timeouts to prevent DoS from hanging connections.
  private let session: URLSession

  private init() {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 5.0
    config.timeoutIntervalForResource = 10.0
    self.session = URLSession(configuration: config)

    // Must be set after all stored properties are initialized
    cache.countLimit = 100
  }

  nonisolated func image(for url: URL) -> NSImage? {
    cache.object(forKey: url as NSURL)
  }

  nonisolated func setImage(_ image: NSImage, for url: URL) {
    cache.setObject(image, forKey: url as NSURL)
  }

  func loadImage(from url: URL) async -> NSImage? {
    if let cached = image(for: url) { return cached }

    // 🛡️ Sentinel: Defense in depth - restrict scheme to http/https to prevent SSRF and local file reads via file: scheme
    let scheme = url.scheme?.lowercased()
    guard scheme == "http" || scheme == "https" else { return nil }

    // ⚡ Bolt Optimization: If a task for this URL is already inflight, await its completion.
    // This prevents redundant network requests for the same favicon when multiple tabs open concurrently.
    if let existingTask = tasks[url] {
      return await existingTask.value
    }

    // ⚡ Bolt Optimization: Converted from a @MainActor class to an actor.
    // This offloads the decoding of the NSImage(data:) from the main UI thread.
    let task = Task<NSImage?, Never> {
      guard let (data, _) = try? await self.session.data(from: url),
        let fetchedImage = NSImage(data: data)
      else { return nil }
      self.setImage(fetchedImage, for: url)
      return fetchedImage
    }

    tasks[url] = task
    let image = await task.value
    tasks[url] = nil

    return image
  }
}

struct FaviconView: View {
  let url: URL?
  let size: CGFloat
  let iconSize: CGFloat

  @State private var image: NSImage?

  // ⚡ Bolt Optimization: Synchronously resolve from cache to avoid flicker on re-render.
  private var resolvedImage: NSImage? {
    if let url = url, let cached = FaviconCache.shared.image(for: url) {
      return cached
    }
    return image
  }

  var body: some View {
    Group {
      if let img = resolvedImage {
        Image(nsImage: img)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: size, height: size)
          .clipShape(.rect(cornerRadius: 2))
      } else {
        Image(systemName: "globe")
          .font(.system(size: iconSize))
          .foregroundStyle(.tertiary)
      }
    }
    .frame(width: size, height: size)
    // ⚡ Bolt Optimization: Use .task(id: url) to refetch if URL changes, and skip async if already cached.
    .task(id: url) {
      guard let url = url else { return }
      if FaviconCache.shared.image(for: url) != nil { return }
      image = await FaviconCache.shared.loadImage(from: url)
    }
  }
}
