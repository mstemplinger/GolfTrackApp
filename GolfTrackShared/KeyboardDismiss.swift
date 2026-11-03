#if os(iOS)
import UIKit

/// Ein Tipp irgendwo außerhalb eines Textfelds schließt die Tastatur – in der
/// ganzen App, ohne dass jede Ansicht es selbst einbauen muss.
///
/// Hängt an jedem Fenster eine Tipp-Geste, die den Tipp **nicht** schluckt
/// (`cancelsTouchesInView = false`): Knöpfe, Listen und Links reagieren
/// weiter wie gewohnt, die Tastatur geht nur zusätzlich zu. Tipps in ein
/// Textfeld zählen nicht, sonst flackerte die Tastatur beim Feldwechsel.
@MainActor
enum KeyboardDismiss {
    private static var observer: NSObjectProtocol?

    /// Einmal beim Start aufrufen (App und App Clip).
    static func install() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { note in
            guard let window = note.object as? UIWindow else { return }
            MainActor.assumeIsolated { attach(to: window) }
        }
    }

    private static func attach(to window: UIWindow) {
        guard !(window.gestureRecognizers ?? []).contains(where: { $0 is DismissTap }) else { return }
        let tap = DismissTap(target: Handler.shared, action: #selector(Handler.tapped(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = Handler.shared
        window.addGestureRecognizer(tap)
    }

    private final class DismissTap: UITapGestureRecognizer {}

    private final class Handler: NSObject, UIGestureRecognizerDelegate {
        static let shared = Handler()

        @objc func tapped(_ recognizer: UITapGestureRecognizer) {
            recognizer.view?.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView { return false }
                view = current.superview
            }
            return true
        }
    }
}
#endif
