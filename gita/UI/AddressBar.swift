import SwiftUI

struct AddressBar: View {
    @ObservedObject var engine: BrowserEngine
    @State private var textFieldURL: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: engine.goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!engine.canGoBack)

            Button(action: engine.goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!engine.canGoForward)

            Button(action: engine.reload) {
                Image(systemName: "arrow.clockwise")
            }

            Image(systemName: engine.isSecure ? "lock.fill" : "lock.open")
                .foregroundColor(engine.isSecure ? .secondary : .orange)
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
                    engine.navigate(to: textFieldURL)
                }

            if engine.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16)
            }
        }
        .padding(8)
        .background(.bar)
        .onChange(of: engine.currentURL) { _, newValue in
            if !isFocused { textFieldURL = newValue }
        }
    }
}
