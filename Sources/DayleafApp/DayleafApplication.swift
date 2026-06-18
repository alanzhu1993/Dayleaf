import SwiftUI

@main
struct DayleafApplication: App {
    @StateObject private var coordinator = DayleafAppCoordinator()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(onShortcutChanged: coordinator.registerQuickCaptureShortcut)
                .environmentObject(coordinator.viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: coordinator.viewModel.menuSystemImage)
                if coordinator.viewModel.menuTitle.isEmpty == false {
                    Text(coordinator.viewModel.menuTitle)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(onShortcutChanged: coordinator.registerQuickCaptureShortcut)
                .environmentObject(coordinator.viewModel)
        }
    }
}
