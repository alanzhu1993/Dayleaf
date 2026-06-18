import Combine
import Foundation

@MainActor
final class DayleafAppCoordinator: ObservableObject {
    let viewModel: DayleafViewModel
    let shortcutManager: GlobalShortcutManager

    private let quickCapturePresenter: QuickCaptureWindowPresenter
    private var cancellables = Set<AnyCancellable>()

    init(
        viewModel: DayleafViewModel = DayleafViewModel(),
        shortcutManager: GlobalShortcutManager = GlobalShortcutManager(),
        quickCapturePresenter: QuickCaptureWindowPresenter = QuickCaptureWindowPresenter()
    ) {
        self.viewModel = viewModel
        self.shortcutManager = shortcutManager
        self.quickCapturePresenter = quickCapturePresenter

        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)

        registerQuickCaptureShortcut()
    }

    func registerQuickCaptureShortcut() {
        let viewModel = viewModel
        let presenter = quickCapturePresenter
        shortcutManager.register(shortcut: viewModel.quickCaptureShortcut) {
            presenter.show(viewModel: viewModel)
        }
        viewModel.setQuickCaptureShortcutRegistrationMessage(shortcutManager.registrationMessage)
    }
}
