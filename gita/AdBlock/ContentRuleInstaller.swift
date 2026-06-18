import Foundation
import WebKit

@MainActor
final class ContentRuleInstaller {
  private(set) var compiledRuleLists: [WKContentRuleList] = []
  private(set) var isReady = false

  func prepare(manifest: FiltersVersionManifest, bundle: Bundle = .main) async throws {
    if let cachedIDs = ContentRuleCache.identifiers(for: manifest), !cachedIDs.isEmpty {
      guard let store = WKContentRuleListStore.default() else {
        throw AdBlockError.rulesCompileFailed("content rule store unavailable")
      }
      var lists: [WKContentRuleList] = []
      for identifier in cachedIDs {
        if let list = try await lookupRuleList(identifier: identifier, in: store) {
          lists.append(list)
        }
      }
      if lists.count == cachedIDs.count {
        compiledRuleLists = lists
        isReady = true
        return
      }
    }

    let compiled = try await compileAllChunks(manifest: manifest, bundle: bundle)
    compiledRuleLists = compiled
    isReady = true

    let cache = ContentRuleCache(
      fingerprint: manifest.cacheFingerprint,
      ruleListIdentifiers: compiled.map(\.identifier)
    )
    cache.save()
  }

  private func lookupRuleList(
    identifier: String,
    in store: WKContentRuleListStore
  ) async throws -> WKContentRuleList? {
    try await withCheckedThrowingContinuation { continuation in
      store.lookUpContentRuleList(forIdentifier: identifier) { list, error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: list)
        }
      }
    }
  }

  private func compileAllChunks(
    manifest: FiltersVersionManifest,
    bundle: Bundle
  ) async throws -> [WKContentRuleList] {
    guard let store = WKContentRuleListStore.default() else {
      throw AdBlockError.rulesCompileFailed("content rule store unavailable")
    }
    var compiled: [WKContentRuleList] = []

    for index in 0..<manifest.chunkCount {
      let resourceName = "content-rules-\(index)"
      guard
        let url = AdBlockResourcePaths.url(
          forResource: resourceName,
          withExtension: "json",
          bundle: bundle
        )
      else {
        throw AdBlockError.missingResource("\(resourceName).json")
      }

      let json = try String(contentsOf: url, encoding: .utf8)
      let identifier = "gita.adblock.rules.\(index)"

      let list = try await compileRuleList(
        identifier: identifier,
        json: json,
        store: store
      )
      compiled.append(list)
    }

    return compiled
  }

  private func compileRuleList(
    identifier: String,
    json: String,
    store: WKContentRuleListStore
  ) async throws -> WKContentRuleList {
    try await withCheckedThrowingContinuation { continuation in
      store.compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: json) {
        list, error in
        if let error {
          continuation.resume(throwing: AdBlockError.rulesCompileFailed(error.localizedDescription))
        } else if let list {
          continuation.resume(returning: list)
        } else {
          continuation.resume(
            throwing: AdBlockError.rulesCompileFailed("unknown compile failure for \(identifier)")
          )
        }
      }
    }
  }
}
