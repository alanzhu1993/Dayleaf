import SwiftUI

@main
struct DayLogApplication: App {
    @StateObject private var viewModel = DayLogViewModel()

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
