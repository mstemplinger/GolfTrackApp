import SwiftUI

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

    @State private var course: MinigolfCourseEntry?
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
                if let course {
                    MinigolfCourseStartView(course: course)
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
            .task {
                #if DEBUG
                // Ohne echten Scan gibt es keinen Universal Link. Xcode und der
                // Simulator reichen die Testadresse als `_XCAppClipURL` durch –
                // nur so lässt sich der Ablauf hier überhaupt durchspielen.
                if course == nil,
                   let raw = ProcessInfo.processInfo.environment["_XCAppClipURL"],
                   let url = URL(string: raw) {
                    open(url)
                }
                #endif
            }
        }
    }

    private func open(_ url: URL) {
        guard let id = MinigolfDeepLink.courseID(from: url) else {
            status = .failed("Dieser Code gehört zu keiner Minigolfanlage.")
            return
        }

        // Eingebaute Anlagen kennt der Clip sofort – das ist der Normalfall
        // und funktioniert auch ohne Empfang.
        if let known = MinigolfCourses.course(id: id) {
            course = known
            status = .ready
            return
        }

        // Sonst beim Verzeichnis nachfragen: Anlagen, die über golftrack.app
        // dazugekommen sind, stecken nicht im Programm.
        status = .loading
        Task {
            if let fetched = await ClipCourseDirectory.course(id: id) {
                course = fetched
                status = .ready
            } else {
                status = .failed("Diese Anlage kennen wir noch nicht. Bitte sag an der Kasse Bescheid.")
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
                Text("Minigolf mit GolfTrack")
                    .font(.title2.bold())
                Text("Scanne den QR-Code an der Anlage, dann zählen wir für dich mit.")
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
