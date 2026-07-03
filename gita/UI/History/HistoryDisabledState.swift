import SwiftUI

struct HistoryDisabledState: View {
  var onEnable: (() -> Void)? = nil

  var body: some View {
    ContentUnavailableView {
      Label("History Paused", systemImage: "clock.badge.xmark")
    } description: {
      Text(
        "Browsing history is off. Turn on “Save history” above to start recording again."
      )
    } actions: {
      if let onEnable {
        Button("Turn On History") {
          onEnable()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
