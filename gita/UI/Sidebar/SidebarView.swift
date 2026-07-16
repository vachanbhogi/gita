import SwiftUI

@MainActor
struct SidebarView: View {
  var engine: BrowserEngine
  var uiState: UIState
  @State private var hoveringNewTab = false
  @FocusState private var isFocused: Bool

  // MARK: - Subviews
  private var header: some View {
    HStack(spacing: 4) {
      Text("TABS")
        .font(.system(size: 9.5, weight: .bold))
        .foregroundStyle(uiState.isSidebarFocused ? Color.accentColor : .secondary.opacity(0.8))

      if uiState.isSidebarFocused {
        Image(systemName: "keyboard")
          .font(.system(size: 9))
          .foregroundStyle(Color.accentColor)
          .transition(.opacity.combined(with: .scale))
      }

      Spacer()
    }
    .padding(.horizontal, 12)
    .frame(height: 24)
    .padding(.top, 10)
  }

  private var newTabButton: some View {
    Button(action: { engine.addNewTab(uiState: uiState) }) {
      HStack {
        Image(systemName: "plus")
          .font(.system(size: 11, weight: .bold))
        Text("New Tab")
          .font(.system(size: 11.5, weight: .medium))
        Spacer()
      }
      .foregroundStyle(Color.primary.opacity(hoveringNewTab ? 0.9 : 0.7))
      .padding(.horizontal, 12)
      .frame(height: 28)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(hoveringNewTab ? Color.primary.opacity(0.08) : Color.primary.opacity(0.04))
      )
    }
    .buttonStyle(PressableButtonStyle())
    .onHover { hoveringNewTab = $0 }
    .help("New Tab (⌘T)")
    .padding(.horizontal, 8)
    .padding(.bottom, 6)
  }

  private var footer: some View {
    VStack(spacing: 0) {
      Divider().opacity(0.12)

      HStack {
        Spacer()

        Button(action: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            uiState.isVerticalTabs = false
          }
        }) {
          HStack(spacing: 6) {
            Image(systemName: "rectangle.split.1x2")
              .font(.system(size: 10.5))
            Text("Horizontal Tabs")
              .font(.system(size: 11, weight: .medium))
          }
          .foregroundStyle(.secondary)
          .padding(.vertical, 5)
          .padding(.horizontal, 8)
          .background(
            RoundedRectangle(cornerRadius: 6)
              .fill(Color.primary.opacity(0.04))
          )
        }
        .buttonStyle(PressableButtonStyle())
        .help("Switch to Horizontal Tabs")

        Spacer()
      }
      .padding(8)
    }
  }

  // MARK: - Body
  var body: some View {
    VStack(spacing: 0) {
      header
      newTabButton

      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: 2) {
            ForEach(Array(engine.tabs.enumerated()), id: \.element.id) { idx, tab in
              SidebarTabItem(
                tab: tab,
                index: idx,
                isActive: tab.id == engine.activeTabId,
                isHighlighted: idx == uiState.sidebarFocusedIndex,
                isSidebarFocused: uiState.isSidebarFocused,
                onSelect: {
                  uiState.sidebarFocusedIndex = idx
                  engine.selectTab(id: tab.id)
                  uiState.isSidebarFocused = true
                },
                onClose: { engine.closeTab(id: tab.id, uiState: uiState) }
              )
              .id(tab.id)
              .transition(
                .asymmetric(
                  insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
            }
          }
          .padding(.horizontal, 8)
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: .infinity)
        .onChange(of: uiState.sidebarFocusedIndex) { _, newIndex in
          scrollToTab(at: newIndex, proxy: proxy)
        }
      }

      VerticalBookmarkStrip(engine: engine, uiState: uiState)

      footer
    }
    .frame(width: 210)
    .background(
      VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
    )
    .overlay(alignment: .trailing) {
      Rectangle()
        .fill(
          Color.primary.opacity(0.08)
        )
        .frame(width: 0.5)
    }
    .focusable()
    .focused($isFocused)
    .onTapGesture {
      uiState.isSidebarFocused = true
    }
    .onKeyPress { keyPress in
      handleKeyPress(keyPress)
    }
    .onChange(of: uiState.isSidebarFocused) { _, newValue in
      withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
        isFocused = newValue
      }
    }
    .onChange(of: isFocused) { _, newValue in
      uiState.isSidebarFocused = newValue
    }
  }

  // MARK: - Navigation Logic Helpers
  private func scrollToTab(at newIndex: Int, proxy: ScrollViewProxy) {
    let tabsCount = engine.tabs.count
    guard newIndex >= 0 && newIndex < tabsCount else { return }
    let targetTabId = engine.tabs[newIndex].id
    withAnimation(.easeOut(duration: 0.15)) {
      proxy.scrollTo(targetTabId)
    }
  }

  private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
    switch keyPress.key {
    case .downArrow:
      if !engine.tabs.isEmpty {
        uiState.sidebarFocusedIndex = (uiState.sidebarFocusedIndex + 1) % engine.tabs.count
      }
      return .handled
    case .upArrow:
      if !engine.tabs.isEmpty {
        uiState.sidebarFocusedIndex =
          (uiState.sidebarFocusedIndex - 1 + engine.tabs.count) % engine.tabs.count
      }
      return .handled
    case .return, .space:
      if uiState.sidebarFocusedIndex >= 0 && uiState.sidebarFocusedIndex < engine.tabs.count {
        engine.selectTab(id: engine.tabs[uiState.sidebarFocusedIndex].id)
      }
      return .handled
    case .escape:
      uiState.isSidebarFocused = false
      return .handled
    case .delete:
      closeFocusedTab()
      return .handled
    default:
      if keyPress.characters == "w" {
        closeFocusedTab()
        return .handled
      } else if keyPress.characters == "n" {
        engine.addNewTab(uiState: uiState)
        return .handled
      } else if keyPress.characters == "\u{7F}" || keyPress.characters == "\u{08}" {
        closeFocusedTab()
        return .handled
      }
      return .ignored
    }
  }

  private func closeFocusedTab() {
    if uiState.sidebarFocusedIndex >= 0 && uiState.sidebarFocusedIndex < engine.tabs.count {
      let tabId = engine.tabs[uiState.sidebarFocusedIndex].id
      engine.closeTab(id: tabId, uiState: uiState)
    }
  }
}
