import SwiftUI

@MainActor
struct NavControls: View {
  var tab: Tab
  @State private var hoverBack = false
  @State private var hoverFwd = false
  @State private var hoverReload = false

  var body: some View {
    HStack(spacing: 2) {
      navBtn(
        icon: "chevron.left",
        enabled: tab.canGoBack,
        hovering: hoverBack,
        action: { tab.goBack() }
      )
      .onHover { hoverBack = $0 }

      navBtn(
        icon: "chevron.right",
        enabled: tab.canGoForward,
        hovering: hoverFwd,
        action: { tab.goForward() }
      )
      .onHover { hoverFwd = $0 }

      navBtn(
        icon: tab.isLoading ? "xmark" : "arrow.clockwise",
        enabled: true,
        hovering: hoverReload,
        action: { tab.reload() }
      )
      .onHover { hoverReload = $0 }
    }
  }

  @ViewBuilder
  private func navBtn(
    icon: String, enabled: Bool, hovering: Bool, action: @MainActor @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: 12.5, weight: .regular))
        .foregroundStyle(
          enabled
            ? Color.primary.opacity(hovering ? 0.85 : 0.6)
            : Color.primary.opacity(0.2)
        )
        .frame(width: 26, height: 26)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(hovering && enabled ? Color.primary.opacity(0.08) : Color.clear)
        )
    }
    .buttonStyle(PressableButtonStyle())
    .disabled(!enabled)
  }
}

struct NavControlsPlaceholder: View {
  var body: some View {
    HStack(spacing: 2) {
      ForEach(["chevron.left", "chevron.right", "arrow.clockwise"], id: \.self) { icon in
        Image(systemName: icon)
          .font(.system(size: 12.5, weight: .regular))
          .foregroundStyle(Color.primary.opacity(0.2))
          .frame(width: 26, height: 26)
      }
    }
  }
}
