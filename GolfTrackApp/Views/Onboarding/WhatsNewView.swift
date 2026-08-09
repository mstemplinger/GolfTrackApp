import SwiftUI

// MARK: - Anzeige-Steuerung

/// Entscheidet, ob die Update-Einführung gezeigt wird.
enum WhatsNew {

    /// Kennung dieser Neuerung – bewusst **nicht** die App-Version, sonst
    /// erscheint die Einführung nach jedem Bugfix-Release erneut.
    static let releaseKey = "positions-tracking-1"
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
    /// und sie durchlaufen bereits das reguläre Onboarding. Deshalb wird die
    /// Neuerung dort sofort als gesehen markiert.
    static func evaluateOnLaunch() -> Bool {
        guard UserDefaults.standard.bool(forKey: "hasSeenOnboarding") else {
            markCurrentAsSeen()
            return false
        }
        return !hasSeenCurrent
    }
}

// MARK: - Einführung

/// Kurze Vorstellung des Positions-Trackings nach dem Update.
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(RoundTrackingService.enabledKey) private var trackingEnabled = false
    @State private var didEnable = false

    private struct Highlight: Identifiable {
        let id = UUID()
        let symbol: String
        let title: LocalizedStringKey
        let text: LocalizedStringKey
    }

    private let highlights: [Highlight] = [
        Highlight(symbol: "figure.walk",
                  title: "Deine Laufspur",
                  text: "Wenn du es erlaubst, merkt sich GolfTrack während der Runde alle paar Meter deine Position. Nach der Runde siehst du deinen Weg über den Platz auf der Karte."),
        Highlight(symbol: "flag.fill",
                  title: "Abschlag und Grün von allein",
                  text: "Aus deinen Runden schätzt die App, wo Abschlag und Fahne jedes Lochs liegen. Danach steht die Entfernung zur Fahne da, ohne dass du den Pin selbst setzen musst."),
        Highlight(symbol: "point.3.filled.connected.trianglepath.dotted",
                  title: "Fairway-Verlauf",
                  text: "Nach ein paar Runden zeichnet die App, wo das Fairway ungefähr verläuft – Doglegs inklusive. Je mehr Runden, desto genauer."),
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
                    Button("Fertig") { dismiss() }
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
            Text("Dein Weg über den Platz")
                .font(.title.bold())
                .foregroundStyle(AppTheme.text)
            Text("GolfTrack kann jetzt aufzeichnen, wo du auf dem Platz unterwegs warst – und daraus lernen, wie die Löcher liegen.")
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
            Text("Die Aufzeichnung ist standardmäßig aus und läuft nur während einer Runde. Die Daten bleiben auf deinem iPhone und werden nicht übertragen. Du kannst das Tracking jederzeit in den Einstellungen abschalten und die Aufzeichnungen dort löschen.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(AppTheme.cardDark, in: RoundedRectangle(cornerRadius: 14))
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            if didEnable {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.green)
                    Text("Aufzeichnung aktiviert – sie startet mit deiner nächsten Runde.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            } else {
                Button {
                    trackingEnabled = true
                    didEnable = true
                } label: {
                    Text("Aufzeichnung einschalten")
                        .goldButton()
                }
                .buttonStyle(.plain)
            }

            Button {
                dismiss()
            } label: {
                Text(didEnable ? "Weiter" : "Später entscheiden")
                    .font(.subheadline.bold())
                    .foregroundStyle(didEnable ? AppTheme.text : AppTheme.textSec)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(didEnable ? AppTheme.cardAlt : Color.clear,
                                in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.25), value: didEnable)
    }
}
