import SwiftUI

@MainActor
struct SaveBookmarkSheet: View {
  let context: BookmarkSheetContext
  let onDismiss: () -> Void

  @State private var title: String = ""
  @State private var note: String = ""
  @State private var pinToBar: Bool = false
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 0) {
      header

      VStack(alignment: .leading, spacing: 14) {
        labeledField("Title", text: $title)

        labeledField("Note (optional)", text: $note)

        Toggle("Pin", isOn: $pinToBar)
          .toggleStyle(.switch)
          .controlSize(.small)
          .font(.system(size: 13))

        if let errorMessage {
          Text(errorMessage)
            .font(.system(size: 11))
            .foregroundStyle(.red)
        }
      }
      .padding(16)

      Rectangle()
        .fill(Color.primary.opacity(0.08))
        .frame(height: 0.5)

      HStack {
        Button("Cancel", action: onDismiss)
          .keyboardShortcut(.cancelAction)

        Spacer()

        Button(context.existing == nil ? "Save" : "Update", action: save)
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.borderedProminent)
      }
      .padding(16)
    }
    .frame(width: 360)
    .background {
      VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
    }
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
    }
    .onAppear {
      title = context.existing?.title ?? context.defaultTitle
      note = context.existing?.note ?? ""
      pinToBar = context.existing?.isPinned ?? false
    }
  }

  private var header: some View {
    HStack {
      Text(context.existing == nil ? "Add Bookmark" : "Edit Bookmark")
        .font(.system(size: 15, weight: .semibold))
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.top, 14)
    .padding(.bottom, 10)
  }

  private func labeledField(_ label: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)

      TextField(label, text: text)
        .textFieldStyle(.plain)
        .font(.system(size: 13))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.06))
            .overlay {
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
        }
    }
  }

  private func save() {
    do {
      try BookmarkStore.shared.save(
        url: context.url,
        title: title,
        note: note,
        isPinned: pinToBar
      )
      onDismiss()
    } catch BookmarkStoreError.pinLimitReached {
      errorMessage = "Pin bar is full (max \(BookmarkPinPolicy.maxPinnedCount)). Unpin one first."
    } catch {
      errorMessage = "Could not save bookmark."
    }
  }
}
