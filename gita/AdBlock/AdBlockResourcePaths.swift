import Foundation

enum AdBlockResourcePaths {
  static let subdirectories = ["Resources/AdBlock", "AdBlock"]

  static func url(
    forResource name: String,
    withExtension ext: String,
    bundle: Bundle = .main
  ) -> URL? {
    for subdirectory in subdirectories {
      if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
        return url
      }
    }
    return bundle.url(forResource: name, withExtension: ext)
  }
}
