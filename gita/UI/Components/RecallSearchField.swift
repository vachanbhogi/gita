import SwiftUI

struct RecallSearchField: View {
  let placeholder: String
  @Binding var text: String
  var isDisabled: Bool = false

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 12))
        .foregroundStyle(.tertiary)

      TextField(placeholder, text: $text)
        .textFieldStyle(.plain)
        .font(.system(size: 13))
        .disabled(isDisabled)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .background {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.primary.opacity(0.06))
        .overlay {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        }
    }
  }
}
