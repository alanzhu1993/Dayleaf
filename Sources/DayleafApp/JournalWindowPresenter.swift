import AppKit
import SwiftUI

@MainActor
final class JournalWindowPresenter {
    static let shared = JournalWindowPresenter()

    private var window: NSWindow?

    private init() {}

    func show(viewModel: DayleafViewModel) {
        let window = existingOrNewWindow(viewModel: viewModel)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func existingOrNewWindow(viewModel: DayleafViewModel) -> NSWindow {
        if let window {
            return window
        }

        let hostingView = NSHostingView(
            rootView: JournalWindowView()
                .environmentObject(viewModel)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "日记"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 820, height: 560)
        window.center()
        self.window = window
        return window
    }
}
