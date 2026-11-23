import SwiftUI

// MARK: - Frage beim Rundenstart

/// Einmalige Frage beim Start einer Runde an einer Anlage aus dem Verzeichnis
/// (Minigolf und schlanke Golfrunde – App und App Clip): „Ergebnis anonym an
/// die Anlage melden?“
///
/// Bewusst **keine** Voreinstellung: Ein vorab eingeschalteter Schalter wäre
/// keine wirksame Einwilligung (EuGH Planet49, § 25 TDDDG) und ein Risiko im
/// App Review (5.1.1/5.1.2). Gleich große Knöpfe, der Spieler tippt aktiv.
/// Nach der Antwort wird nie wieder gefragt; ändern lässt es sich über den
/// Schalter im Ergebnis.
struct RoundStatsStartPrompt: ViewModifier {
    /// Nur an einer Anlage aus dem Verzeichnis und bei einer frisch
    /// gestarteten (nicht fortgesetzten) Runde.
    let isEligible: Bool
    @State private var isShown = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isShown {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .bottom) {
                if isShown {
                    card
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task {
                guard isEligible, !RoundStatsService.wasAsked else { return }
                // Erst die Zählkarte ankommen lassen, dann die Frage einblenden.
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.spring(duration: 0.4)) { isShown = true }
            }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title3)
                    .foregroundStyle(AppTheme.gold)
                Text("Ergebnis anonym an die Anlage melden?")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Hilft dem Betreiber, die Bahnen zu verbessern. Gesendet werden nur Tag, Dauer und Schläge je Bahn – keine Namen, kein Standort. Ändern kannst du das jederzeit im Ergebnis.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                answerButton(Text("Nein"), consent: false, filled: false)
                answerButton(Text("Ja, gern"), consent: true, filled: true)
            }
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.gold.opacity(0.35), lineWidth: 1))
    }

    private func answerButton(_ label: Text, consent: Bool, filled: Bool) -> some View {
        Button {
            Haptics.tap()
            RoundStatsService.hasConsent = consent
            withAnimation(.easeInOut(duration: 0.25)) { isShown = false }
        } label: {
            label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(filled ? AppTheme.gold : AppTheme.cardAlt,
                            in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(filled ? Color.black.opacity(0.8) : AppTheme.text)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func roundStatsStartPrompt(isEligible: Bool) -> some View {
        modifier(RoundStatsStartPrompt(isEligible: isEligible))
    }
}

// MARK: - Schalter im Ergebnis

/// Kleiner Schalter im Ergebnis – zum Ändern der beim Start gegebenen Antwort.
struct RoundStatsConsentToggle: View {
    @AppStorage(RoundStatsService.consentKey) private var consent = false
    @AppStorage(RoundStatsService.askedKey) private var asked = false
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: $consent) {
                Text("Ergebnis anonym an die Anlage melden")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
            }
            .tint(AppTheme.gold)
            .onChange(of: consent) { _, _ in
                Haptics.selection()
                asked = true
            }

            // Zwei getrennte `Text`, kein Ternär aus Literalen – der würde zum
            // `String` und damit nicht übersetzt.
            Button {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.2)) { showDetails.toggle() }
            } label: {
                showDetails ? Text("Weniger") : Text("Was wird gesendet?")
            }
            .font(.caption.bold())
            .foregroundStyle(AppTheme.gold)

            if showDetails {
                Text("Tag, Tageszeit (grob), Dauer, Gruppengröße und Schläge je Bahn – keine Namen, keine Uhrzeit, kein Standort, keine Geräte-ID. Die Anlage sieht nur Summen ab zehn Runden. Weil nichts auf dich verweist, lässt sich eine gesendete Runde nicht mehr löschen. Mehr unter [golftrack.app/datenschutz](https://golftrack.app/datenschutz).")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .tint(AppTheme.gold)   // Farbe des Links
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
