import SwiftUI

struct ChromeButton: View {
  let icon: String
  var size: CGFloat = 13
  var tooltip: String? = nil
  let action: () -> Void
  @State private var hovered = false

  var body: some View {
    let button = Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: size, weight: .regular))
        .foregroundStyle(Color.primary.opacity(hovered ? 0.85 : 0.55))
        .frame(width: 28, height: 28)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(hovered ? Color.primary.opacity(0.08) : Color.clear)
        )
    }
    .buttonStyle(PressableButtonStyle())
    .onHover { hovered = $0 }

    if let tooltip = tooltip {
      button.help(tooltip)
    } else {
      button
    }
  }
}
