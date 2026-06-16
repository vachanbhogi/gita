import SwiftUI

@MainActor
struct SafariTabItem: View {
  var tab: Tab
  let isActive: Bool
  let isFirst: Bool
  let isLast: Bool
  let isNextActive: Bool
  let width: CGFloat
  let onSelect: () -> Void
  let onClose: () -> Void

  @State private var hovered = false

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 0) {
        HStack(spacing: 6) {
          ZStack {
            if hovered {
              TabCloseButton(action: onClose)
                .transition(.opacity.animation(.easeOut(duration: 0.08)))
            } else {
              if tab.isLoading {
                ProgressView()
                  .scaleEffect(0.32)
                  .frame(width: 12, height: 12)
              } else if tab.isSuspended {
                Image(systemName: "moon.fill")
                  .font(.system(size: 8))
                  .foregroundStyle(.quaternary)
              } else {
                FaviconView(url: tab.faviconURL, size: 13, iconSize: 10)
              }
            }
          }
          .frame(width: 16, height: 16)

          Text(tab.title.isEmpty ? "New Tab" : tab.title)
            .font(.system(size: 12, weight: isActive ? .bold : .medium))
            .foregroundStyle(
              isActive
                ? Color.primary.opacity(0.9)
                : Color.primary.opacity(tab.isSuspended ? 0.38 : 0.65)
            )
            .italic(tab.isSuspended)
            .lineLimit(1)
            .truncationMode(.tail)

          Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(width: width - 0.5)
        .frame(height: 30)
        .background(tabBackground)
        .padding(.vertical, 2)

        if !isActive && !isLast && !isNextActive {
          Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 0.5, height: 20)
        } else {
          Spacer().frame(width: 0.5)
        }
      }
    }
    .buttonStyle(PressableButtonStyle())
    .onHover { hovered = $0 }
    .animation(.easeOut(duration: 0.08), value: hovered)
    .animation(.easeOut(duration: 0.08), value: isActive)
  }

  @ViewBuilder
  private var tabBackground: some View {
    if isActive {
      RoundedRectangle(cornerRadius: 7)
        .fill(Color(NSColor.controlBackgroundColor).opacity(0.95))
        .overlay(
          RoundedRectangle(cornerRadius: 7)
            .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 0.5)
    } else if hovered {
      RoundedRectangle(cornerRadius: 7)
        .fill(Color.primary.opacity(0.06))
    } else {
      Color.clear
    }
  }
}

struct TabCloseButton: View {
  let action: () -> Void
  @State private var hovered = false

  var body: some View {
    Button(action: action) {
      Image(systemName: "xmark")
        .font(.system(size: 7.5, weight: .bold))
        .foregroundStyle(Color.primary.opacity(hovered ? 0.95 : 0.6))
        .frame(width: 16, height: 16)
        .background(
          Circle()
            .fill(hovered ? Color.primary.opacity(0.12) : Color.clear)
        )
    }
    .buttonStyle(PressableButtonStyle())
    .onHover { hovered = $0 }
    .help("Close tab")
  }
}
