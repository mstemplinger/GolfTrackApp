import SwiftUI
import SwiftData
import MapKit

/// Zeigt den aus eigenen Runden abgeleiteten Fairway-Verlauf pro Loch.
struct FairwayCorridorView: View {
    let course: Course

    @Environment(\.modelContext) private var context
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    @State private var corridors: [HoleCorridor] = []
    @State private var selectedHole: Int?
    @State private var isCalculating = false
    @State private var didCalculate = false

    /// True, wenn seit der gespeicherten Berechnung Runden mit Laufspur
    /// hinzugekommen (oder weggefallen) sind.
    private var isStale: Bool {
        let tracked = course.rounds.filter { $0.track != nil }.count
        guard let stored = corridors.map(\.roundCount).max() else { return true }
        return stored != tracked
    }

    private var selected: HoleCorridor? {
        guard let selectedHole else { return corridors.first }
        return corridors.first { $0.holeNumber == selectedHole } ?? corridors.first
    }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            if isCalculating {
                ProgressView("Fairway-Verlauf wird berechnet …")
                    .tint(AppTheme.gold)
                    .foregroundStyle(AppTheme.textSec)
            } else if corridors.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .navigationTitle("Fairway-Verlauf")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await calculate() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .foregroundStyle(AppTheme.gold)
                .disabled(isCalculating)
            }
        }
        .task {
            guard corridors.isEmpty, !didCalculate else { return }
            corridors = course.fairwayCorridors
            selectedHole = corridors.first?.holeNumber
            // Neu rechnen, wenn nichts gespeichert ist ODER seit der letzten
            // Berechnung Runden dazugekommen sind – sonst zeigt die Ansicht
            // stillschweigend einen veralteten Korridor.
            if corridors.isEmpty || isStale { await calculate() }
        }
    }

    // MARK: - Inhalt

    private var content: some View {
        VStack(spacing: 0) {
            holePicker
            map
                .frame(maxHeight: .infinity)
            if let corridor = selected {
                infoPanel(corridor)
            }
        }
    }

    private var holePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(corridors) { corridor in
                    let isActive = corridor.holeNumber == (selected?.holeNumber ?? -1)
                    Button {
                        selectedHole = corridor.holeNumber
                    } label: {
                        Text("\(corridor.holeNumber)")
                            .font(.subheadline.bold())
                            .foregroundStyle(isActive ? Color(red: 0.10, green: 0.22, blue: 0.13) : AppTheme.text)
                            .frame(width: 38, height: 38)
                            .background(isActive ? AppTheme.gold : AppTheme.card, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(AppTheme.cardDark)
    }

    @ViewBuilder
    private var map: some View {
        if let corridor = selected {
            Map(initialPosition: .automatic) {
                // Korridor als Fläche
                if corridor.corridorPolygon.count >= 4 {
                    MapPolygon(coordinates: corridor.corridorPolygon)
                        .foregroundStyle(AppTheme.gold.opacity(0.22))
                        .stroke(AppTheme.gold.opacity(0.55), lineWidth: 1.5)
                }
                // Mittellinie
                if corridor.centerline.count >= 2 {
                    MapPolyline(coordinates: corridor.centerline)
                        .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                // Direkte Linie Abschlag→Grün als Referenz
                MapPolyline(coordinates: [corridor.tee, corridor.green])
                    .stroke(.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

                Annotation(String(localized: "Abschlag"), coordinate: corridor.tee) {
                    marker(symbol: "figure.golf", color: .blue)
                }
                Annotation(String(localized: "Grün"), coordinate: corridor.green) {
                    marker(symbol: "flag.fill", color: .red)
                }
            }
            .id(corridor.holeNumber)   // Kamera bei Lochwechsel neu einpassen
            .mapStyle(.hybrid(elevation: .realistic))
        }
    }

    private func marker(symbol: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 26, height: 26)
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
    }

    // MARK: - Infopanel

    private func infoPanel(_ corridor: HoleCorridor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("Loch \(corridor.holeNumber)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                reliabilityBadge(corridor.reliability)
                Spacer()
                Text("Runden: \(corridor.roundCount)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }

            HStack(spacing: 14) {
                stat(icon: "arrow.left.and.right", value: distanceUnit.format(corridor.averageWidthMeters))
                stat(icon: "ruler", value: distanceUnit.format(corridor.axisLengthMeters))
                statKey(icon: "chart.bar", key: "Abdeckung \(Int(corridor.coverage * 100)) %")
            }

            Text(reliabilityHint(corridor.reliability))
                .font(.caption2)
                .foregroundStyle(corridor.reliability == .good ? AppTheme.textSec : .orange)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(AppTheme.card)
    }

    private func stat(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppTheme.gold)
            Text(value)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSec)
        }
    }

    /// Variante für übersetzbare Beschriftungen – `stat` nimmt fertige Zahlenstrings.
    private func statKey(icon: String, key: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppTheme.gold)
            Text(key)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSec)
        }
    }

    private func reliabilityBadge(_ reliability: HoleCorridor.Reliability) -> some View {
        let label: LocalizedStringKey
        let color: Color
        switch reliability {
        case .good:     label = "belastbar";  color = AppTheme.green
        case .thin:     label = "dünn";       color = AppTheme.gold
        case .veryThin: label = "sehr dünn";  color = .orange
        }
        return Text(label)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
    }

    private func reliabilityHint(_ reliability: HoleCorridor.Reliability) -> LocalizedStringKey {
        switch reliability {
        case .good:
            "Aus mehreren Runden gerechnet. Trotzdem eine Schätzung – kein amtlicher Platzplan."
        case .thin:
            "Noch wenige Runden. Der Korridor kann daneben liegen, vor allem an Doglegs."
        case .veryThin:
            "Aus sehr wenigen Daten. Eine Laufspur ist nicht das Fairway – du läufst zu deinem Ball, über Wege und ins Rough. Betrachte das als groben Anhaltspunkt."
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textTer)
            Text("Kein Fairway-Verlauf ableitbar")
                .font(.headline)
                .foregroundStyle(AppTheme.text)
            Text("Dafür braucht es pro Loch Abschlag- und Grünposition sowie Messpunkte dazwischen – aus Laufspuren oder getrackten Schlägen. Par-3-Löcher werden übersprungen, dort gibt es kein Fairway.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    // MARK: - Berechnung

    private func calculate() async {
        isCalculating = true
        // Einen Frame abgeben, sonst rendert der Spinner nie – die Berechnung
        // läuft bewusst auf dem MainActor, weil sie SwiftData-Objekte liest.
        await Task.yield()
        let result = FairwayCorridorInference.corridors(for: course)
        corridors = result
        course.setFairwayCorridors(result)
        try? context.save()
        if selectedHole == nil { selectedHole = result.first?.holeNumber }
        didCalculate = true
        isCalculating = false
    }
}
