import SwiftUI

@main
struct DayleafApplication: App {
    @StateObject private var viewModel = DayleafViewModel()

    var body: some Scene {
        MenuBarExtra("一日一笺", systemImage: viewModel.menuSystemImage) {
            MenuBarRootView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
}
