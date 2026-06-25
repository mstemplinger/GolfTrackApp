import SwiftUI

struct HelpView: View {
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            List {
                guideSection
                scoringSection
                gameModesSection
                shotTrackingSection
                statsSection
                legalSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Hilfe & Anleitung")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Sections

    private var guideSection: some View {
        Section {
            HelpRow(
                icon: "1.circle.fill", color: AppTheme.gold,
                title: "Golfplatz hinzufügen",
                content: "Gehe zu Einstellungen > Golfplätze und tippe auf '+'. Du kannst Plätze manuell anlegen oder über die Suche (API-Key erforderlich) aus über 30.000 Plätzen weltweit importieren."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "2.circle.fill", color: AppTheme.gold,
                title: "Neue Runde starten",
                content: "Tippe auf den Tab 'Neue Runde'. Wähle Platz, Datum und Spielmodus. Bei Mehrspieler-Modi kannst du direkt die Namen der Mitspieler eingeben. Dann auf 'Starten'."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "3.circle.fill", color: AppTheme.gold,
                title: "Scorecard ausfüllen",
                content: "Erfasse Schlag für Schlag deine Scores. Mit den Pfeilen navigierst du zwischen den Löchern. Wenn du fertig bist, tippe auf 'Abschließen'."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "4.circle.fill", color: AppTheme.gold,
                title: "Statistiken ansehen",
                content: "Im Tab 'Statistik' siehst du deine Entwicklung über alle Runden: Score-Verlauf, Fairway-Trefferquote, Grun in Regulierung und Putt-Durchschnitt."
            ).listRowBackground(AppTheme.card)
        } header: {
            Label("Erste Schritte", systemImage: "flag.fill")
        }
    }

    private var scoringSection: some View {
        Section {
            HelpRow(
                icon: "figure.golf", color: AppTheme.gold,
                title: "Schläge & Putts",
                content: "Stelle mit + und - die Anzahl der Schläge und Putts pro Loch ein. GolfTrack berechnet automatisch Score vs. Par, Stableford-Punkte und Matchplay-Ergebnis."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "checkmark.circle", color: AppTheme.gold,
                title: "Fairway & GIR",
                content: "Fairway Hit: Hast du den Fairway beim Abschlag getroffen? GIR (Grun in Regulierung): Hast du das Grun in Par minus 2 Schlagen erreicht?"
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "mappin.and.ellipse", color: AppTheme.gold,
                title: "Schlag-Tracking auf der Karte",
                content: "Tippe auf das Karten-Symbol in der Scorecard, um deine Schläge auf einer Karte zu tracken. Setze Abschlag und Landepunkt per Tipp oder nutze 'Standort' für deine aktuelle GPS-Position."
            ).listRowBackground(AppTheme.card)
        } header: {
            Label("Scorecard", systemImage: "doc.text.fill")
        }
    }

    private var gameModesSection: some View {
        Section {
            HelpRow(
                icon: "figure.golf", color: .orange,
                title: "Zählspiel",
                content: "Die klassische Spielform. Jeder Schlag zählt. Wer am Ende die wenigsten Schläge hat, gewinnt."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "star.circle.fill", color: .orange,
                title: "Stableford",
                content: "Punkte statt Schläge: Albatross=5, Eagle=4, Birdie=3, Par=2, Bogey=1, Double+=0. Wer die meisten Punkte sammelt, gewinnt."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "person.2.fill", color: .orange,
                title: "Matchplay",
                content: "Loch für Loch gegen einen Gegner. Wer das Loch gewinnt, führt um einen Punkt. Wer mehr Löcher vorne hat als noch zu spielen sind, gewinnt (z. B. 3&2)."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "seal.fill", color: .orange,
                title: "Skins",
                content: "Jedes Loch hat einen Skin. Wer das Loch mit dem niedrigsten Score gewinnt, erhält den Skin. Bei Gleichstand wird der Skin aufs nächste Loch übertragen (Carryover)."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "flame.fill", color: .orange,
                title: "Better Ball",
                content: "Im 2er-Team: Der bessere Score pro Loch zählt für das Team, entweder im Zählspiel oder Stableford-Modus."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "person.2.wave.2.fill", color: .orange,
                title: "2-Mann Scramble",
                content: "Beide Partner schlagen ab. Der beste Abschlag wird gewählt, beide spielen von dort weiter. Der gemeinsame Team-Score wird eingetragen."
            ).listRowBackground(AppTheme.card)
        } header: {
            Label("Spielmodi", systemImage: "gamecontroller.fill")
        }
    }

    private var shotTrackingSection: some View {
        Section {
            HelpRow(
                icon: "location.fill", color: .purple,
                title: "GPS-Standort verwenden",
                content: "Tippe auf 'Standort' im Banner, um deinen aktuellen GPS-Standort als Abschlag oder Treffpunkt zu setzen. Stelle sicher, dass der Standortzugriff in den iOS-Einstellungen für GolfTrack erlaubt ist."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "hand.tap.fill", color: .purple,
                title: "Karte antippen",
                content: "Tippe direkt auf die Karte, um Abschlag (blau) und Treffpunkt (orange) zu platzieren. GolfTrack berechnet die Distanz automatisch in Metern und Yards."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "arrow.uturn.backward", color: .purple,
                title: "Rückgängig",
                content: "Der Zurück-Button macht schrittweise rückgängig: zuerst den Treffpunkt, dann den Abschlag, dann den letzten gespeicherten Schlag."
            ).listRowBackground(AppTheme.card)
        } header: {
            Label("Schlag-Tracking", systemImage: "map.fill")
        }
    }

    private var statsSection: some View {
        Section {
            HelpRow(
                icon: "chart.line.uptrend.xyaxis", color: .teal,
                title: "Score-Verlauf",
                content: "Zeigt deinen Score vs. Par über alle abgeschlossenen Runden als Liniendiagramm. Ein fallender Wert bedeutet Verbesserung."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "percent", color: .teal,
                title: "Fairway & GIR",
                content: "Prozentualer Anteil der getroffenen Fairways und Grüns in Regulierung. Hohe GIR-Werte sind ein Zeichen für gutes Kurzspiel."
            ).listRowBackground(AppTheme.card)
            HelpRow(
                icon: "figure.golf.circle", color: .teal,
                title: "Putt-Durchschnitt",
                content: "Durchschnittliche Putt-Anzahl pro Loch über alle Runden. Der Benchmark für gute Spieler liegt bei 1,7-1,8 Putts pro Loch."
            ).listRowBackground(AppTheme.card)
        } header: {
            Label("Statistiken", systemImage: "chart.bar.fill")
        }
    }

    private var legalSection: some View {
        Section {
            NavigationLink("Datenschutz") { PrivacyView() }
                .listRowBackground(AppTheme.card)
            NavigationLink("Impressum") { ImprintView() }
                .listRowBackground(AppTheme.card)
        } header: {
            Label("Rechtliches", systemImage: "doc.plaintext")
        }
    }
}

// MARK: - Help Row

private struct HelpRow: View {
    let icon: String
    let color: Color
    let title: String
    let content: String

    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                        .frame(width: 28)
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }

