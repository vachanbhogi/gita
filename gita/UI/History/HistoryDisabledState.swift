import SwiftUI

struct HistoryDisabledState: View {
  var body: some View {
    ContentUnavailableView(
      "History Paused",
      systemImage: "clock.badge.xmark",
      description: Text(
        "Browsing history is off. Turn on “Save history” above to start recording again."
      )
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
