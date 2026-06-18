import SwiftUI

// MARK: - ChromeBar
// Safari two-row layout:
//   Row 1 (toolbar, 38pt):  traffic-lights · sidebar · ← → ↻ · [======= address bar =======] · share · Aa · +
//   Row 2 (tab strip, 30pt): [Tab1 ×][Tab2 ×]...

@MainActor
struct ChromeBar: View {
  var engine: BrowserEngine
  var uiState: UIState
  @State private var tabContainerWidth: CGFloat = 800
  @State private var hoveringNewTab = false

  var body: some View {
    VStack(spacing: 0) {
      toolbarRow

      if !uiState.isVerticalTabs {
        tabStrip
          .background(Color.primary.opacity(0.03))

        HorizontalBookmarkStrip(engine: engine, uiState: uiState)
      }
    }
    .background(
      VisualEffectView(material: .headerView, blendingMode: .behindWindow)
    )
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(Color.primary.opacity(0.08))
        .frame(height: 0.5)
    }
  }

  private var toolbarRow: some View {
    HStack(spacing: 6) {
      // Traffic-light clearance zone
      Spacer().frame(width: 78)

      // Sidebar toggle
      ChromeButton(icon: "sidebar.leading", size: 13, tooltip: "Toggle Sidebar") {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
          if !uiState.isVerticalTabs {
            uiState.isVerticalTabs = true
            uiState.sidebarVisible = true
          } else {
            uiState.sidebarVisible.toggle()
          }
        }
      }

      // Navigation: Back / Forward / Reload
      if let tab = engine.activeTab {
        NavControls(tab: tab)
      } else {
        NavControlsPlaceholder()
      }

      Spacer().frame(width: 4)

      // ── Address bar (flex, centered) ────────────────────────────────
      if let tab = engine.activeTab {
        AddressPill(tab: tab, uiState: uiState)
      } else {
        addressPlaceholder
      }

      Spacer().frame(width: 4)

      // Trailing controls
      ShieldsButton(engine: engine)
      ChromeButton(icon: "square.and.arrow.up", size: 12.5, tooltip: "Share") {}
      ChromeButton(icon: "textformat.size", size: 12, tooltip: "Text Size") {}

      // Layout switcher
      ChromeButton(
        icon: uiState.isVerticalTabs ? "rectangle.split.1x2" : "rectangle.split.2x1",
        size: 13,
        tooltip: "Toggle Layout"
      ) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
          uiState.isVerticalTabs.toggle()
        }
      }

      // New tab — rightmost
      ChromeButton(icon: "plus", size: 13, tooltip: "New Tab") {
        engine.addNewTab(uiState: uiState)
      }
      .padding(.trailing, 10)
    }
    .frame(height: 38)
  }

  private var tabStrip: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 0) {
        ForEach(Array(engine.tabs.enumerated()), id: \.element.id) { idx, tab in
          // Skip separator when next tab is active (Safari-style seamless active tab)
          let isNextActive =
            idx + 1 < engine.tabs.count && engine.tabs[idx + 1].id == engine.activeTabId
          let count = CGFloat(max(1, engine.tabs.count))
          let remainingWidth = tabContainerWidth - 32
          let tabWidth = max(100, min(240, remainingWidth / count))

          SafariTabItem(
            tab: tab,
            isActive: tab.id == engine.activeTabId,
            isFirst: idx == 0,
            isLast: idx == engine.tabs.count - 1,
            isNextActive: isNextActive,
            width: tabWidth,
            onSelect: {
              engine.selectTab(id: tab.id)
              uiState.sidebarFocusedIndex = idx
            },
            onClose: { engine.closeTab(id: tab.id, uiState: uiState) }
          )
          .transition(
            .asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
        }

        Button(action: { engine.addNewTab(uiState: uiState) }) {
          Image(systemName: "plus")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.primary.opacity(hoveringNewTab ? 0.85 : 0.55))
            .frame(width: 20, height: 20)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(hoveringNewTab ? Color.primary.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hoveringNewTab = $0 }
        .help("New Tab")
        .padding(.leading, 6)
      }
      .padding(.horizontal, 4)
    }
    .scrollIndicators(.hidden)
    .frame(height: 36)
    .background {
      GeometryReader { geo in
        Color.clear
          .onAppear {
            tabContainerWidth = geo.size.width
          }
          .onChange(of: geo.size.width) { _, newValue in
            tabContainerWidth = newValue
          }
      }
    }
    .overlay(alignment: .top) {
      Rectangle()
        .fill(Color.primary.opacity(0.04))
        .frame(height: 0.5)
    }
  }

  private var addressPlaceholder: some View {
    RoundedRectangle(cornerRadius: 7)
      .fill(Color.primary.opacity(0.05))
      .overlay(
        RoundedRectangle(cornerRadius: 7)
          .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
      )
      .frame(maxWidth: .infinity)
      .frame(height: 26)
  }
}
