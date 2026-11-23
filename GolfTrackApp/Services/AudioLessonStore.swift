import Foundation
import Network
import Combine
import SwiftUI

/// Hält die Audio-Lektionen auf dem Gerät.
///
/// Nur Lektion 01 (gratis) liegt im App-Paket. Die übrigen 16 lädt die App
/// nach der Installation von golftrack.app nach. So bleibt der Download im
/// App Store klein, was auf Golfplätzen im Funkloch zählt.
///
/// - Geladene Dateien liegen in Application Support, nicht in Caches: iOS
///   räumt Caches bei Platzmangel leer, und dann fehlte die Lektion genau
///   dort, wo man kein Netz hat. Sie sind vom Backup ausgenommen, weil sie
///   jederzeit neu geladen werden können.
/// - Automatisch lädt die App nur, wenn Netz da ist, und nie im
///   Datensparmodus. Ohne Pro nur über WLAN, weil die Lektionen dann noch
///   gesperrt sind.
/// - Tippt jemand eine fehlende Lektion an, wird sie sofort geladen, über
///   jedes Netz.
///
/// Quelldateien und Umwandlung: `tools/audio-lessons/build.sh`.
@MainActor
final class AudioLessonStore: ObservableObject {
    static let shared = AudioLessonStore()

    /// Muss zu `VERSION` in `tools/audio-lessons/build.sh` passen. Eine neue
    /// Version lädt alle Lektionen neu und löscht die alten Dateien.
    static let remoteVersion = "v1"
    static let fileExtension = "m4a"
    static let baseURL = URL(string: "https://golftrack.app/audio/lessons/\(remoteVersion)/")!

    enum Availability: Equatable {
        case ready
        case loading(Double)
        case missing
        case failed
    }

    /// Fortschritt laufender Downloads, 0…1, je Dateiname.
    @Published private(set) var progress: [String: Double] = [:]
    @Published private(set) var failed: Set<String> = []
    @Published private(set) var isOnline = true
    /// Ändert sich, sobald eine Datei fertig ist – damit Ansichten neu zeichnen.
    @Published private(set) var completedCount = 0

    private var tasks: [String: Task<URL?, Never>] = [:]
    private var fillTask: Task<Void, Never>?
    private var lastFillAllowsExpensive = false
    private let monitor = NWPathMonitor()
    private let directory: URL

