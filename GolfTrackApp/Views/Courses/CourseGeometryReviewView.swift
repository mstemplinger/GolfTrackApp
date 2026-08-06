import SwiftUI
import SwiftData
import MapKit

/// Zeigt die aus Laufspuren und Schlägen abgeleiteten Abschlag-/Grünpositionen
/// eines Platzes und lässt den Nutzer sie prüfen und übernehmen.
struct CourseGeometryReviewView: View {
    let course: Course

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    @State private var suggestions: [HoleGeometrySuggestion] = []
    @State private var appliedHoles: Set<Int> = []
    @State private var isCalculating = true

    private var usable: [HoleGeometrySuggestion] {
        suggestions.filter(\.hasUsableSuggestion)
    }

    private var highConfidenceCount: Int {
        usable.filter { $0.isPlausible && min($0.teeConfidence, $0.greenConfidence) >= 0.7 }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                if isCalculating {
                    ProgressView("Laufspuren werden ausgewertet …")
                        .tint(AppTheme.gold)
                        .foregroundStyle(AppTheme.textSec)
                } else if usable.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Loch-Positionen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Frame abgeben, damit der Ladehinweis sichtbar wird.
            await Task.yield()
            suggestions = CourseGeometryInference.suggestions(for: course)
            isCalculating = false
        }
    }

    // MARK: - Inhalt

    private var content: some View {
        List {
            Section {
                explanation
                    .listRowBackground(AppTheme.cardDark)
            }

            Section {
                ForEach(usable) { suggestion in
                    NavigationLink {
                        HoleGeometryDetailView(course: course,
                                               suggestion: suggestion,
                                               onApply: { apply([suggestion], minConfidence: 0) })
                    } label: {
                        row(for: suggestion)
                    }
                    .listRowBackground(AppTheme.card)
                }
            } header: {
                Text("\(usable.count) von \(course.numberOfHoles) Löchern ableitbar")
            } footer: {
                Text("Bereits gespeichert: \(course.holePositionCount) von \(course.numberOfHoles) Löchern.")
                    .font(.caption)
            }

            if course.holePositionCount > 0 {
                Section {
                    NavigationLink {
                        FairwayCorridorView(course: course)
                    } label: {
                        Label("Fairway-Verlauf", systemImage: "point.3.filled.connected.trianglepath.dotted")
                    }
                    .listRowBackground(AppTheme.card)
                } footer: {
                    Text("Schätzt aus den Messpunkten zwischen Abschlag und Grün, wo das Fairway ungefähr verläuft. Braucht gespeicherte Loch-Positionen.")
                        .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) { actionBar }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Wie das funktioniert")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.text)
            Text("Am Abschlag und am Grün stehst du still, dazwischen bewegst du dich. Aus dem ersten und letzten längeren Stillstand pro Loch werden Abschlag und Grün geschätzt. Getrackte Schläge und selbst gesetzte Pins zählen stärker als die Laufspur.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
            Text("Je mehr Runden auf diesem Platz aufgezeichnet sind, desto genauer wird die Schätzung. Prüfe Vorschläge mit niedriger Konfidenz auf der Karte, bevor du sie übernimmst.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
        }
        .padding(.vertical, 4)
    }

    private func row(for suggestion: HoleGeometrySuggestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text("Loch \(suggestion.holeNumber)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)

                confidenceBadge(suggestion)

                Spacer()

                if appliedHoles.contains(suggestion.holeNumber) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.gold)
                }
            }

            HStack(spacing: 12) {
                marker(label: "Abschlag", available: suggestion.tee != nil)
                marker(label: "Grün", available: suggestion.green != nil)
                if let measured = suggestion.measuredLengthMeters {
                    Text("Länge \(distanceUnit.format(measured))")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSec)
                }
            }

            if let expected = suggestion.expectedLengthMeters,
               let deviation = suggestion.lengthDeviation {
                HStack(spacing: 4) {
                    Image(systemName: suggestion.isPlausible ? "checkmark.seal" : "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(suggestion.isPlausible ? AppTheme.green : .orange)
                    Text("Scorecard: \(expected) m · Abweichung \(Int(deviation * 100)) %")
                        .font(.caption2)
                        .foregroundStyle(suggestion.isPlausible ? AppTheme.textSec : .orange)
                }
            }

            Text("Runden: \(suggestion.roundCount) · Streuung ±\(Int(max(suggestion.teeSpreadMeters, suggestion.greenSpreadMeters))) m")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(.vertical, 4)
    }

    private func confidenceBadge(_ suggestion: HoleGeometrySuggestion) -> some View {
        let label: LocalizedStringKey
        let color: Color
        switch suggestion.confidenceLevel {
        case .high:   label = "hoch";    color = AppTheme.green
        case .medium: label = "mittel";  color = AppTheme.gold
        case .low:    label = "niedrig"; color = .orange
        }
        return Text(label)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
    }

    private func marker(label: LocalizedStringKey, available: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: available ? "mappin.circle.fill" : "mappin.slash")
                .font(.caption2)
                .foregroundStyle(available ? AppTheme.gold : AppTheme.textTer)
            Text(label)
                .font(.caption2)
                .foregroundStyle(available ? AppTheme.textSec : AppTheme.textTer)
        }
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            Button {
                apply(usable, minConfidence: 0.7)
            } label: {
                Text(highConfidenceCount > 0
                     ? "Hohe Konfidenz übernehmen (\(highConfidenceCount))"
                     : "Keine Löcher mit hoher Konfidenz")
                    .goldButton()
            }
            .buttonStyle(.plain)
            .disabled(highConfidenceCount == 0)
            .opacity(highConfidenceCount == 0 ? 0.5 : 1)

            Button {
                apply(usable, minConfidence: 0.4)
            } label: {
                Text("Alle plausiblen Vorschläge übernehmen")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textTer)
            Text("Noch keine Daten zum Ableiten")
                .font(.headline)
                .foregroundStyle(AppTheme.text)
            Text("Aktiviere das Positions-Tracking in den Einstellungen und spiele eine Runde auf diesem Platz. Danach können Abschlag und Grün pro Loch geschätzt werden.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    // MARK: - Übernehmen

    private func apply(_ items: [HoleGeometrySuggestion], minConfidence: Double) {
        let applied = CourseGeometryInference.apply(items, to: course, minConfidence: minConfidence)
        guard applied > 0 else { return }
        for item in items where item.isPlausible {
            if (item.tee != nil && item.teeConfidence >= minConfidence) ||
               (item.green != nil && item.greenConfidence >= minConfidence) {
                appliedHoles.insert(item.holeNumber)
            }
        }
        try? context.save()
    }
}

