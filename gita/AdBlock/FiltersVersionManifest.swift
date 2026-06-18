import Foundation

struct FiltersVersionManifest: Codable, Equatable {
  struct ListDigest: Codable, Equatable {
    let name: String
    let sha256: String
  }

  struct RuleCounts: Codable, Equatable {
    let contentBlocking: Int

    enum CodingKeys: String, CodingKey {
      case contentBlocking = "content_blocking"
    }
  }

  let adblockVersion: String
  let generatedAt: String
  let lists: [ListDigest]
  let resourcesSha256: String
  let chunkCount: Int
  let ruleCounts: RuleCounts

  enum CodingKeys: String, CodingKey {
    case adblockVersion = "adblock_version"
    case generatedAt = "generated_at"
    case lists
    case resourcesSha256 = "resources_sha256"
    case chunkCount = "chunk_count"
    case ruleCounts = "rule_counts"
  }

  var cacheFingerprint: String {
    let listPart = lists.map(\.sha256).sorted().joined(separator: ":")
    return "\(adblockVersion)|\(listPart)|\(resourcesSha256)|\(chunkCount)"
  }

  static func load(from bundle: Bundle = .main) throws -> FiltersVersionManifest {
    guard let url = AdBlockResourcePaths.url(
      forResource: "filters-version",
      withExtension: "json",
      bundle: bundle
    ) else {
      throw AdBlockError.missingResource("filters-version.json")
    }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(FiltersVersionManifest.self, from: data)
  }
}

enum AdBlockError: Error, LocalizedError {
  case missingResource(String)
  case engineLoadFailed
  case rulesCompileFailed(String)

  var errorDescription: String? {
    switch self {
    case .missingResource(let name):
      return "Missing ad block resource: \(name)"
    case .engineLoadFailed:
      return "Failed to load ad block engine"
    case .rulesCompileFailed(let detail):
      return "Failed to compile content rules: \(detail)"
    }
  }
}
