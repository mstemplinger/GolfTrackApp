import SwiftUI

/// Einstieg nach dem Scannen des QR-Codes an einem Golfplatz.
///
/// Kurz gehalten: begrüßen, sagen was die Kurzfassung kann und was nicht,
/// dann zählen. Eine angefangene Runde am selben Platz wird angeboten.
struct GolfLiteStartView: View {

    let course: GolfLiteCourse

    @Environment(\.dismiss) private var dismiss
    @State private var round: GolfLiteCourse?
    @State private var resuming: SavedGolfLiteRound?
    @State private var saved: SavedGolfLiteRound?
    @State private var didStart = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    infoCard
                    if let saved, saved.courseID == course.id, saved.playedHoles > 0 {
                        resumeCard(saved)
                    }
                    startButton
                    FullAppFeaturesCard()
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(course.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $round) { entry in
                GolfLiteScoringView(course: entry, resuming: resuming)
            }
        }
        .onAppear { saved = GolfLiteStore.load() }
        .onChange(of: round) { _, newValue in
            if newValue == nil && didStart { saved = GolfLiteStore.load() }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "flag.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.gold)
                .padding(.top, 10)
            Text("Willkommen!")
                .font(.title.bold())
            Text("Ab jetzt zählen wir für dich mit – Loch für Loch.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var infoCard: some View {
        VStack(spacing: 10) {
            row(icon: "mappin.and.ellipse", text: Text(course.location))
            row(icon: "flag.2.crossed", text: Text("\(course.holes) Löcher"))
            if let par = course.totalPar {
                row(icon: "number", text: Text("Par \(par)"))
            } else {
                row(icon: "exclamationmark.circle",
                    text: Text("Für diesen Platz liegen keine Par-Werte vor – gezählt wird trotzdem."))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func row(icon: String, text: Text) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppTheme.gold)
                .frame(width: 22)
            text
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private func resumeCard(_ entry: SavedGolfLiteRound) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Angefangene Runde", systemImage: "clock.arrow.circlepath")
                .font(.headline)
            Text("Loch \(entry.currentHole + 1) · \(entry.totalStrokes) Schläge")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                resuming = entry
                didStart = true
                round = course
            } label: {
                Label("Fortsetzen", systemImage: "play.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var startButton: some View {
        Button {
            GolfLiteStore.clear()
            resuming = nil
            didStart = true
            round = course
        } label: {
            Text("Neue Runde starten").goldButton()
        }
        .buttonStyle(.plain)
    }
}
