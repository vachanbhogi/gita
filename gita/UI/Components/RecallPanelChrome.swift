import SwiftUI

struct RecallPanelChrome<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .frame(width: 420, height: 520)
      .background {
        VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
      }
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
      }
      .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
  }
}
