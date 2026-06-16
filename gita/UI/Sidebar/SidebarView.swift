import SwiftUI

@MainActor
struct SidebarView: View {
    var engine: BrowserEngine
    @State private var hoveringNewTab = false
    @FocusState private var isFocused: Bool

    // MARK: - Subviews
    private var header: some View {
        HStack(spacing: 4) {
            Text("TABS")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(engine.isSidebarFocused ? Color.accentColor : .secondary.opacity(0.8))
            
            if engine.isSidebarFocused {
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
        Button(action: { engine.addNewTab() }) {
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
                        engine.isVerticalTabs = false
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
                        ForEach(engine.tabs) { tab in
                            let idx = engine.tabs.firstIndex(where: { $0.id == tab.id }) ?? 0
                            SidebarTabItem(
                                tab: tab,
                                index: idx,
                                isActive: tab.id == engine.activeTabId,
                                isHighlighted: idx == engine.sidebarFocusedIndex,
                                isSidebarFocused: engine.isSidebarFocused,
                                onSelect: {
                                    engine.sidebarFocusedIndex = idx
                                    engine.selectTab(id: tab.id)
                                    engine.isSidebarFocused = true
                                },
                                onClose: { engine.closeTab(id: tab.id) }
                            )
                            .id(tab.id)
                            .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .scrollIndicators(.hidden)
                .onChange(of: engine.sidebarFocusedIndex) { _, newIndex in
                    scrollToTab(at: newIndex, proxy: proxy)
                }
            }

            Spacer()
            footer
        }
        .frame(width: 210)
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.primary.opacity(0.08)
            )
            .frame(width: 0.5)
        }
        .focusable()
        .focused($isFocused)
        .onTapGesture {
            engine.isSidebarFocused = true
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
        .onChange(of: engine.isSidebarFocused) { _, newValue in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isFocused = newValue
            }
        }
        .onChange(of: isFocused) { _, newValue in
            engine.isSidebarFocused = newValue
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
                engine.sidebarFocusedIndex = (engine.sidebarFocusedIndex + 1) % engine.tabs.count
            }
            return .handled
        case .upArrow:
            if !engine.tabs.isEmpty {
                engine.sidebarFocusedIndex = (engine.sidebarFocusedIndex - 1 + engine.tabs.count) % engine.tabs.count
            }
            return .handled
        case .return, .space:
            if engine.sidebarFocusedIndex >= 0 && engine.sidebarFocusedIndex < engine.tabs.count {
                engine.selectTab(id: engine.tabs[engine.sidebarFocusedIndex].id)
            }
            return .handled
        case .escape:
            engine.isSidebarFocused = false
            return .handled
        case .delete:
            closeFocusedTab()
            return .handled
        default:
            if keyPress.characters == "w" {
                closeFocusedTab()
                return .handled
            } else if keyPress.characters == "n" {
                engine.addNewTab()
                engine.sidebarFocusedIndex = engine.tabs.count - 1
                return .handled
            } else if keyPress.characters == "\u{7F}" || keyPress.characters == "\u{08}" {
                closeFocusedTab()
                return .handled
            }
            return .ignored
        }
    }

    private func closeFocusedTab() {
        if engine.sidebarFocusedIndex >= 0 && engine.sidebarFocusedIndex < engine.tabs.count {
            let tabId = engine.tabs[engine.sidebarFocusedIndex].id
            engine.closeTab(id: tabId)
            if engine.sidebarFocusedIndex >= engine.tabs.count {
                engine.sidebarFocusedIndex = max(0, engine.tabs.count - 1)
            }
        }
    }
}


