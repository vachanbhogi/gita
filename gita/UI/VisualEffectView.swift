import SwiftUI
import AppKit

// MARK: - VisualEffectView

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .headerView
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .followsWindowActiveState

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - TransparentWindow
// Configures the host NSWindow for true Safari-style liquid glass appearance:
// - Transparent titlebar
// - Full-size content view (chrome draws into titlebar zone)
// - Unified toolbar style for seamless material continuity

struct TransparentWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            // Core transparency
            window.isOpaque = false
            window.backgroundColor = .clear
            // Full content area — our SwiftUI chrome replaces the titlebar
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            // Unified toolbar look (extends vibrancy into the titlebar region)
            window.toolbarStyle = .unified
            // Smooth corners — match macOS Sequoia window corner radius
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 10
            window.contentView?.layer?.masksToBounds = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
