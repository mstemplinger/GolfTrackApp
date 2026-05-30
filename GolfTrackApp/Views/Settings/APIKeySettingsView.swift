import SwiftUI

struct APIKeySettingsView: View {
    private var api: GolfCourseAPIService = .shared
    @State private var draft = ""
    @State private var showKey = false
    @State private var isTesting = false
    @State private var testResult: TestResult?

    enum TestResult {
        case success(String)
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Group {
                            if showKey {
                                TextField("API-Key", text: $draft)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("API-Key eintragen", text: $draft)
                            }
                        }
                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(AppTheme.textSec)
                        }
                        .buttonStyle(.borderless)
                    }
                } header: {
                    Text("GolfCourseAPI Key")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kostenlos registrieren unter:")
                        Link("golfcourseapi.com/sign-in",
                             destination: URL(string: "https://www.golfcourseapi.com/sign-in")!)
                            .font(.footnote)
                        Text("Über 30.000 Golfplätze weltweit mit Loch-für-Loch Par-Werten.")
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .font(.footnote)
                }

                Section {
                    Button {
                        isTesting = true
                        testResult = nil
                        Task {
                            defer { isTesting = false }
                            do {
                                // Save first, then test with a known query
                                api.apiKey = draft.trimmingCharacters(in: .whitespaces)
                                let results = try await GolfCourseAPIService.shared.search(query: "pebble beach")
                                testResult = .success("Verbindung OK – \(results.count) Ergebnis(se) für \"pebble beach\"")
                            } catch {
                                testResult = .failure(error.localizedDescription)
                            }
                        }
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            }
                            Text("Verbindung testen")
                        }
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || isTesting)

                    if let result = testResult {
                        switch result {
                        case .success(let msg):
                            Label(msg, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.gold)
                                .font(.footnote)
                        case .failure(let msg):
                            Label(msg, systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }
                    }
                }

                if !api.apiKey.isEmpty {
                    Section {
                        Button("API-Key entfernen", role: .destructive) {
                            api.apiKey = ""
                            draft = ""
                            testResult = nil
                        }
                    }
                }
            }
            .navigationTitle("API-Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { draft = api.apiKey }
            .onChange(of: draft) { _, new in
                // Auto-save on change
                api.apiKey = new.trimmingCharacters(in: .whitespaces)
            }
        }
    }
}