// MARK: - Detailansicht eines Lochs

private struct HoleGeometryDetailView: View {
    let course: Course
    let suggestion: HoleGeometrySuggestion
    let onApply: () -> Void

    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters
    @State private var didApply = false

    /// Alle Laufspur-Punkte dieses Lochs über alle Runden – als graue Linien im Hintergrund.
    private var tracks: [[CLLocationCoordinate2D]] {
        course.rounds.compactMap { round in
            guard let track = round.track else { return nil }
            let coords = track.points(forHole: suggestion.holeNumber)
                .filter(\.isValid)
                .sorted { $0.timeOffset < $1.timeOffset }
                .map(\.coordinate)
            return coords.count > 1 ? coords : nil
        }
    }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                map
                    .frame(maxHeight: .infinity)
                infoPanel
            }
        }
        .navigationTitle("Loch \(suggestion.holeNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var map: some View {
        Map(initialPosition: .automatic) {
            ForEach(Array(tracks.enumerated()), id: \.offset) { _, coords in
                MapPolyline(coordinates: coords)
                    .stroke(AppTheme.textTer, lineWidth: 2)
            }
            if let tee = suggestion.tee, let green = suggestion.green {
                MapPolyline(coordinates: [tee, green])
                    .stroke(AppTheme.gold.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            }
            if let tee = suggestion.tee {
                Annotation(String(localized: "Abschlag"), coordinate: tee) {
                    markerCircle(system: "figure.golf", color: .blue)
                }
            }
            if let green = suggestion.green {
                Annotation(String(localized: "Grün"), coordinate: green) {
                    markerCircle(system: "flag.fill", color: .red)
                }
            }
            // Bereits gespeicherte Position zum Vergleich
            if let stored = course.flagCoordinate(forHole: suggestion.holeNumber) {
                Annotation(String(localized: "gespeichert"), coordinate: stored) {
                    Circle()
                        .stroke(AppTheme.gold, lineWidth: 2)
                        .frame(width: 16, height: 16)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
    }

    private func markerCircle(system: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
            Image(systemName: system)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
    }

    private var confidenceText: LocalizedStringKey {
        switch suggestion.confidenceLevel {
        case .high:   "Konfidenz: hoch"
        case .medium: "Konfidenz: mittel"
        case .low:    "Konfidenz: niedrig"
        }
    }

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(confidenceText)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text("Runden: \(suggestion.roundCount)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }

            if let measured = suggestion.measuredLengthMeters {
                Group {
                    if let expected = suggestion.expectedLengthMeters {
                        Text("Abgeleitete Länge: \(distanceUnit.format(measured)) · Scorecard: \(expected) m")
                    } else {
                        Text("Abgeleitete Länge: \(distanceUnit.format(measured))")
                    }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
            }

            if !suggestion.isPlausible {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Die abgeleitete Länge passt nicht zur Scorecard – hier steckt wahrscheinlich ein GPS-Ausreißer oder ein falsch zugeordnetes Loch drin.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Button {
                onApply()
                didApply = true
            } label: {
                Text(didApply ? "Übernommen" : "Für dieses Loch übernehmen")
                    .goldButton()
            }
            .buttonStyle(.plain)
            .disabled(didApply)
            .opacity(didApply ? 0.6 : 1)
        }
        .padding(16)
        .background(AppTheme.card)
    }
}
