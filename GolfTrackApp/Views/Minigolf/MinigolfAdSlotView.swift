import SwiftUI

/// Die freie Fläche unter den Spielernamen in der Minigolfkarte.
///
/// Drei Fälle, in dieser Reihenfolge:
/// 1. Wer ein Abo hat, sieht hier nichts – die Fläche verschwindet ganz.
/// 2. Gibt es eine gebuchte Anzeige für diese Anlage (oder allgemein), steht
///    sie hier, sichtbar als „Anzeige" gekennzeichnet.
/// 3. Sonst bewirbt sich die App selbst: Abo, Caddy oder der Hinweis für
///    Anlagenbetreiber, dass dieser Platz buchbar ist.
///
/// Die Anzeige wechselt mit der Bahn – so bekommt jeder Werbepartner im Lauf
/// einer Runde seine Einblendungen, statt dass die erste Anzeige 18 Bahnen
/// lang klebt.
struct MinigolfAdSlotView: View {

    /// Kennung der Anlage, auf der gespielt wird – `nil` bei einer Runde ohne
    /// hinterlegte Anlage.
    let courseID: String?
    /// Schaltet die Anzeige weiter; in der Scorecard die Bahnnummer.
    let rotation: Int

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.openURL) private var openURL

    private let catalog = AdCatalogService.shared

    @State private var promoSheet: HousePromo?

    private var bookedAd: RemoteAd? {
        catalog.ad(placement: .minigolfScoring, courseID: courseID, rotation: rotation)
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
        if subscriptionManager.showsAds {
            content
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
        MinigolfAdSlotView(courseID: "sankt-englmar", rotation: 0)
        MinigolfAdSlotView(courseID: nil, rotation: 1)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .appBackground()
    .environmentObject(SubscriptionManager())
    .preferredColorScheme(.dark)
}
