import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {

    // MARK: - Stored preferences

    @AppStorage("notif.inactivity.enabled")        private var inactivityEnabled: Bool  = true
    @AppStorage("notif.inactivity.days")           private var inactivityDays: Int      = 5
    @AppStorage("notif.openRound.enabled")         private var openRoundEnabled: Bool   = true
    @AppStorage("notif.roundInactivity.enabled")   private var roundInactivityEnabled: Bool = true
    @AppStorage("notif.roundInactivity.minutes")   private var roundInactivityMinutes: Int  = 45

    // MARK: - Runtime state

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showSystemAlert = false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if authStatus == .denied {
                        deniedBanner
                    }

                    inactivityCard
                    openRoundCard
                    RoundInactivityCard(
                        enabled: $roundInactivityEnabled,
                        minutes: $roundInactivityMinutes
                    )
                    footerNote
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Benachrichtigungen")
        .navigationBarTitleDisplayMode(.large)
        .task { await loadAuthStatus() }
        .onChange(of: inactivityEnabled) { _, _ in rescheduleInactivity() }
        .onChange(of: inactivityDays)    { _, _ in rescheduleInactivity() }
        .onChange(of: openRoundEnabled)  { _, new in
            if !new { NotificationManager.shared.cancelOpenRoundReminder() }
        }
    }

    // MARK: - Denied banner

    private var deniedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(.red)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text("Benachrichtigungen gesperrt")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Text("Bitte in den iPhone-Einstellungen aktivieren.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer()
            Button("Öffnen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption.bold())
            .foregroundStyle(AppTheme.gold)
        }
        .padding(14)
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Inactivity card

    @ViewBuilder private var inactivityCard: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 14) {
                iconBadge(systemName: "bell.badge.fill", color: AppTheme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Inaktivitätserinnerung")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Text("Erinnert dich wenn du längere Zeit nicht gespielt hast")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Toggle("", isOn: $inactivityEnabled)
                    .labelsHidden()
                    .tint(AppTheme.gold)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            if inactivityEnabled {
                Divider().padding(.leading, 62).background(AppTheme.cardAlt)

                // Days picker
                HStack(spacing: 14) {
                    iconBadge(systemName: "calendar.badge.clock", color: AppTheme.textSec)
                        .opacity(0)   // invisible spacer for alignment
                    Text("Erinnerung nach")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Picker("Tage", selection: $inactivityDays) {
                        Text("3 Tagen").tag(3)
                        Text("5 Tagen").tag(5)
                        Text("7 Tagen").tag(7)
                        Text("14 Tagen").tag(14)
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.gold)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Open round card

    @ViewBuilder private var openRoundCard: some View {
        HStack(spacing: 14) {
            iconBadge(systemName: "flag.fill", color: Color(red: 0.3, green: 0.85, blue: 0.5))
            VStack(alignment: .leading, spacing: 2) {
                Text("Offene Runde")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Text("Erinnert dich am nächsten Morgen an eine unfertige Runde")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer()
            Toggle("", isOn: $openRoundEnabled)
                .labelsHidden()
                .tint(AppTheme.gold)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Footer

    private var footerNote: some View {
        Text("Benachrichtigungen werden nur als lokale Erinnerungen verschickt – keine Werbung, keine Server.")
            .font(.caption)
            .foregroundStyle(AppTheme.textTer)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    // MARK: - Helpers

    private func iconBadge(systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(color.opacity(0.18))
                .frame(width: 40, height: 40)
            Image(systemName: systemName)
                .font(.system(size: 16))
                .foregroundStyle(color)
        }
    }

    private func loadAuthStatus() async {
        authStatus = await UNUserNotificationCenter.current()
            .notificationSettings().authorizationStatus
        if authStatus == .notDetermined {
            await NotificationManager.shared.requestAuthorization()
            authStatus = await UNUserNotificationCenter.current()
                .notificationSettings().authorizationStatus
        }
    }

    private func rescheduleInactivity() {
        guard inactivityEnabled else {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: ["de.golftrack.inactivity"])
            return
        }
        Task { await NotificationManager.shared.scheduleInactivityReminder(afterDays: inactivityDays) }
    }
}

// MARK: - Sub-view (extracted to reduce type-checker complexity)

private struct RoundInactivityCard: View {
    @Binding var enabled: Bool
    @Binding var minutes: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                iconBadge(systemName: "clock.badge.exclamationmark.fill", color: .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pause-Erinnerung")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Text("Erinnert dich während einer Runde, wenn du längere Zeit nichts eingetragen hast")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Toggle("", isOn: $enabled)
                    .labelsHidden()
                    .tint(AppTheme.gold)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            if enabled {
                Divider().padding(.leading, 62).background(AppTheme.cardAlt)

                HStack {
                    Text("Erinnerung nach")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Picker("Minuten", selection: $minutes) {
                        Text("20 Min.").tag(20)
                        Text("30 Min.").tag(30)
                        Text("45 Min.").tag(45)
                        Text("60 Min.").tag(60)
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.gold)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)

                Divider().padding(.leading, 18).background(AppTheme.cardAlt)

                HStack(spacing: 8) {
                    Image(systemName: "applewatch")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                    Text("Wird automatisch deaktiviert, wenn du eine Apple Watch zum Tracken verwendest.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func iconBadge(systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(color.opacity(0.18))
                .frame(width: 40, height: 40)
            Image(systemName: systemName)
                .font(.system(size: 16))
                .foregroundStyle(color)
        }
    }
}
