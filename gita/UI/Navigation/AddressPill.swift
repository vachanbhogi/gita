import SwiftUI

@MainActor
struct AddressPill: View {
  var tab: Tab
  var uiState: UIState
  @State private var editText: String = ""
  @FocusState private var focused: Bool
  @State private var hovering = false

  private var displayHost: String {
    guard !tab.url.isEmpty,
      let url = URL(string: tab.url),
      let host = url.host
    else { return tab.url }
    return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
  }

  var body: some View {
    HStack(spacing: 5) {
      ZStack {
        // The ACTUAL TextField (always handles hit testing and OS focus)
        TextField(focused ? "Search or enter website name" : "", text: $editText)
          .focused($focused)
          .textFieldStyle(.plain)
          .font(.system(size: 12))
          .foregroundStyle(focused ? Color.primary : Color.clear)
          .onSubmit {
            tab.navigate(to: editText)
            focused = false
          }

        // Display mode — centered host (on top, but passes clicks to the text field)
        HStack(spacing: 4) {
          // Lock icon
          Image(systemName: tab.isSecure ? "lock.fill" : "lock.open.fill")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(
              tab.isSecure
                ? AnyShapeStyle(Color.primary.opacity(0.35))
                : AnyShapeStyle(Color.orange.opacity(0.7))
            )

          Text(displayHost.isEmpty ? "Search or enter website name" : displayHost)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(
              displayHost.isEmpty
                ? Color.primary.opacity(0.3)
                : Color.primary.opacity(0.8)
            )
            .lineLimit(1)
            .truncationMode(.middle)
        }
        .opacity(focused ? 0.0 : 1.0)
        .allowsHitTesting(false)  // Click passes straight through to TextField
        .frame(maxWidth: .infinity, alignment: .center)
      }

      if tab.isLoading {
        ProgressView()
          .scaleEffect(0.38)
          .frame(width: 10, height: 10)
      }
    }
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity)
    .frame(height: 26)
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(
          focused
            ? Color(NSColor.textBackgroundColor).opacity(0.9)
            : (hovering ? Color.primary.opacity(0.07) : Color.primary.opacity(0.04))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 6)
            .stroke(
              focused ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.04),
              lineWidth: focused ? 1.5 : 0.5
            )
        )
    )
    .shadow(
      color: focused ? Color.accentColor.opacity(0.1) : .clear,
      radius: 4, x: 0, y: 1
    )
    .animation(.easeOut(duration: 0.15), value: focused)
    .animation(.easeOut(duration: 0.1), value: hovering)
    .onHover { hovering = $0 }
    .onChange(of: tab.url) { _, newURL in
      if !focused { editText = newURL }
    }
    .onAppear { editText = tab.url }
    .onChange(of: uiState.isAddressBarFocused) { _, newValue in
      if newValue {
        editText = tab.url
        focused = true
      }
    }
    .onChange(of: focused) { _, newValue in
      if !newValue {
        uiState.isAddressBarFocused = false
      }
    }
  }
}
