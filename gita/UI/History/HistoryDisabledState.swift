import SwiftUI

struct HistoryDisabledState: View {
  @Binding var historyEnabled: Bool

  var body: some View {
    ContentUnavailableView(
      "History Paused",
      systemImage: "clock.badge.xmark",
      description: Text(
        "Browsing history is off."
      )
    ) {
      Button("Turn On History") {
        historyEnabled = true
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
