import SwiftUI

struct HistoryDisabledState: View {
  @Binding var historyEnabled: Bool

  var body: some View {
    ContentUnavailableView {
      Label("History Paused", systemImage: "clock.badge.xmark")
    } description: {
      Text("Browsing history is off.")
    } actions: {
      Button("Turn on Save History") {
        historyEnabled = true
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
