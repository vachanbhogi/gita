import SwiftUI

@MainActor
struct SidebarView: View {
    var engine: BrowserEngine
    @State private var hoveringNewTab = false

    var body: some View {
        VStack(spacing: 0) {
            // Sidebar header
            HStack {
                Text("TABS")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .padding(.leading, 12)
                Spacer()
            }
            .frame(height: 24)
            .padding(.top, 10)

            // New Tab capsule button
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
            .buttonStyle(.plain)
            .onHover { hoveringNewTab = $0 }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)

            // Scrollable tabs list
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(engine.tabs) { tab in
                        SidebarTabItem(
                            tab: tab,
                            isActive: tab.id == engine.activeTabId,
                            onSelect: { engine.selectTab(id: tab.id) },
                            onClose: { engine.closeTab(id: tab.id) }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            .scrollIndicators(.hidden)

            Spacer()

            // Footer / Layout switch option
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
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(8)
            }
        }
        .frame(width: 210)
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 0.5)
        }
    }
}

@MainActor
struct SidebarTabItem: View {
    var tab: Tab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                // Favicon / Loading state
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

                // Title
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .font(.system(size: 11.5, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? Color.primary : Color.primary.opacity(0.65))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()

                // Close button
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
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? Color.primary.opacity(0.08) : (hovered ? Color.primary.opacity(0.04) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}
