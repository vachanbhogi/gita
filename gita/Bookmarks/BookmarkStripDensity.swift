import CoreGraphics
import Foundation

enum BookmarkStripDensity: Equatable {
  case titled
  case compact
  case iconOnly

  static func horizontal(forCount count: Int) -> BookmarkStripDensity {
    switch count {
    case 0: return .titled
    case 1...4: return .titled
    case 5...12: return .compact
    default: return .iconOnly
    }
  }

  static func vertical(forCount count: Int) -> BookmarkStripDensity {
    count <= 8 ? .titled : .compact
  }

  var stripHeight: CGFloat {
    switch self {
    case .titled: return 26
    case .compact: return 24
    case .iconOnly: return 22
    }
  }

  var verticalRowHeight: CGFloat {
    switch self {
    case .titled: return 26
    case .compact: return 24
    case .iconOnly: return 22
    }
  }

  var maxVerticalStripHeight: CGFloat { 132 }
}
