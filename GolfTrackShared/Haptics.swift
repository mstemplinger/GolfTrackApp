import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Zentrale Haptik der App. Alle Views spielen Feedback ausschließlich hierüber,
/// damit Stärke und Bedeutung überall gleich sind und sich zentral abschalten lassen.
///
/// Bedeutungsebenen:
/// - `tap`      – normaler Knopfdruck, Kartenauswahl, Navigation
/// - `selection`– Auswahl hat sich geändert (Picker, Chips, Segmente, Tabs)
/// - `light/medium/heavy/soft/rigid` – Impuls mit gewünschtem Gewicht
/// - `success/warning/error` – Ergebnis einer Aktion
/// - Golf-spezifisch: `stroke`, `score`, `holeFinished`, `celebrate`
@MainActor
enum Haptics {

    // MARK: - Einstellung

    /// UserDefaults-Schlüssel, damit die Einstellungen-View denselben Wert per `@AppStorage` binden kann.
    static let enabledKey = "hapticsEnabled"

    /// Haptik global an/aus. Standard: an.
    static var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: enabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: enabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            if newValue { warmUp() }
        }
    }

    // MARK: - Basis-Feedback

    /// Leichter Impuls für normale Knopfdrücke, Kartenauswahl und Navigation.
    static func tap() { impact(.light) }

    /// Auswahl hat sich geändert – Picker, Segmente, Filter-Chips, Tabwechsel.
    static func selection() {
        #if canImport(UIKit) && !os(watchOS)
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
        #endif
    }

    static func light()  { impact(.light) }
    static func medium() { impact(.medium) }
    static func heavy()  { impact(.heavy) }
    static func soft()   { impact(.soft) }
    static func rigid()  { impact(.rigid) }

    #if canImport(UIKit) && !os(watchOS)
    /// Impuls mit frei wählbarem Gewicht und Intensität (0…1).
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        guard isEnabled else { return }
        let generator = impactGenerator(for: style)
        generator.impactOccurred(intensity: intensity)
        generator.prepare()
    }

    /// Ergebnis-Feedback (erfolgreich / Warnung / Fehler).
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type)
        notificationGenerator.prepare()
    }
    #else
    static func impact(_ style: Int = 0, intensity: Double = 1.0) {}
    #endif

    static func success() {
        #if canImport(UIKit) && !os(watchOS)
        notify(.success)
        #endif
    }

    static func warning() {
        #if canImport(UIKit) && !os(watchOS)
        notify(.warning)
        #endif
    }

    static func error() {
        #if canImport(UIKit) && !os(watchOS)
        notify(.error)
        #endif
    }

    // MARK: - Golf-spezifisch

    /// Ein einzelner gezählter Schlag – knackig und schwach, damit auch 8 Schläge
    /// hintereinander nicht nerven.
    static func stroke() { impact(.rigid, intensity: 0.7) }

    /// Schlag zurückgenommen / Wert verringert.
    static func decrement() { impact(.soft, intensity: 0.6) }

    /// Bahn oder Loch abgeschlossen – Feedback richtet sich nach dem Ergebnis zum Par.
    /// - Parameter relativeToPar: Schläge minus Par (negativ = unter Par).
    static func score(relativeToPar: Int) {
        guard isEnabled else { return }
        switch relativeToPar {
        case ..<(-1):  celebrate()          // Eagle oder besser
        case -1:       doubleTap(.medium)   // Birdie
        case 0:        success()            // Par
        case 1:        impact(.soft)        // Bogey
        default:       warning()            // Doppelbogey oder schlechter
        }
    }

    /// Loch/Bahn eingetragen, ohne Par-Bezug (z. B. Minigolf-Zählkarte ohne Par).
    static func holeFinished() { impact(.medium) }

    /// Ass / Hole-in-One – auffällig, aber kurz.
    static func ace() { celebrate() }

    /// Runde beendet, Erfolg freigeschaltet, Kauf abgeschlossen.
    static func celebrate() {
        guard isEnabled else { return }
        #if canImport(UIKit) && !os(watchOS)
        impact(.medium)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 90_000_000)
            impact(.heavy, intensity: 0.8)
            try? await Task.sleep(nanoseconds: 110_000_000)
            notify(.success)
        }
        #endif
    }

    // MARK: - Helfer

    /// Zwei kurze Impulse hintereinander.
    static func doubleTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        #if canImport(UIKit) && !os(watchOS)
        impact(style)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            impact(style, intensity: 0.7)
        }
        #endif
    }

    /// Generatoren vorwärmen, damit der erste Impuls nicht verschluckt wird.
    static func warmUp() {
        #if canImport(UIKit) && !os(watchOS)
        guard isEnabled else { return }
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        impactGenerator(for: .light).prepare()
        impactGenerator(for: .medium).prepare()
        impactGenerator(for: .rigid).prepare()
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle.RawValue: UIImpactFeedbackGenerator] = [:]

    private static func impactGenerator(for style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        if let existing = impactGenerators[style.rawValue] { return existing }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        impactGenerators[style.rawValue] = generator
        return generator
    }
    #endif
}

// MARK: - View-Komfort

extension View {
    /// Haptik beim Antippen – für Views, die auf `onTapGesture` statt `Button` setzen.
    /// Der eigentliche Tap-Handler bleibt unberührt.
    func hapticTap(_ feedback: @escaping @MainActor () -> Void = { Haptics.tap() }) -> some View {
        self.simultaneousGesture(TapGesture().onEnded { feedback() })
    }
}
