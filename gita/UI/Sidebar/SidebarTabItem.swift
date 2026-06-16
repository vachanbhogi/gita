import SwiftUI

@MainActor
struct SidebarTabItem: View {
  var tab: Tab
  let index: Int
  let isActive: Bool
  let isHighlighted: Bool
  let isSidebarFocused: Bool
  let onSelect: () -> Void
  let onClose: () -> Void
  @State private var hovered = false
  @State private var isAppeared = false

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 6) {
        ZStack {
          if tab.isLoading {
            ProgressView()
              .scaleEffect(0.32)
              .frame(width: 12, height: 12)
          } else {
            if let faviconURL = tab.faviconURL {
              AsyncImage(url: faviconURL) { phase in
                switch phase {
                case .success(let image):
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .clipShape(.rect(cornerRadius: 2))
                default:
                  Image(systemName: "globe")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.tertiary)
                }
              }
              .frame(width: 12, height: 12)
            } else {
              Image(systemName: "globe")
                .font(.system(size: 9.5))
                .foregroundStyle(.tertiary)
            }
          }
        }
        .frame(width: 14, height: 14)

        Text(tab.title.isEmpty ? "New Tab" : tab.title)
          .font(.system(size: 11.5, weight: isActive ? .semibold : .medium))
          .foregroundStyle(isActive ? Color.primary : Color.primary.opacity(0.65))
          .lineLimit(1)
          .truncationMode(.tail)

        Spacer()

        if hovered {
          Button(action: onClose) {
            Image(systemName: "xmark")
              .font(.system(size: 7, weight: .bold))
              .foregroundStyle(Color.primary.opacity(0.6))
              .frame(width: 14, height: 14)
              .background(
                Circle()
                  .fill(Color.primary.opacity(0.1))
              )
          }
          .buttonStyle(PressableButtonStyle())
        }
      }
      .padding(.horizontal, 8)
      .frame(height: 26)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(
            isActive
              ? Color.primary.opacity(0.08) : (hovered ? Color.primary.opacity(0.04) : Color.clear))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(
            isHighlighted && isSidebarFocused ? Color.accentColor : Color.clear, lineWidth: 1.5)
      )
    }
    .buttonStyle(PressableButtonStyle())
    .onHover { hovered = $0 }
    .offset(x: isAppeared ? 0 : -8)
    .opacity(isAppeared ? 1 : 0)
    .onAppear {
      let delay = Double(index) * 0.035
      withAnimation(.spring(response: 0.35, dampingFraction: 0.8).delay(delay)) {
        isAppeared = true
      }
    }
  }
}
