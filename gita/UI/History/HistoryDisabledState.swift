import SwiftUI

struct HistoryDisabledState: View {
  @Binding var historyEnabled: Bool

  var body: some View {
    ContentUnavailableView {
      Label("History Paused", systemImage: "clock.badge.xmark")
    } description: {
      Text("Browsing history is off. Turn on “Save history” to start recording again.")
    } actions: {
      Button("Turn On History") {
        historyEnabled = true
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.regular)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