    private lazy var fillSession: URLSession = Self.makeSession(discretionary: true, allowExpensive: false)
    private lazy var fillSessionExpensive: URLSession = Self.makeSession(discretionary: true, allowExpensive: true)
    private lazy var directSession: URLSession = Self.makeSession(discretionary: false, allowExpensive: true)

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let root = support.appendingPathComponent("AudioLessons", isDirectory: true)
        directory = root.appendingPathComponent(Self.remoteVersion, isDirectory: true)
        Self.prepare(root: root, current: directory)

        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.networkChanged(online: online) }
        }
        monitor.start(queue: DispatchQueue(label: "AudioLessonStore.network"))
    }

    // MARK: Abfragen

    /// Alle Lektionen, die eine Audiodatei haben.
    private var allFiles: [String] { allLessons.compactMap(\.audioFile) }

    /// Abspielbare Datei: erst im App-Paket, dann unter den geladenen.
    func localURL(for file: String) -> URL? {
        if let bundled = Bundle.main.url(forResource: file, withExtension: Self.fileExtension) {
            return bundled
        }
        let url = fileURL(for: file)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func availability(of file: String) -> Availability {
        if let p = progress[file] { return .loading(p) }
        if localURL(for: file) != nil { return .ready }
        return failed.contains(file) ? .failed : .missing
    }

    var missingCount: Int { allFiles.filter { localURL(for: $0) == nil }.count }

    // MARK: Laden

    /// Lädt alle fehlenden Lektionen nacheinander. Bricht beim ersten Fehler
    /// ab (kein Netz, Server weg) – der nächste Anlauf kommt, wenn die App
    /// wieder nach vorn kommt oder das Netz zurück ist.
    func fillInBackground(allowExpensive: Bool) {
        lastFillAllowsExpensive = allowExpensive
        guard fillTask == nil, isOnline else { return }
        let missing = allFiles.filter { localURL(for: $0) == nil }
        guard !missing.isEmpty else { return }
        let session = allowExpensive ? fillSessionExpensive : fillSession
        fillTask = Task { [weak self] in
            for file in missing {
                guard let self, !Task.isCancelled else { break }
                if await self.download(file, using: session) == nil { break }
            }
            self?.fillTask = nil
        }
    }

    /// Lädt eine Lektion sofort, über jedes Netz. Gibt die lokale Datei zurück
    /// oder `nil`, wenn es nicht geklappt hat.
    @discardableResult
    func load(_ file: String) async -> URL? {
        await download(file, using: directSession)
    }

    private func download(_ file: String, using session: URLSession) async -> URL? {
        if let local = localURL(for: file) { return local }
        if let running = tasks[file] { return await running.value }

        failed.remove(file)
        progress[file] = 0
        let source = Self.baseURL.appendingPathComponent("\(file).\(Self.fileExtension)")
        let target = fileURL(for: file)
        let task = Task<URL?, Never> {
            await Self.fetch(source, to: target, session: session) { [weak self] fraction in
                Task { @MainActor in
                    guard let self, self.progress[file] != nil else { return }
                    self.progress[file] = fraction
                }
            }
        }
        tasks[file] = task
        let result = await task.value
        tasks[file] = nil
        progress[file] = nil
        if result == nil {
            failed.insert(file)
        } else {
            completedCount += 1
        }
        return result
    }

    private func networkChanged(online: Bool) {
        let cameBack = online && !isOnline
        isOnline = online
        if cameBack {
            failed.removeAll()
            fillInBackground(allowExpensive: lastFillAllowsExpensive)
        }
    }

    // MARK: Dateien

    private func fileURL(for file: String) -> URL {
        directory.appendingPathComponent("\(file).\(Self.fileExtension)")
    }

    /// Legt den Ordner an, nimmt ihn vom Backup aus und räumt Dateien älterer
    /// Versionen weg.
    private static func prepare(root: URL, current: URL) {
        let fm = FileManager.default
        try? fm.createDirectory(at: current, withIntermediateDirectories: true)
        var rootURL = root
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? rootURL.setResourceValues(values)
        let versions = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        for old in versions where old.lastPathComponent != current.lastPathComponent {
            try? fm.removeItem(at: old)
        }
    }

    private static func makeSession(discretionary: Bool, allowExpensive: Bool) -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 10 * 60
        config.allowsExpensiveNetworkAccess = allowExpensive
        // Datensparmodus: automatisch nichts, auf ausdrücklichen Wunsch schon.
        config.allowsConstrainedNetworkAccess = !discretionary
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }

    /// Lädt eine Datei und legt sie erst nach vollständigem, gültigem Empfang
    /// an ihren Platz – eine halbe Datei soll nie als „geladen" gelten.
    nonisolated private static func fetch(
        _ source: URL,
        to target: URL,
        session: URLSession,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async -> URL? {
        await withCheckedContinuation { (continuation: CheckedContinuation<URL?, Never>) in
            let observation = Box<NSKeyValueObservation>()
            let task = session.downloadTask(with: source) { temp, response, error in
                observation.value?.invalidate()
                guard error == nil,
                      let temp,
                      let http = response as? HTTPURLResponse,
                      http.statusCode == 200,
                      let size = try? FileManager.default.attributesOfItem(atPath: temp.path)[.size] as? Int,
                      size > 10_000 else {
                    continuation.resume(returning: nil)
                    return
                }
                do {
                    let fm = FileManager.default
                    if fm.fileExists(atPath: target.path) { try fm.removeItem(at: target) }
                    try fm.moveItem(at: temp, to: target)
                    continuation.resume(returning: target)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
            observation.value = task.progress.observe(\.fractionCompleted) { progress, _ in
                onProgress(progress.fractionCompleted)
            }
            task.resume()
        }
    }
}

// MARK: - Automatisch nachladen

extension View {
    /// Startet das Nachladen der Audio-Lektionen beim Start, beim Zurückkehren
    /// in die App und sobald Pro freigeschaltet wird.
    func prefetchAudioLessons() -> some View { modifier(AudioLessonPrefetch()) }
}

private struct AudioLessonPrefetch: ViewModifier {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .task {
                // Kurz warten: Der Abo-Status steht erst nach dem ersten
                // StoreKit-Abgleich fest, und der Start soll nicht ruckeln.
                try? await Task.sleep(for: .seconds(4))
                start()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { start() }
            }
            .onChange(of: subscriptionManager.isPro) { _, _ in start() }
    }

    private func start() {
        AudioLessonStore.shared.fillInBackground(allowExpensive: subscriptionManager.isPro)
    }
}

/// Hält die KVO-Beobachtung, bis der Download fertig ist.
private final class Box<T>: @unchecked Sendable {
    var value: T?
}
