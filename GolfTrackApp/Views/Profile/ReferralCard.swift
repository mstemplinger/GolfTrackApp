import SwiftUI

/// „Freunde einladen“ im Profil: eigener Link zum Teilen, Fortschritt bis fünf
/// Freunde, danach der Geschenkcode für zwei Wochen Pro. Wer selbst eingeladen
/// wurde, kann hier den Code des Freundes eingeben.
struct ReferralCard: View {
    @ObservedObject private var referral = ReferralService.shared
    @State private var enteredCode = ""
    @State private var claimMessage: LocalizedStringKey?
    @State private var isClaiming = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Freunde einladen")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Text("Bei 5 Freunden gibt's 2 Wochen Pro geschenkt")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Image(systemName: "gift.fill")
                    .foregroundStyle(AppTheme.gold)
            }

            Divider().background(AppTheme.cardAlt)

            if let status = referral.status {
                progress(status)
                if let url = status.rewardUrl.flatMap(URL.init(string:)) {
                    Button {
                        Haptics.celebrate()
                        openURL(url)
                    } label: {
                        label("2 Wochen Pro einlösen", icon: "gift.fill", filled: true)
                    }
                    .buttonStyle(.plain)
                } else if status.rewardPending {
                    Text("Geschafft! Dein Geschenk ist gleich da – schau später noch einmal vorbei.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                ShareLink(
                    item: ReferralService.inviteURL(code: status.code),
                    message: Text("Ich zähle meine Golfrunden mit GolfTrack – probier's aus! Mein Einladungscode: \(status.code)")
                ) {
                    label("Einladung teilen", icon: "square.and.arrow.up", filled: status.rewardUrl == nil)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })
            } else {
                HStack(spacing: 8) {
                    if referral.isLoading { ProgressView() }
                    Text(referral.isLoading ? "Lade deinen Einladungscode …" : "Keine Verbindung – versuch es später noch einmal.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
            }

            if !referral.hasClaimed {
                codeEntry
            }
        }
        .padding(20)
        .cardStyle()
        .task { await referral.refresh() }
    }

    private func progress(_ status: ReferralService.Status) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<status.needed, id: \.self) { i in
                    Capsule()
                        .fill(i < status.friends ? AppTheme.gold : AppTheme.cardAlt)
                        .frame(height: 6)
                }
            }
            HStack {
                Text("\(min(status.friends, status.needed)) von \(status.needed) Freunden")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text("Code \(Text(verbatim: status.code).bold())")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .textSelection(.enabled)
            }
        }
    }

    private var codeEntry: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Von einem Freund eingeladen?")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSec)
            HStack(spacing: 8) {
                TextField("Code", text: $enteredCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.subheadline.monospaced())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
                    .onChange(of: enteredCode) { _, new in
                        enteredCode = String(new.uppercased().prefix(6))
                    }
                Button {
                    Haptics.tap()
                    Task { await claim() }
                } label: {
                    Text("Einlösen")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(AppTheme.text)
                }
                .buttonStyle(.plain)
                .disabled(enteredCode.count != 6 || isClaiming)
            }
            if let claimMessage {
                Text(claimMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
        }
    }

    private func claim() async {
        isClaiming = true
        defer { isClaiming = false }
        let result = await referral.claim(enteredCode)
        claimMessage = Self.message(for: result)
        if result == .counted { Haptics.success() } else { Haptics.error() }
    }

    static func message(for result: ReferralService.ClaimResult) -> LocalizedStringKey {
        switch result {
        case .counted:        "Danke! Dein Freund ist einen Schritt näher an seinem Geschenk."
        case .ownCode:        "Das ist dein eigener Code."
        case .alreadyCounted: "Dieses iPhone hat schon eine Einladung eingelöst."
        case .notFound:       "Diesen Code gibt es nicht."
        case .rateLimited:    "Zu viele Versuche – probier es morgen noch einmal."
        case .offline:        "Keine Verbindung zum Server. Prüf die Internetverbindung."
        }
    }

    private func label(_ title: LocalizedStringKey, icon: String, filled: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(filled ? AppTheme.gold : AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(filled ? Color(red: 0.10, green: 0.22, blue: 0.13) : AppTheme.text)
    }
}
