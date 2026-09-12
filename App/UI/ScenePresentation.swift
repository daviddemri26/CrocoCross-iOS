import SwiftUI
import UIKit

/// Prefer landscape on iPad while retaining all orientations for system resizing/multitasking.
/// Inner foldable displays and all layout decisions use the actual window size, not a model list.
struct ScenePresentation: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController {
        private var requested = false
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard !requested, traitCollection.userInterfaceIdiom == .pad,
                  let scene = view.window?.windowScene else { return }
            requested = true
            guard !scene.interfaceOrientation.isLandscape else { return }
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { _ in
                // Split View or a system-constrained window may refuse. Adaptive layout remains usable.
            }
        }
    }
}
