import SwiftUI

struct SettingsView: View {
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
                            APIKeySettingsView()
                        } label: {
                            Label("API-Einstellungen", systemImage: "key.fill")
                        }
                        .listRowBackground(AppTheme.card)
                    } header: {
                        Text("Daten")
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
