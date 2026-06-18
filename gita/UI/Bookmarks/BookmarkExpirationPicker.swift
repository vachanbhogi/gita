import SwiftUI

struct BookmarkExpirationPicker: View {
  @Binding var selection: BookmarkExpiration

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Keep for")
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)

      Picker("Keep for", selection: $selection) {
        ForEach(BookmarkExpiration.allCases) { option in
          Text(option.rawValue).tag(option)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
    }
  }
}
