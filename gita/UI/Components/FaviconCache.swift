import SwiftUI

@MainActor
class FaviconCache {
  static let shared = FaviconCache()
  private let cache = NSCache<NSURL, NSImage>()

  private init() {
    cache.countLimit = 100
  }

  func image(for url: URL) -> NSImage? {
    cache.object(forKey: url as NSURL)
  }

  func setImage(_ image: NSImage, for url: URL) {
    cache.setObject(image, forKey: url as NSURL)
  }

  func loadImage(from url: URL) async -> NSImage? {
    if let cached = image(for: url) { return cached }
    guard let (data, _) = try? await URLSession.shared.data(from: url),
      let image = NSImage(data: data)
    else { return nil }
    setImage(image, for: url)
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
