import SwiftUI

struct TabBar: View {
    @ObservedObject var engine: BrowserEngine

    var body: some View {
        HStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(engine.tabs) { tab in
                        TabButton(tab: tab, activeTabId: engine.activeTabId, onSelect: {
                            engine.selectTab(id: tab.id)
                        }, onClose: {
                            engine.closeTab(id: tab.id)
                        })
                    }
                }
                .padding(.horizontal, 4)
            }

            Button(action: {
                engine.addNewTab()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.plain)
            .padding(6)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.windowBackgroundColor))
    }
}

struct TabButton: View {
    @ObservedObject var tab: Tab
    let activeTabId: UUID
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.system(size: 11, weight: tab.id == activeTabId ? .semibold : .regular))
                .foregroundColor(tab.id == activeTabId ? .primary : .secondary)
                .lineLimit(1)
                .frame(maxWidth: 120)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .padding(2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tab.id == activeTabId ? Color(.controlBackgroundColor) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