                if expanded {
                    Text(content)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                        .padding(.top, 8)
                        .padding(.leading, 40)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legal Views

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    legalBlock(
                        title: "Datenschutz auf einen Blick",
                        body: "GolfTrack speichert deine Daten (Runden, Scores, Statistiken) lokal auf deinem Gerät. Es werden keine Analyse- oder Tracking-Dienste eingesetzt. Einzelne Funktionen nutzen externe Dienste (Caddy-Sprachassistent, Golfplatz-Suche, Wetter) — dabei werden nur die unten beschriebenen Daten übertragen, und nur wenn du die jeweilige Funktion aktiv verwendest."
                    )
                    legalBlock(
                        title: "Gespeicherte Daten",
                        body: "Die App speichert deine Runden, Scores, Golfplätze und Schlag-Tracking-Daten ausschließlich in der lokalen SwiftData-Datenbank auf deinem Gerät. Diese Daten verlassen dein Gerät nicht, außer durch von dir initiierte iCloud-Synchronisierung."
                    )
                    legalBlock(
                        title: "Standortzugriff",
                        body: "GolfTrack kann deinen GPS-Standort für das Schlag-Tracking auf der Karte verwenden. Der Standortzugriff erfolgt nur während der App-Nutzung und die Koordinaten werden ausschließlich lokal auf deinem Gerät gespeichert."
                    )
                    legalBlock(
                        title: "Caddy-Sprachassistent (ElevenLabs)",
                        body: "Wenn du den Caddy-Sprachassistenten nutzt, wird deine Spracheingabe zur Verarbeitung an ElevenLabs Inc. (USA) übertragen. Die Übertragung erfolgt nur, während ein Gespräch aktiv ist. Für die Verarbeitung gilt die Datenschutzerklärung von ElevenLabs (elevenlabs.io/privacy). Ohne Nutzung des Caddys werden keine Sprachdaten übertragen."
                    )
                    legalBlock(
                        title: "GolfCourse API",
                        body: "Wenn du einen API-Key für golfcourseapi.com hinterlegst, werden Suchanfragen für Golfplätze an die API übertragen. Dabei wird ausschließlich dein Suchbegriff übermittelt. Der API-Key wird lokal in den UserDefaults deines Geräts gespeichert."
                    )
                    legalBlock(
                        title: "Wetterdaten (Open-Meteo)",
                        body: "Für die Wetteranzeige werden die ungefähren Koordinaten deines Standorts bzw. des Golfplatzes an den Wetterdienst Open-Meteo (open-meteo.com) übertragen. Es werden keine weiteren personenbezogenen Daten übermittelt."
                    )
                    legalBlock(
                        title: "Deine Rechte",
                        body: "Da alle Daten lokal auf deinem Gerät gespeichert sind, hast du jederzeit die volle Kontrolle. Du kannst alle Daten durch Löschen der App vollständig entfernen."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Datenschutz")
        .navigationBarTitleDisplayMode(.large)
    }

    private func legalBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body).font(.subheadline).foregroundStyle(AppTheme.textSec)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ImprintView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                imprintBlock(
                    title: "Angaben gemäß § 5 TMG",
                    lines: [
                        "Name: Tobias Aufschläger",
                        "Adresse: Hadamarstraße 22e, 93051 Regensburg, Deutschland",
                        "E-Mail: tobi@triline.de"
                    ]
                )
                imprintBlock(
                    title: "Hinweis",
                    lines: [
                        "Diese App wird als privates, nicht-kommerzielles Projekt bereitgestellt.",
                        "Die App wird ohne Gewinnerzielungsabsicht betrieben."
                    ]
                )
                imprintBlock(
                    title: "Haftungsausschluss",
                    lines: [
                        "Alle angezeigten Scores, Statistiken und Distanzen werden automatisch berechnet und dienen nur zur Information.",
                        "Für die Richtigkeit der Daten wird keine Haftung übernommen.",
                        "GolfTrack ist kein offizielles Produkt des DGV, der EGA oder eines anderen Golfverbands."
                    ]
                )
                imprintBlock(
                    title: "Urheberrecht",
                    lines: [
                        "Das Design und der Quellcode der App sind urheberrechtlich geschützt.",
                        "Golfplatz-Daten werden über die GolfCourse API bezogen.",
                        "Der Caddy-Sprachassistent nutzt die Sprachtechnologie von ElevenLabs.",
                        "Wetterdaten werden von Open-Meteo bereitgestellt."
                    ]
                )
                imprintBlock(
                    title: "App-Version",
                    lines: [
                        "GolfTrack \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")",
                        "Gebaut mit SwiftUI & SwiftData"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("Impressum")
        .navigationBarTitleDisplayMode(.large)
    }

    private func imprintBlock(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            ForEach(lines, id: \.self) { line in
                Text("• \(line)").font(.subheadline).foregroundStyle(AppTheme.textSec)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
    }
}
