import Foundation

enum URLCanonicalizer {
  private static let trackingParamPrefixes = ["utm_", "fbclid", "gclid", "mc_eid", "mc_cid"]
  private static let trackingParamExact: Set<String> = ["ref", "source", "campaign", "medium"]

  // ⚡ Bolt Optimization: Cache to prevent redundant URLComponents parsing and allocations
  private static let cache = NSCache<NSURL, NSURL>()
  private static let lock = NSLock()

  static func canonicalize(_ url: URL) -> URL? {
    let nsURL = url as NSURL
    lock.lock()
    if let cached = cache.object(forKey: nsURL) {
      lock.unlock()
      // If it's cached as an empty NSURL (URL with empty string), it means canonicalization failed/returned nil.
      if cached.absoluteString?.isEmpty == true {
        return nil
      }
      return cached as URL
    }
    lock.unlock()

    guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
      cacheResult(nil, for: nsURL)
      return nil
    }

    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      cacheResult(nil, for: nsURL)
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
    cacheResult(result, for: nsURL)
    return result
  }

  private static func cacheResult(_ result: URL?, for key: NSURL) {
    let valueToCache: NSURL
    if let result = result {
      valueToCache = result as NSURL
    } else {
      // Store empty URL to represent `nil` result
      valueToCache = NSURL(string: "") ?? NSURL()
    }

    lock.lock()
    cache.setObject(valueToCache, forKey: key)
    lock.unlock()
  }
}
