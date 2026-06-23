import SwiftUI
import WebKit

@MainActor
struct NavControls: View {
  var tab: Tab
  @State private var hoverBack = false
  @State private var hoverFwd = false
  @State private var hoverReload = false

  var body: some View {
    HStack(spacing: 2) {
      navMenu(
        icon: "chevron.left",
        enabled: tab.canGoBack,
        hovering: $hoverBack,
        tooltip: "Go back",
        items: tab.backMenuItems,
        primaryAction: { tab.goBack() },
        onSelect: { tab.go(to: $0) }
      )

      navMenu(
        icon: "chevron.right",
        enabled: tab.canGoForward,
        hovering: $hoverFwd,
        tooltip: "Go forward",
        items: tab.forwardMenuItems,
        primaryAction: { tab.goForward() },
        onSelect: { tab.go(to: $0) }
      )

      navBtn(
        icon: tab.isLoading ? "xmark" : "arrow.clockwise",
        enabled: true,
        hovering: hoverReload,
        tooltip: tab.isLoading ? "Stop loading" : "Reload page",
        action: {
          if tab.isLoading {
            tab.stopLoading()
          } else {
            tab.reload()
          }
        }
      )
      .onHover { hoverReload = $0 }
    }
  }

  @ViewBuilder
  private func navMenu(
    icon: String,
    enabled: Bool,
    hovering: Binding<Bool>,
    tooltip: String,
    items: [WKBackForwardListItem],
    primaryAction: @escaping @MainActor () -> Void,
    onSelect: @escaping @MainActor (WKBackForwardListItem) -> Void
  ) -> some View {
    Menu {
      if items.isEmpty {
        Text("No pages")
          .foregroundStyle(.secondary)
      } else {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
          Button {
            onSelect(item)
          } label: {
            Text(itemLabel(for: item))
          }
        }
      }
    } label: {
      navBtnLabel(icon: icon, enabled: enabled, hovering: hovering.wrappedValue)
    } primaryAction: {
      if enabled { primaryAction() }
    }
    .menuStyle(.borderlessButton)
    .disabled(!enabled)
    .help(tooltip)
    .onHover { hovering.wrappedValue = $0 }
  }

  @ViewBuilder
  private func navBtn(
    icon: String, enabled: Bool, hovering: Bool, tooltip: String,
    action: @MainActor @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      navBtnLabel(icon: icon, enabled: enabled, hovering: hovering)
    }
    .buttonStyle(PressableButtonStyle())
    .disabled(!enabled)
    .help(tooltip)
  }

  @ViewBuilder
  private func navBtnLabel(icon: String, enabled: Bool, hovering: Bool) -> some View {
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

  private func itemLabel(for item: WKBackForwardListItem) -> String {
    if let title = item.title, !title.isEmpty { return title }
    return item.url.host ?? item.url.absoluteString
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
