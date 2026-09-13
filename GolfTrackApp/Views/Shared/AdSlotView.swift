import CoreLocation
import SwiftUI

/// Die Werbefläche in der Zählkarte – bei Minigolf wie bei Golf.
///
/// Drei Fälle, in dieser Reihenfolge:
/// 1. Wer ein Abo hat, sieht hier nichts – die Fläche verschwindet ganz.
///    Die **Hinweise der Anlage** bleiben davon unberührt; die stehen
///    außerhalb dieser Ansicht und sind keine Werbung.
/// 2. Gibt es eine gebuchte Anzeige für diesen Platz, für seinen Umkreis oder
///    allgemein, steht sie hier – sichtbar als „Anzeige" gekennzeichnet.
/// 3. Sonst bewirbt sich die App selbst: Abo, Caddy oder der Hinweis für
///    Betreiber, dass dieser Platz buchbar ist.
///
/// Die Anzeige wechselt mit dem Loch – so bekommt jeder Werbepartner im Lauf
/// einer Runde seine Einblendungen, statt dass die erste Anzeige 18 Löcher
/// lang klebt.
struct AdSlotView: View {

    /// Wo in der App die Fläche steht – Minigolf- oder Golf-Zählkarte.
    let placement: AdPlacement
    /// Kennung des Platzes – `nil` bei einer Runde ohne hinterlegten Platz.
    let courseID: String?
    /// Wo der Platz liegt, für Umkreis-Werbung. Wird nichts übergeben,
    /// schlägt die Ansicht selbst im Katalog nach – die geteilten Zählkarten
    /// können das nicht, weil `CourseCatalogService` nicht im App Clip steckt.
    var coordinate: CLLocationCoordinate2D? = nil
    /// Schaltet die Anzeige weiter; in der Zählkarte die Lochnummer.
    let rotation: Int

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.openURL) private var openURL

    private let catalog = AdCatalogService.shared

    @State private var promoSheet: HousePromo?

    /// Übergebene Koordinate, sonst die aus dem Katalog.
    private var effectiveCoordinate: CLLocationCoordinate2D? {
        if let coordinate { return coordinate }
        guard let courseID else { return nil }
        let courses = CourseCatalogService.shared
        if let entry = courses.minigolfCourse(id: courseID) { return entry.coordinate }
        if let entry = courses.allGolfCourses.first(where: { $0.slug == courseID }) {
            return CLLocationCoordinate2D(latitude: entry.lat, longitude: entry.lon)
        }
        return nil
    }

    private var bookedAd: RemoteAd? {
        catalog.ad(placement: placement,
                   courseID: courseID,
                   coordinate: effectiveCoordinate,
                   rotation: rotation)
    }

    private var housePromo: HousePromo? {
        let available = HousePromo.available(
            hasTraining: subscriptionManager.isTrainingSubscribed,
            hasCaddy: subscriptionManager.isCaddySubscribed
        )
        guard !available.isEmpty else { return nil }
        return available[abs(rotation) % available.count]
    }

    var body: some View {
        if !AppClipEnvironment.isRunningAsAppClip && subscriptionManager.showsAds {
            content
                // Der Slot holt seine Anzeigen selbst. Vorher tat das nur die
                // Minigolf-Seite – wer ausschließlich Golf spielt, bekam nie
                // einen Feed und sah dauerhaft nur die Eigenwerbung.
                .task { await catalog.refreshIfNeeded() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let ad = bookedAd {
            let banner = slot(
                badge: "Anzeige",
                title: Text(verbatim: ad.title),
                // Ohne zweite Zeile rückt der Auftraggeber nach – ganz ohne
                // Absender soll keine Anzeige dastehen.
                subtitle: Text(verbatim: ad.subtitle.isEmpty ? ad.advertiser : ad.subtitle),
                imageURL: ad.image,
                symbol: "megaphone.fill",
                tappable: ad.link != nil
            )
            Group {
                // Ohne Ziel bleibt es eine reine Einblendung – ein Button, der
                // nichts tut (oder ausgegraut wirkt), wäre schlechter.
                if let link = ad.link {
                    Button {
                        Haptics.tap()
                        catalog.countClick(ad)
                        openURL(link)
                    } label: {
                        banner
                    }
                    .buttonStyle(.plain)
                } else {
                    banner
                }
            }
            .task(id: "\(ad.id)-\(rotation)") { catalog.countImpression(ad) }
        } else if let promo = housePromo {
            Button {
                Haptics.tap()
                switch promo.destination {
                case .sheet:               promoSheet = promo
                case .link(let url):       openURL(url)
                }
            } label: {
                slot(
                    badge: "GolfTrack",
                    title: Text(promo.title),
                    subtitle: Text(promo.subtitle),
                    imageURL: nil,
                    symbol: promo.symbol,
                    tappable: true
                )
            }
            .buttonStyle(.plain)
            .sheet(item: $promoSheet) { promo in
                switch promo {
                case .training:  TrainingPaywallView()
                case .caddy:     CaddyPaywallView()
                case .advertise: EmptyView()
                }
            }
        }
    }

    // MARK: – Aufbau

    private func slot(badge: LocalizedStringKey,
                      title: Text,
                      subtitle: Text,
                      imageURL: URL?,
                      symbol: String,
                      tappable: Bool) -> some View {
        HStack(spacing: 12) {
            thumbnail(imageURL: imageURL, symbol: symbol)

            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                subtitle
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if tappable {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textTer)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topTrailing) {
            Text(badge)
                .font(.system(size: 8, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(AppTheme.textTer)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .contentShape(Rectangle())
    }

    private func thumbnail(imageURL: URL?, symbol: String) -> some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    symbolTile(symbol)
                }
            } else {
                symbolTile(symbol)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func symbolTile(_ symbol: String) -> some View {
        ZStack {
            AppTheme.cardAlt
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.gold)
        }
    }
}

// MARK: – Eigenwerbung

/// Was die App zeigt, solange der Platz nicht verkauft ist. Die Reihenfolge
/// ist die Rangfolge: erst das, was Geld bringt, dann der Hinweis für
/// Anlagenbetreiber – der wiederum sorgt dafür, dass der Platz verkauft wird.
enum HousePromo: String, Identifiable, CaseIterable {
    case training
    case caddy
    case advertise

    var id: String { rawValue }

    enum Destination {
        case sheet
        case link(URL)
    }

    var title: LocalizedStringKey {
        switch self {
        case .training:  return "Besser putten lernen"
        case .caddy:     return "Caddy fragen"
        case .advertise: return "Hier könnte Ihre Anlage stehen"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .training:  return "Audio-Trainings für Technik und Kopf"
        case .caddy:     return "Der Assistent für Schlagwahl und Taktik"
        case .advertise: return "Werbeplatz für Betreiber – golftrack.app"
        }
    }

    var symbol: String {
        switch self {
        case .training:  return "headphones"
        case .caddy:     return "waveform.circle.fill"
        case .advertise: return "megaphone.fill"
        }
    }

    var destination: Destination {
        switch self {
        case .training, .caddy:
            return .sheet
        case .advertise:
            return .link(URL(string: "https://golftrack.app/werbung")!)
        }
    }

    /// Nur bewerben, was noch fehlt – wer Training hat, braucht den Hinweis nicht.
    static func available(hasTraining: Bool, hasCaddy: Bool) -> [HousePromo] {
        allCases.filter { promo in
            switch promo {
            case .training:  return !hasTraining
            case .caddy:     return !hasCaddy
            case .advertise: return true
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AdSlotView(placement: .minigolfScoring, courseID: "sankt-englmar", rotation: 0)
        AdSlotView(placement: .golfScoring, courseID: nil, rotation: 1)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .appBackground()
    .environmentObject(SubscriptionManager())
    .preferredColorScheme(.dark)
}
