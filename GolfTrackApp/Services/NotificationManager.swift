import UserNotifications
import SwiftUI

extension Notification.Name {
    /// Eine Mitteilung mit hinterlegtem Platz wurde angetippt.
    static let openCourseFromNotification = Notification.Name("openCourseFromNotification")
}

@MainActor
final class NotificationManager: NSObject {

    static let shared = NotificationManager()
    private override init() { super.init() }

    /// Muss früh im Start gesetzt werden, sonst gehen Antippen-Ereignisse
    /// verloren, die die App überhaupt erst gestartet haben.
    func becomeDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    // MARK: - Inactivity Reminder

    /// Schedules a "you haven't played in X days" notification.
    /// Respects the user's settings stored in UserDefaults / @AppStorage.
    func scheduleInactivityReminder(afterDays overrideDays: Int? = nil) {
        guard UserDefaults.standard.object(forKey: "notif.inactivity.enabled") as? Bool != false else {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [NotificationID.inactivity])
            return
        }

        let storedDays = UserDefaults.standard.integer(forKey: "notif.inactivity.days")
        let days = overrideDays ?? (storedDays > 0 ? storedDays : 5)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.inactivity])

        let content = UNMutableNotificationContent()
        content.title = "Zeit für eine Runde Golf ⛳"
        content.body = "Du hast seit \(days) Tagen nicht gespielt. Raus auf den Platz!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("notification.caf"))

        let fireDate = Calendar.current.date(byAdding: .day, value: days, to: .now)!
        let dc = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(year: dc.year, month: dc.month, day: dc.day, hour: 9),
            repeats: false
        )
        center.add(UNNotificationRequest(identifier: NotificationID.inactivity, content: content, trigger: trigger))
    }

    // MARK: - Open Round Reminder

    /// Schedules a reminder for an unfinished round (next morning at 8:00).
    func scheduleOpenRoundReminder(courseName: String) {
        guard UserDefaults.standard.object(forKey: "notif.openRound.enabled") as? Bool != false else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.openRound])

        let content = UNMutableNotificationContent()
        content.title = "Offene Runde wartet"
        content.body = "Deine Runde auf \(courseName) ist noch nicht abgeschlossen."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("notification.caf"))

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        let dc = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(year: dc.year, month: dc.month, day: dc.day, hour: 8),
            repeats: false
        )
        center.add(UNNotificationRequest(identifier: NotificationID.openRound, content: content, trigger: trigger))
    }

    func cancelOpenRoundReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [NotificationID.openRound])
    }

    // MARK: - Round Inactivity (during active play)

    /// Call this every time a hole score changes.
    /// Fires a notification after `minutes` of silence – unless the user has an Apple Watch active.
    func rescheduleRoundInactivityReminder(holeName: String, afterMinutes minutes: Int = 45, watchIsActive: Bool) {
        guard UserDefaults.standard.object(forKey: "notif.roundInactivity.enabled") as? Bool != false else { return }
        guard !watchIsActive else {
            // Watch is tracking – no need for a push reminder
            cancelRoundInactivityReminder()
            return
        }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.roundInactivity])

        let content = UNMutableNotificationContent()
        content.title = "Noch auf dem Platz? ⛳"
        content.body = "Du hast seit \(minutes) Minuten kein Ergebnis eingetragen. Vergiss nicht deine Schläge!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("notification.caf"))

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )
        center.add(UNNotificationRequest(
            identifier: NotificationID.roundInactivity,
            content: content,
            trigger: trigger
        ))
    }

    func cancelRoundInactivityReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [NotificationID.roundInactivity])
    }

    // MARK: - IDs

    fileprivate enum NotificationID {
        static let inactivity        = "de.golftrack.inactivity"
        static let openRound         = "de.golftrack.openRound"
        static let roundInactivity   = "de.golftrack.roundInactivity"
    }
}


// MARK: - Antippen

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Auch im Vordergrund anzeigen – wer gerade in der App ist und den Platz
    /// betritt, soll den Hinweis sehen statt gar nichts.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        guard let raw = info[NotificationPayload.deepLinkKey] as? String,
              let url = URL(string: raw) else { return }
        await MainActor.run {
            NotificationCenter.default.post(name: .openCourseFromNotification, object: url)
        }
    }
}
