import SwiftUI

// MARK: - Anzeige-Steuerung

/// Entscheidet, ob die Update-Einführung gezeigt wird.
enum WhatsNew {

    /// Kennung dieser Neuerung – bewusst **nicht** die App-Version, sonst
    /// erscheint die Einführung nach jedem Bugfix-Release erneut.
    /// Vorher: `positions-tracking-1` (Laufspur, Herbst 2026).
    static let releaseKey = "crowd-positions-1"
    static let storageKey = "whatsNew.lastSeenRelease"

    static var hasSeenCurrent: Bool {
        UserDefaults.standard.string(forKey: storageKey) == releaseKey
    }

    static func markCurrentAsSeen() {
        UserDefaults.standard.set(releaseKey, forKey: storageKey)
    }

    /// Beim Start aufrufen: liefert, ob die Einführung gezeigt werden soll.
    ///
    /// Neuinstallationen bekommen sie nicht – für die ist ohnehin alles neu,
    /// und sie durchlaufen bereits das reguläre Onboarding (die Frage nach dem
    /// Teilen kommt dort nach der ersten Runde mit Laufspur). Wer schon teilt,
    /// braucht den Hinweis auch nicht.
    static func evaluateOnLaunch() -> Bool {
        guard UserDefaults.standard.bool(forKey: "hasSeenOnboarding"),
              !CrowdGeometryService.hasConsent else {
            markCurrentAsSeen()
            return false
        }
        return !hasSeenCurrent
    }
}

// MARK: - Einführung

/// Hinweis nach dem Update: Platzpositionen gemeinsam verbessern – mit
/// Schalter, der Laufspur und Teilen gleich hier einschaltet.
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(RoundTrackingService.enabledKey) private var trackingEnabled = false
    @AppStorage(CrowdGeometryService.consentKey) private var sharingEnabled = false
    @AppStorage(CrowdGeometryService.askedKey) private var askedAboutSharing = false

    private var isOn: Bool { trackingEnabled && sharingEnabled }

    private struct Highlight: Identifiable {
        let id = UUID()
        let symbol: String
        let title: LocalizedStringKey
        let text: LocalizedStringKey
    }

    private let highlights: [Highlight] = [
        Highlight(symbol: "figure.walk",
                  title: "Aus deiner Runde gelernt",
                  text: "Mit eingeschalteter Laufspur erkennt GolfTrack nach der Runde, wo Abschlag und Grün jedes Lochs liegen."),
        Highlight(symbol: "person.3.fill",
                  title: "Gemeinsam genauer",
                  text: "Teilst du diese Punkte, werden sie mit denen anderer Spieler abgeglichen. Sobald fünf übereinstimmen, gilt die Position für alle auf dem Platz."),
        Highlight(symbol: "flag.fill",
                  title: "Entfernungen, die stimmen",
                  text: "Korrigierte Positionen kommen von selbst in deine App – auch auf Plätzen, die du zum ersten Mal spielst."),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        ForEach(highlights) { highlight in
                            row(highlight)
                        }

                        privacyNote
                    }
                    .padding(20)
                    .padding(.bottom, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        Haptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSec)
                }
            }
            .safeAreaInset(edge: .bottom) { actionBar }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Bausteine

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Neu in GolfTrack")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.gold)
            Text("Richtige Entfernungen für alle")
                .font(.title.bold())
                .foregroundStyle(AppTheme.text)
            Text("Auf vielen Plätzen stimmen Abschlag- und Grünpositionen noch nicht genau. Mit deinen Runden kannst du das für alle Spieler korrigieren.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func row(_ highlight: Highlight) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.gold.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: highlight.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.gold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(highlight.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Text(highlight.text)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSec)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hand.raised.fill")
                .font(.footnote)
                .foregroundStyle(AppTheme.gold)
            Text("Gesendet werden nur die Punkte je Loch – keine Laufspur, kein Name, keine Geräte-ID. Weil nichts auf dich verweist, lassen sich gesendete Punkte nicht mehr löschen. Die Laufspur selbst bleibt auf deinem iPhone. Beides kannst du jederzeit unter Einstellungen › Positions-Tracking ändern.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(AppTheme.cardDark, in: RoundedRectangle(cornerRadius: 14))
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            if isOn {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.green)
                    Text("Eingeschaltet – deine nächste Runde hilft mit.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            } else {
                Button {
                    Haptics.success()
                    trackingEnabled = true
                    sharingEnabled = true
                    askedAboutSharing = true
                } label: {
                    Text(trackingEnabled ? "Teilen einschalten" : "Laufspur und Teilen einschalten")
                        .goldButton()
                }
                .buttonStyle(.plain)
            }

            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Text(isOn ? "Weiter" : "Später entscheiden")
                    .font(.subheadline.bold())
                    .foregroundStyle(isOn ? AppTheme.text : AppTheme.textSec)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isOn ? AppTheme.cardAlt : Color.clear,
                                in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.25), value: isOn)
    }
}
