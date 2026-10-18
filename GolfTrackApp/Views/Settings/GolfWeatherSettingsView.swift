import SwiftUI

/// Grenzen, ab denen eine Stunde als Golf-Wetter zählt. Wirkt sofort auf
/// Startseite und Wettervorhersage (GolfWeatherService beobachtet die Werte).
struct GolfWeatherSettingsView: View {
    @AppStorage(GolfWeatherRules.maxRainKey)
    private var maxRainMm = GolfWeatherRules.default.maxRainMm
    @AppStorage(GolfWeatherRules.maxWindKey)
    private var maxWindKmh = GolfWeatherRules.default.maxWindKmh
    @AppStorage(GolfWeatherRules.minTemperatureKey)
    private var minTemperature = GolfWeatherRules.default.minTemperature
    @AppStorage(GolfWeatherRules.minWindowKey)
    private var minWindowHours = GolfWeatherRules.default.minWindowHours

    private var isDefault: Bool { GolfWeatherRules.current == .default }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            List {
                Section {
                    sliderRow(icon: "drop.fill", title: "Regen pro Stunde",
                              value: rainText, binding: $maxRainMm, range: 0...2, step: 0.1)
                    sliderRow(icon: "wind", title: "Wind",
                              value: "\(Int(maxWindKmh)) km/h", binding: $maxWindKmh, range: 10...60, step: 5)
                    sliderRow(icon: "thermometer.medium", title: "Mindesttemperatur",
                              value: "\(Int(minTemperature))°C", binding: $minTemperature, range: -5...20, step: 1)
                } header: {
                    Text("Spielbare Stunde")
                } footer: {
                    Text("Eine Stunde zählt als Golf-Wetter, wenn höchstens so viel Regen fällt, der Wind nicht stärker ist und es mindestens so warm ist. Nebel, Schnee, Glätte, Gewitter und Dunkelheit zählen immer als schlecht.")
                        .font(.caption)
                }

                Section {
                    Stepper(value: $minWindowHours, in: 1...5) {
                        HStack {
                            Label("Mindestdauer", systemImage: "clock")
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                            Text("\(minWindowHours) h")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.gold)
                        }
                    }
                    .listRowBackground(AppTheme.card)
                    .onChange(of: minWindowHours) { _, _ in Haptics.selection() }
                } header: {
                    Text("Golf-Fenster")
                } footer: {
                    Text("So viele gute Stunden am Stück braucht es, damit ein Zeitraum als Golf-Fenster angezeigt wird. Neun Loch dauern etwa 2 Stunden, 18 Loch etwa 4.")
                        .font(.caption)
                }

                Section {
                    Button("Auf Standard zurücksetzen") {
                        Haptics.tap()
                        GolfWeatherRules.reset()
                    }
                    .foregroundStyle(isDefault ? AppTheme.textTer : AppTheme.gold)
                    .disabled(isDefault)
                    .listRowBackground(AppTheme.card)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Golf-Wetter")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rainText: String {
        maxRainMm < 0.05
            ? String(localized: "kein Regen")
            : "\(maxRainMm.formatted(.number.precision(.fractionLength(1)))) mm"
    }

    private func sliderRow(icon: String, title: LocalizedStringKey, value: String,
                           binding: Binding<Double>, range: ClosedRange<Double>,
                           step: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.gold)
                    .monospacedDigit()
            }
            Slider(value: binding, in: range, step: step) { editing in
                if !editing { Haptics.selection() }
            }
            .tint(AppTheme.gold)
        }
        .padding(.vertical, 4)
        .listRowBackground(AppTheme.card)
    }
}
