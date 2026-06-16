import SwiftUI

actor FaviconCache {
  static let shared = FaviconCache()
  private let cache = NSCache<NSURL, NSImage>()
  // ⚡ Bolt Optimization: Track inflight network requests to deduplicate concurrent fetches.
  private var tasks = [URL: Task<NSImage?, Never>]()

  private init() {
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

    // ⚡ Bolt Optimization: If a task for this URL is already inflight, await its completion.
    // This prevents redundant network requests for the same favicon when multiple tabs open concurrently.
    if let existingTask = tasks[url] {
      return await existingTask.value
    }

    // ⚡ Bolt Optimization: Converted from a @MainActor class to an actor.
    // This offloads the decoding of the NSImage(data:) from the main UI thread.
    let task = Task<NSImage?, Never> {
      guard let (data, _) = try? await URLSession.shared.data(from: url),
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

  var body: some View {
    Group {
      if let image {
        Image(nsImage: image)
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
    .task {
      guard let url else { return }
      image = await FaviconCache.shared.loadImage(from: url)
    }
  }
}
