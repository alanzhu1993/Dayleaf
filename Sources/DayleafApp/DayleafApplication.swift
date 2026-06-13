import SwiftUI

@main
struct DayleafApplication: App {
    @StateObject private var viewModel = DayleafViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView()
                .environmentObject(viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.menuSystemImage)
                if viewModel.menuTitle.isEmpty == false {
                    Text(viewModel.menuTitle)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
}
