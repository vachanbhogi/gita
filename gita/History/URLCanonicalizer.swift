import Foundation

enum URLCanonicalizer {
  private static let trackingParamPrefixes = ["utm_", "fbclid", "gclid", "mc_eid", "mc_cid"]
  private static let trackingParamExact: Set<String> = ["ref", "source", "campaign", "medium"]

  static func canonicalize(_ url: URL) -> URL? {
    guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
      return nil
    }

    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return nil
    }

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
    return components.url
  }
}
