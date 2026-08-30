import SwiftUI

/// Einstieg nach dem Scannen des QR-Codes an einer Minigolfanlage:
/// kurze Begrüßung → Frage nach dem Tutorial → Spieler → Runde läuft.
///
/// Wird sowohl von der Anlagen-Liste in `MinigolfView` als auch vom
/// Deep-Link-Handler in `ContentView` präsentiert (und später vom App Clip).
struct MinigolfCourseStartView: View {

    let course: MinigolfCourseEntry

    private enum Step { case welcome, tutorialQuestion, tutorial, players }

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .welcome
    @State private var rawNames: [String] = ["", ""]
    @State private var tutorialPage = 0
    @State private var config: MinigolfConfig?
    /// Wurde die Runde schon gestartet? Dann schließt der Flow sich mit ihr.
    @State private var didStart = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    switch step {
                    case .welcome:          welcomeStep
                    case .tutorialQuestion: tutorialQuestionStep
                    case .tutorial:         tutorialStep
                    case .players:          playersStep
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.25), value: step)
            }
            .appBackground()
            .navigationTitle(course.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(AppTheme.gold)
                }
            }
            .navigationDestination(item: $config) { config in
                MinigolfScoringView(config: config)
            }
        }
        .onAppear {
            if let names = MinigolfGameStore.loadNames(), !names.isEmpty {
                rawNames = names
            }
        }
        // Runde beendet oder verlassen → gesamten Flow schließen
        .onChange(of: config) { _, newValue in
            if newValue == nil && didStart { dismiss() }
        }
    }

    // MARK: - Schritt 1: Begrüßung

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 46))
                .foregroundStyle(AppTheme.gold)
                .padding(.top, 12)

            VStack(spacing: 6) {
                Text("Willkommen!")
                    .font(.title.bold())
                Text(course.welcome)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                infoRow(icon: "mappin.and.ellipse", Text(course.location))
                infoRow(icon: "flag.fill", Text("\(course.holes) Bahnen"))
                if !course.notes.isEmpty {
                    infoRow(icon: "info.circle", Text(course.notes))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))

            Button { step = .tutorialQuestion } label: {
                Text("Los geht's").goldButton()
            }
            .buttonStyle(.plain)
        }
    }

    private func infoRow(icon: String, _ label: Text) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppTheme.gold)
                .frame(width: 22)
            label
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Schritt 2: Tutorial ja/nein

    private var tutorialQuestionStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 46))
                .foregroundStyle(AppTheme.gold)
                .padding(.top, 12)

            VStack(spacing: 6) {
                Text("Kurz erklärt?")
                    .font(.title2.bold())
                Text("Drei Sätze, wie das Zählen in der App funktioniert – oder direkt loslegen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button {
                    tutorialPage = 0
                    step = .tutorial
                } label: {
                    Label("Ja, kurz zeigen", systemImage: "sparkles")
                        .goldButton()
                }
                .buttonStyle(.plain)

                Button { step = .players } label: {
                    Label("Nein, direkt starten", systemImage: "figure.golf")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Schritt 3: Mini-Tutorial

    private struct TutorialSlide: Identifiable {
        let id = UUID()
        let icon: String
        let title: LocalizedStringKey
        let text: LocalizedStringKey
    }

    private static let tutorialSlides: [TutorialSlide] = [
        .init(icon: "plus.circle.fill",
              title: "Schläge zählen",
              text: "Jeder Spieler hat eine eigene Zeile. Nach jedem Schlag auf + tippen – verzählt? Das Minus korrigiert."),
        .init(icon: "chevron.right.circle.fill",
              title: "Bahn für Bahn",
              text: "Unten auf „Weiter“ geht es zur nächsten Bahn. Der Stand wird automatisch gesichert, auch wenn du das Handy weglegst."),
        .init(icon: "trophy.fill",
              title: "Ergebnis",
              text: "Oben rechts siehst du jederzeit die Tabelle. Nach der letzten Bahn steht der Sieger fest.")
    ]

    private var tutorialStep: some View {
        let slides = Self.tutorialSlides
        return VStack(spacing: 18) {
            TabView(selection: $tutorialPage) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    VStack(spacing: 14) {
                        Image(systemName: slide.icon)
                            .font(.system(size: 46))
                            .foregroundStyle(AppTheme.gold)
                        Text(slide.title)
                            .font(.title3.bold())
                        Text(slide.text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 20)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 280)

            Button {
                if tutorialPage < slides.count - 1 {
                    withAnimation(.easeInOut(duration: 0.2)) { tutorialPage += 1 }
                } else {
                    step = .players
                }
            } label: {
                Group {
                    if tutorialPage < slides.count - 1 {
                        Text("Weiter")
                    } else {
                        Text("Verstanden")
                    }
                }
                .goldButton()
            }
            .buttonStyle(.plain)

            Button("Überspringen") { step = .players }
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Schritt 4: Spieler

    private var playersStep: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Wer spielt mit?")
                    .font(.title2.bold())
                Text("Namen sind optional – leer lassen geht auch.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            playersCard

            Button(action: startRound) {
                Text("Runde starten · \(course.holes) Bahnen").goldButton()
            }
            .buttonStyle(.plain)
        }
    }

    private var playersCard: some View {
        VStack(spacing: 8) {
            ForEach(Array(rawNames.indices), id: \.self) { i in
                playerRow(i)
            }
            playerCountButtons
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func playerRow(_ index: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(AppTheme.gold.opacity(0.75), in: Circle())
            TextField("Spieler \(index + 1)", text: $rawNames[index])
                .font(.body)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
    }

    private var playerCountButtons: some View {
        HStack(spacing: 10) {
            if rawNames.count < 8 {
                Button {
                    withAnimation(.spring(response: 0.3)) { rawNames.append("") }
                } label: {
                    Label("Hinzufügen", systemImage: "plus")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(AppTheme.gold)
                }
                .buttonStyle(.plain)
            }
            if rawNames.count > 1 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if !rawNames.isEmpty { rawNames.removeLast() }
                    }
                } label: {
                    Label("Entfernen", systemImage: "minus")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Start

    private func startRound() {
        let names = rawNames.enumerated().map { i, name in
            name.trimmingCharacters(in: .whitespaces).isEmpty
                ? "Spieler \(i + 1)"
                : name
        }
        MinigolfGameStore.saveNames(rawNames)
        MinigolfGameStore.clear()
        didStart = true
        config = MinigolfConfig(playerNames: names,
                                numberOfHoles: course.holes,
                                courseName: course.name)
    }
}

#Preview {
    MinigolfCourseStartView(course: MinigolfCourses.all[0])
        .preferredColorScheme(.dark)
}
