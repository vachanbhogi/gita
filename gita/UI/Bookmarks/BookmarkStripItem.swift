import AppKit
import SwiftUI

struct BookmarkStripItem: View {
  let record: BookmarkRecord
  let density: BookmarkStripDensity
  let layout: BookmarkStripItemLayout
  let onOpen: (_ newTab: Bool) -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void
  let onTogglePin: () -> Void

  @State private var hovered = false
  @State private var showNotePopover = false
  @State private var hoverTask: Task<Void, Never>?

  var body: some View {
    Group {
      switch layout {
      case .horizontal:
        horizontalBody
      case .vertical:
        verticalBody
      }
    }
    .onDisappear {
      hoverTask?.cancel()
      showNotePopover = false
    }
  }

  private var horizontalBody: some View {
    Button(action: openFromClick) {
      HStack(spacing: density == .iconOnly ? 0 : 5) {
        FaviconView(
          url: FaviconURLBuilder.url(forDomain: record.domain),
          size: density == .iconOnly ? 14 : 12,
          iconSize: density == .iconOnly ? 10 : 9
        )

        if density != .iconOnly {
          Text(record.title)
            .font(.system(size: density == .compact ? 10.5 : 11, weight: .medium))
            .foregroundStyle(Color.primary.opacity(hovered ? 0.85 : 0.62))
            .lineLimit(1)
            .frame(maxWidth: density == .compact ? 88 : 120)

          if density == .titled {
            BookmarkExpirationBadge(record: record)
          }
        }
      }
      .padding(.horizontal, density == .iconOnly ? 5 : 7)
      .padding(.vertical, 3)
      .background(chipBackground)
    }
    .buttonStyle(.plain)
    .onHover(perform: handleHover)
    .help(BookmarkStripHoverText.make(for: record))
    .popover(isPresented: $showNotePopover, arrowEdge: .bottom) {
      BookmarkHoverCard(record: record)
        .padding(10)
    }
    .contextMenu { contextMenu }
  }

  private var verticalBody: some View {
    Button(action: openFromClick) {
      HStack(spacing: 7) {
        FaviconView(
          url: FaviconURLBuilder.url(forDomain: record.domain),
          size: 12,
          iconSize: 9
        )

        VStack(alignment: .leading, spacing: 1) {
          Text(record.title)
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(Color.primary.opacity(hovered ? 0.9 : 0.7))
            .lineLimit(1)

          if density == .titled, !record.note.isEmpty {
            Text(record.note)
              .font(.system(size: 10))
              .foregroundStyle(.secondary)
              .lineLimit(hovered ? 2 : 1)
          } else if density == .compact {
            Text(record.domain)
              .font(.system(size: 10))
              .foregroundStyle(.tertiary)
              .lineLimit(1)
          }
        }

        Spacer(minLength: 0)

        if record.isPinned {
          Image(systemName: "pin.fill")
            .font(.system(size: 8))
            .foregroundStyle(.quaternary)
        }

        BookmarkExpirationBadge(record: record)
      }
      .padding(.horizontal, 8)
      .frame(height: density.verticalRowHeight)
      .background(
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .fill(hovered ? Color.primary.opacity(0.06) : Color.clear)
      )
    }
    .buttonStyle(.plain)
    .onHover(perform: handleHover)
    .help(BookmarkStripHoverText.make(for: record))
    .popover(isPresented: $showNotePopover, arrowEdge: .trailing) {
      BookmarkHoverCard(record: record)
        .padding(10)
    }
    .contextMenu { contextMenu }
  }

  private var chipBackground: some View {
    RoundedRectangle(cornerRadius: 5, style: .continuous)
      .fill(hovered ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
  }

  @ViewBuilder
  private var contextMenu: some View {
    Button("Open") { onOpen(false) }
    Button("Open in New Tab") { onOpen(true) }
    Divider()
    Button("Edit…", action: onEdit)
    Button(record.isPinned ? "Unpin" : "Pin", action: onTogglePin)
    Button("Delete", role: .destructive, action: onDelete)
  }

  private func openFromClick() {
    let newTab = NSEvent.modifierFlags.contains(.command)
    onOpen(newTab)
  }

  private func handleHover(_ isHovering: Bool) {
    hovered = isHovering
    hoverTask?.cancel()

    guard isHovering, !record.note.isEmpty || record.expiresAt != nil else {
      showNotePopover = false
      return
    }

    hoverTask = Task {
      try? await Task.sleep(for: .milliseconds(420))
      guard !Task.isCancelled, hovered else { return }
      showNotePopover = true
    }
  }
}

enum BookmarkStripItemLayout {
  case horizontal
  case vertical
}
