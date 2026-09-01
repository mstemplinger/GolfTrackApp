import SwiftUI
import StoreKit

/// Der App Clip: eine Minigolfrunde, ohne dass jemand etwas installieren muss.
///
/// Der Gast scannt den QR-Code an der Anlage. Ist GolfTrack installiert, fängt
/// iOS den Universal Link ab und die volle App öffnet sich. Ist sie es nicht,
/// erscheint die App-Clip-Karte und dieser Clip startet – dieselbe Begrüßung,
/// dieselbe Zählkarte.
///
/// Bewusst nicht dabei: Werbung (untersagt, Richtlinie 2.5.16(a)), der
/// Watch-Abgleich, Abos, Caddy, Golfrunden, SwiftData. Der Clip muss klein
/// bleiben – Apple begrenzt ihn auf 15 MB entpackt.
@main
struct GolfTrackClipApp: App {

    @State private var minigolfCourse: MinigolfCourseEntry?
    @State private var golfCourse: GolfLiteCourse?
    @State private var status: Status = .waiting

    enum Status: Equatable {
        case waiting
        case loading
        case failed(String)
        case ready
    }

    init() {
        configureNavigationBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let minigolfCourse {
                    MinigolfCourseStartView(course: minigolfCourse)
                } else if let golfCourse {
                    GolfLiteStartView(course: golfCourse)
                } else {
                    ClipPlaceholderView(status: status)
                }
            }
            .preferredColorScheme(.dark)
            // Der Clip wird über den Universal Link gestartet; beide Wege
            // abdecken, weil iOS je nach Startart das eine oder andere liefert.
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = activity.webpageURL { open(url) }
            }
            .onOpenURL { url in open(url) }
            // Am Ende der Runde die volle App vorschlagen – Apples eigener
            // Weg dafür. Bewusst erst dann und nicht beim Start: Wer gerade
            // erst gescannt hat, will spielen, nicht installieren.
            .onReceive(NotificationCenter.default.publisher(for: .minigolfRoundFinished)) { _ in
                recommendFullApp()
            }
            .task {
                #if DEBUG
                // Ohne echten Scan gibt es keinen Universal Link. Xcode und der
                // Simulator reichen die Testadresse als `_XCAppClipURL` durch –
                // nur so lässt sich der Ablauf hier überhaupt durchspielen.
                if minigolfCourse == nil, golfCourse == nil,
                   let raw = ProcessInfo.processInfo.environment["_XCAppClipURL"],
                   let url = URL(string: raw) {
                    open(url)
                }
                #endif
            }
        }
    }

    /// Blendet die App-Store-Karte für die volle App ein.
    ///
    /// `SKOverlay` ist im App Clip der vorgesehene Weg; ein selbstgebauter
    /// Knopf mit App-Store-Link wäre gegen die Richtlinien und würde den
    /// Zustand des Clips nicht mitnehmen. Der gespielte Stand liegt bereits
    /// in der gemeinsamen App-Gruppe und steht nach dem Installieren da.
    private func recommendFullApp() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        let config = SKOverlay.AppClipConfiguration(position: .bottom)
        SKOverlay(configuration: config).present(in: scene)
    }

    private func open(_ url: URL) {
        guard let link = CourseDeepLink.link(from: url) else {
            status = .failed("Dieser Code gehört zu keinem Platz von GolfTrack.")
            return
        }

        switch link.kind {
        case .minigolf:
            // Eingebaute Anlagen kennt der Clip sofort – das ist der Normalfall
            // und funktioniert auch ohne Empfang.
            if let known = MinigolfCourses.course(id: link.slug) {
                minigolfCourse = known
                status = .ready
                return
            }
            status = .loading
            Task {
                if let fetched = await ClipCourseDirectory.minigolfCourse(id: link.slug) {
                    minigolfCourse = fetched
                    status = .ready
                } else {
                    status = .failed("Diese Anlage kennen wir noch nicht. Bitte sag an der Kasse Bescheid.")
                }
            }

        case .golf:
            // Golfplätze stecken nie im Programm, dafür sind es zu viele.
            // Ohne Empfang geht hier nichts – das sagt die Meldung auch.
            status = .loading
            Task {
                if let fetched = await ClipCourseDirectory.golfCourse(id: link.slug) {
                    golfCourse = fetched
                    status = .ready
                } else {
                    status = .failed("Der Platz ließ sich nicht laden. Prüf die Verbindung und scanne noch einmal.")
                }
            }
        }
    }
}

/// Was zu sehen ist, solange keine Anlage feststeht.
private struct ClipPlaceholderView: View {

    let status: GolfTrackClipApp.Status

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 46))
                .foregroundStyle(AppTheme.gold)

            switch status {
            case .waiting, .ready:
                Text("Runde starten mit GolfTrack")
                    .font(.title2.bold())
                Text("Scanne den QR-Code am Platz, dann zählen wir für dich mit.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

            case .loading:
                ProgressView()
                    .tint(AppTheme.gold)
                Text("Anlage wird gesucht …")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            case .failed(let message):
                Text("Das hat nicht geklappt")
                    .font(.title3.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appBackground()
    }
}
