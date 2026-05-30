import UIKit
import SwiftUI

// MARK: - Shake-Erkennung

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShakeNotification")
}

// UIView als First Responder – stabiler als UIViewControllerRepresentable als Background
class ShakeView: UIView {
    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            self?.becomeFirstResponder()
        }
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}

// SwiftUI-Wrapper
struct ShakeDetector: UIViewRepresentable {
    func makeUIView(context: Context) -> ShakeView { ShakeView() }
    func updateUIView(_ uiView: ShakeView, context: Context) {}
}
