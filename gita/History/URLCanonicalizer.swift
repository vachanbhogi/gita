import Foundation

enum URLCanonicalizer {
  private static let trackingParamPrefixes = ["utm_", "fbclid", "gclid", "mc_eid", "mc_cid"]
  private static let trackingParamExact: Set<String> = ["ref", "source", "campaign", "medium"]

  // ⚡ Bolt Optimization: Use an NSCache wrapper (mapping NSURL to NSURL) to avoid the
  // significant overhead of repeated URLComponents parsing on critical rendering paths.
  private static let cache: NSCache<NSURL, NSURL> = {
    let c = NSCache<NSURL, NSURL>()
    c.countLimit = 1000
    return c
  }()
  private static let nilMarker = NSURL(string: "gita-internal://nil")!

  static func canonicalize(_ url: URL) -> URL? {
    if let cached = cache.object(forKey: url as NSURL) {
      return cached === nilMarker ? nil : cached as URL
    }

    guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
      cache.setObject(nilMarker, forKey: url as NSURL)
      return nil
    }

    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      cache.setObject(nilMarker, forKey: url as NSURL)
      return nil
    }

    // 🛡️ Sentinel: Strip Basic Auth credentials to prevent plaintext leakage in History/Bookmarks
    components.user = nil
    components.password = nil

    if let host = components.host?.lowercased() {
      var normalizedHost = host
      if normalizedHost.hasPrefix("www.") {
        normalizedHost = String(normalizedHost.dropFirst(4))
      }
      components.host = normalizedHost
    }

    if var queryItems = components.queryItems, !queryItems.isEmpty {
      queryItems = queryItems.filter { item in
        let name = item.name.lowercased()
        if trackingParamExact.contains(name) { return false }
        return !trackingParamPrefixes.contains(where: { name.hasPrefix($0) })
      }
      components.queryItems = queryItems.isEmpty ? nil : queryItems
    }

    var path = components.percentEncodedPath
    if path.count > 1, path.hasSuffix("/") {
      path.removeLast()
      components.percentEncodedPath = path
    }

    components.fragment = nil

    let result = components.url
    if let r = result {
      cache.setObject(r as NSURL, forKey: url as NSURL)
    } else {
      cache.setObject(nilMarker, forKey: url as NSURL)
    }

    return result
  }
}
