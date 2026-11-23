import SwiftUI

struct SettingsView: View {
    @AppStorage(Haptics.enabledKey) private var hapticsEnabled = true
    @AppStorage(RoundStatsService.consentKey) private var sharesRoundStats = false
    @AppStorage(RoundStatsService.askedKey) private var askedAboutRoundStats = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                List {
                    Section {
                        NavigationLink {
                            CourseListView()
                        } label: {
                            Label("Golfplätze", systemImage: "mappin.and.ellipse")
                        }
                        .listRowBackground(AppTheme.card)
                        NavigationLink {
                            TrackingSettingsView()
                        } label: {
                            Label("Positions-Tracking", systemImage: "figure.walk")
                        }
                        .listRowBackground(AppTheme.card)
                        NavigationLink {
                            GolfWeatherSettingsView()
                        } label: {
                            Label("Golf-Wetter", systemImage: "cloud.sun.fill")
                        }
                        .listRowBackground(AppTheme.card)
                    } header: {
                        Text("Daten")
                    }

                    Section {
                        Toggle(isOn: $sharesRoundStats) {
                            Label("Anonyme Rundenstatistik teilen", systemImage: "chart.bar.xaxis")
                        }
                        .tint(AppTheme.gold)
                        .listRowBackground(AppTheme.card)
                        .onChange(of: sharesRoundStats) { _, _ in
                            Haptics.selection()
                            askedAboutRoundStats = true
                        }
                    } header: {
                        Text("Datenschutz")
                    } footer: {
                        Text("Nach einer Runde auf einem Platz aus dem Verzeichnis geht eine anonyme Zusammenfassung an golftrack.app: Tag, Tageszeit (grob), Dauer, Gruppengröße sowie Schläge je Loch – keine Namen, keine Uhrzeit, kein Standort, keine Geräte-ID. Betreiber sehen daraus nur Summen ab zehn Runden. Weil nichts auf dich verweist, lassen sich gesendete Runden nicht mehr löschen.")
                    }

                    Section {
                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptisches Feedback", systemImage: "iphone.radiowaves.left.and.right")
                        }
                        .tint(AppTheme.gold)
                        .listRowBackground(AppTheme.card)
                        .onChange(of: hapticsEnabled) { _, enabled in
                            // Beim Einschalten sofort spürbar bestätigen.
                            if enabled { Haptics.success() }
                        }
                    } header: {
                        Text("Bedienung")
                    } footer: {
                        Text("Kurze Vibrationen bei Aktionen wie Schlagzählung, Lochwechsel und Rundenabschluss.")
                    }

                    Section {
                        NavigationLink {
                            HelpView()
                        } label: {
                            Label("Hilfe & Anleitung", systemImage: "questionmark.circle.fill")
                        }
                        .listRowBackground(AppTheme.card)
                        NavigationLink {
                            PrivacyView()
                        } label: {
                            Label("Datenschutz", systemImage: "hand.raised.fill")
                        }
                        .listRowBackground(AppTheme.card)
                        NavigationLink {
                            ImprintView()
                        } label: {
                            Label("Impressum", systemImage: "doc.plaintext.fill")
                        }
                        .listRowBackground(AppTheme.card)
                    } header: {
                        Text("Hilfe & Rechtliches")
                    }

                    Section {
                        HStack {
                            Text("Version")
                                .foregroundStyle(AppTheme.textSec)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(AppTheme.textSec)
                        }
                        .listRowBackground(AppTheme.card)
                        HStack {
                            Text("Gebaut mit")
                                .foregroundStyle(AppTheme.textSec)
                            Spacer()
                            Text("SwiftUI & SwiftData")
                                .foregroundStyle(AppTheme.textSec)
                        }
                        .listRowBackground(AppTheme.card)
                    } header: {
                        Text("App-Info")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .navigationTitle("Einstellungen")
            }
        }
    }
}
