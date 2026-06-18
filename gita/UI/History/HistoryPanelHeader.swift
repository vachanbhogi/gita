import SwiftUI

struct HistoryPanelHeader: View {
  @Binding var historyEnabled: Bool
  let onClearRequest: (HistoryClearRange) -> Void
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 10) {
        Text("History")
          .font(.system(size: 15, weight: .semibold))

        Spacer()

        Menu {
          ForEach(HistoryClearRange.allCases) { range in
            Button("Clear \(range.rawValue)…") {
              onClearRequest(range)
            }
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .help("Clear history")

        Button(action: onClose) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Close")
      }

      HStack(spacing: 8) {
        Toggle("Save history", isOn: $historyEnabled)
          .toggleStyle(.switch)
          .controlSize(.small)
          .font(.system(size: 12))

        Spacer()

        Text("Auto-deletes after 30 days")
          .font(.system(size: 11))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 14)
    .padding(.bottom, 10)
  }
}
