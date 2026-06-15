import SwiftUI

struct AddressBar: View {
    @ObservedObject var tab: Tab
    @State private var textFieldURL: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: tab.goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!tab.canGoBack)

            Button(action: tab.goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!tab.canGoForward)

            Button(action: tab.reload) {
                Image(systemName: "arrow.clockwise")
            }

            Image(systemName: tab.isSecure ? "lock.fill" : "lock.open")
                .foregroundColor(tab.isSecure ? .secondary : .orange)
                .font(.caption)

            TextField("Search or enter address", text: $textFieldURL)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.textBackgroundColor))
                .cornerRadius(6)
                .onSubmit {
                    tab.navigate(to: textFieldURL)
                }

            if tab.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16)
            }
        }
        .padding(8)
        .background(.bar)
        .onChange(of: tab.url) { _, newValue in
            if !isFocused { textFieldURL = newValue }
        }
    }
}
