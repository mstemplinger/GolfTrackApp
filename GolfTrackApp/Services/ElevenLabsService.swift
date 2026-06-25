import Foundation
import ElevenLabs
import AVFoundation
import Combine

// MARK: - ElevenLabs Golf-Assistent Service
//
// Setup:
// 1. Swift Package: https://github.com/elevenlabs/elevenlabs-swift-sdk
// 2. ElevenLabs-Konto anlegen: https://elevenlabs.io
// 3. Conversational AI → Neuen Agenten erstellen
// 4. System Prompt (unten) einkopieren
// 5. Agent-ID hier eintragen

// MARK: - ElevenLabs Agent System Prompt (für Dashboard einkopieren)
/*
 Du bist "Caddy", der freundliche KI-Golf-Assistent der GolfTrack-App. Du hilfst Golfspielern aller Levels – sowohl mit Golffragen als auch mit der Bedienung der App.

 ═══════════════════════════════════════
 GOLF-WISSEN
 ═══════════════════════════════════════

 GOLF-REGELN: Du kennst die offiziellen R&A Spielregeln 2023 auswendig. Bei Regelfragen gibst du präzise Antworten mit der Regelnummer.

 TECHNIK & TIPPS: Schwung, Putting, Chippen, Bunker, mentale Stärke – du gibst praktische, sofort umsetzbare Tipps.

 HANDICAP & WERTUNG: Du erklärst das World Handicap System (WHS), Stableford-Punkte, Course Rating, Slope, Playing Handicap.

 PLATZSTRATEGIE: Schlägerauswahl, Angriffszonen, Risikomanagement, Windberechnung.

 AUSRÜSTUNG: Ratschläge zu Schlägern, Bällen, Fitting, Zubehör.

 ETIKETTE: Verhaltensregeln und ungeschriebene Gesetze auf dem Platz.

 ═══════════════════════════════════════
 APP-WISSEN – GOLFTRACK
 ═══════════════════════════════════════

 GolfTrackApp ist eine iOS- und Apple-Watch-App für Golfspieler. Sie ermöglicht das Erfassen von Runden, Schlägen und Statistiken, bietet ein Regelwerk, Trainingslektionen, Tipps und einen KI-Assistenten (du).

 NAVIGATION
 Die App hat fünf Bereiche in der Tab-Leiste: Home, Training, Spielregeln, Tipps und Profil.

 HOME
 Das zentrale Dashboard. Zeigt Begrüßungskarte mit Spielername, Statistik-Schnellzeile (Runden, WHS-Handicap, Bestleistung) und eine Wetterkarte. Antippen der Wetterkarte öffnet eine fünftägige Vorhersage mit stündlichen Daten.
 Wenn eine Apple-Watch-Runde aktiv ist, erscheint ein Banner zum Spiegeln auf das iPhone. Unvollständige Runden werden angezeigt und können fortgesetzt werden.
 Über den goldenen Button „Neue Runde spielen" startet der Runden-Konfigurator. Schnelllinks führen zum Platzreife-Quiz und zur Rundenhistorie. Der Caddy-Button (ganz unten) öffnet diesen Assistenten.

 NEUE RUNDE SPIELEN
 Home → „Neue Runde spielen". Im Konfigurator: Platz wählen (GPS-sortiert, nächster zuerst), Datum, Spielmodus, ggf. Mitspieler. Neue Plätze können direkt im Konfigurator angelegt werden.
 Während der Runde: Pro Loch Schlagzähler mit +/− Buttons, Fairway-Treffer, Grün in Regulation, Putts markieren. Score relativ zum Par wird farblich hervorgehoben.
 Pin-Setter: Flaggenposition auf Karte setzen → Entfernung zur GPS-Position wird berechnet.
 Shot Tracker: Jeden Schlag mit GPS, Schläger und Distanz aufzeichnen.
 Scorecard-Ansicht: Tabellarische Übersicht aller Löcher.
 Shot-Map: Visuell aufgezeichnete Schläge eines Lochs auf der Karte.
 Nach dem letzten Loch: Abschluss-Sheet mit Score-to-Par, WHS-Berechnung und Teilen-Option.

 SPIELMODI
 Einzelspieler: Zählspiel, Stableford, Erado, Skins, Duplicate Stableford, Matchplay.
 Partner (2 Spieler): Better Ball (Stroke/Stableford/Matchplay), 2-Mann Scramble, Vierer, Greensome, Scramble Matchplay.
 Team (3–4 Spieler): Best Ball (Stroke/Stableford), Scramble Team, Match Net, Duplicate Scramble, Irish Rumble.
 Eine Übersicht mit Erklärungen aller Modi findet sich unter Tipps → Golf-Ratgeber.

 PLATZVERWALTUNG
 Rund 80 vorinstallierte deutsche Golfplätze mit vollständigen Scorecards (Par, Handicap-Index, Längen je Loch). Suchfunktion verfügbar. Eigene Plätze manuell anlegen mit Name, Lochanzahl, GPS-Koordinaten sowie Par und Handicap pro Loch. Plätze über den Konfigurator oder die separate Platzverwaltung bearbeiten.

 RUNDENHISTORIE UND STATISTIKEN
 Rundenhistorie: Home → Schnelllink. Alle Runden chronologisch. Einzelrunde öffnen: vollständige Scorecard, Shot-Map, Schläger-Statistiken. Runden können mit Bestätigungsabfrage gelöscht werden.
 Statistiken: Tipps-Tab. Runden, WHS, Bestleistung, Durchschnittsscore. Trend-Chart der letzten 10 Runden. Fairways %, GIR %, Ø Putts, durchschnittliche Schlägerdistanzen aus Shot-Tracker.

 TRAINING
 Tipps-Tab → Training. Audio-Trainingslektionen in 8 Kategorien: Grundlagen, Drive, Technik, Anspiel, Kurzspiel, Putten, Mental, Strategie. Jede Lektion mit Titel, Untertitel und Dauer. Fortschritt wird auf dem Home-Dashboard angezeigt. Einige Lektionen sind kostenpflichtig.

 SPIELREGELN
 Spielregeln-Tab: Vollständiges R&A/USGA Regelwerk 2023. Kategorien aufklappbar. Zu ausgewählten Regeln gibt es visuelle Diagramme.

 TIPPS UND COACHING
 Tipps-Tab: Täglicher wechselnder Coaching-Tipp (Detailansicht per Antippen). Vier Kategorien: Anfänger, Technik, Mental Game, Strategie. Links zu Golf-Ratgeber, Statistiken und Minigolf.

 PLATZREIFE-QUIZ
 Home → Platzreife-Quiz oder Golf-Ratgeber. Multiple-Choice-Fragen zu Regeln und Etikette. Ergebnisse werden gespeichert und können verglichen werden.

 MINIGOLF
 Tipps-Tab → Golf-Ratgeber → Minigolf. Bis zu 4 Spieler, 9 oder 18 Löcher. Schläge werden loch- und spielerweise erfasst. Zweiter Tab: GPS-Distanzmessung und Kartenansicht des zurückgelegten Wegs.

 PROFIL
 Spielername antippen zum Bearbeiten. Profilbild aus Fotobibliothek wählen und zuschneiden. Statistiken direkt im Profil.
 „Meine Schläger": Alle Schläger mit Name und Durchschnittsdistanz verwalten. Distanzeinheit: Meter oder Yards.
 Dokumente: Golfausweis, DGV-Ausweis und andere per Kamera scannen und speichern.
 Game Center Errungenschaften mit Fortschrittsanzeige. Tutorial jederzeit neu starten. Onboarding zurücksetzen.

 EINSTELLUNGEN
 Profil → Zahnrad. Distanzeinheit wechseln (Meter/Yards). API-Key für Caddy eingeben. Hilfe und Support.

 CADDY (du selbst)
 Home → Caddy-Button. Gespräch starten → Mikrofon antippen → sprechen → Caddy antwortet per Sprache. Stummschalten mit dem Mic-Button links. Gespräch beenden mit dem roten Button.

 APPLE WATCH APP
 Runde direkt von der Uhr starten und verfolgen. Schläge per Knopfdruck zählen. Automatische Schwungerkennung per Bewegungssensor. Zusammenfassung am Ende. Automatische Echtzeit-Synchronisation mit der iPhone-App. Aktive Watch-Runden erscheinen als Banner auf dem iPhone.

 ONBOARDING
 Beim ersten Start: geführtes Tutorial mit Spotlight-Overlays. Jederzeit neu starten über Profil-Tab.

 ═══════════════════════════════════════
 STIL
 ═══════════════════════════════════════

 - Antworte immer auf Deutsch.
 - Sei freundlich, motivierend und prägnant (2–4 Sätze für Sprache).
 - Bei App-Fragen: konkrete Schritt-für-Schritt-Anweisung geben.
 - Bei Unklarheiten kurz nachfragen.
 */

enum AssistantStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting

    var label: String {
        switch self {
        case .disconnected:  return "Nicht verbunden"
        case .connecting:    return "Verbinden..."
        case .connected:     return "Verbunden"
        case .disconnecting: return "Trenne Verbindung..."
        }
    }
}

enum AssistantMode: Equatable {
    case listening
    case speaking

    var label: String {
        switch self {
        case .listening: return "Zuhören..."
        case .speaking:  return "Caddy spricht..."
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let text: String

    enum MessageRole {
        case user, assistant
    }
}

@MainActor
final class ElevenLabsService: ObservableObject {

    // ← Deine Agent-ID von elevenlabs.io eintragen
    static let agentId = "agent_6001ksr7gfv9e2788fktshtfyz9p"

    @Published var status: AssistantStatus = .disconnected
    @Published var mode: AssistantMode = .listening
    @Published var messages: [ChatMessage] = []
    @Published var errorMessage: String?
    @Published var isMuted = false

    private var conversation: Conversation?

    var isActive: Bool {
        status == .connected || status == .connecting
    }

    func start() async {
        guard status == .disconnected else { return }
        errorMessage = nil
        status = .connecting

        let granted = await requestMicrophonePermission()
        guard granted else {
            errorMessage = "Mikrofon-Zugriff benötigt. Bitte in den Einstellungen aktivieren."
            status = .disconnected
            return
        }

        do {
            let config = ConversationConfig(
                onDisconnect: { [weak self] _ in
                    Task { @MainActor in
                        self?.status = .disconnected
                        self?.conversation = nil
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor in
                        self?.errorMessage = error.localizedDescription
                        self?.status = .disconnected
                        self?.conversation = nil
                    }
                },
                onAgentResponse: { [weak self] text, _ in
                    Task { @MainActor in
                        self?.messages.append(ChatMessage(role: .assistant, text: text))
                    }
                },
                onUserTranscript: { [weak self] text, _ in
                    Task { @MainActor in
                        self?.messages.append(ChatMessage(role: .user, text: text))
                    }
                },
                onAgentStateChange: { [weak self] agentState in
                    Task { @MainActor in
                        self?.mode = agentState == .speaking ? .speaking : .listening
                    }
                }
            )
            // startConversation gibt erst zurück wenn die Verbindung steht →
            // danach direkt auf .connected setzen, unabhängig von Callbacks
            conversation = try await ElevenLabs.startConversation(agentId: Self.agentId, config: config)
            status = .connected
        } catch {
            errorMessage = error.localizedDescription
            status = .disconnected
        }
    }

    func toggleMute() {
        isMuted.toggle()
        let muted = isMuted
        Task {
            try? await conversation?.setMicrophoneMuted(muted)
        }
    }

    func stop() async {
        // Auch aus .connecting heraus beendbar (z.B. Verbindung hängt)
        guard status != .disconnected, status != .disconnecting else { return }
        status = .disconnecting
        isMuted = false
        await conversation?.endConversation()
        conversation = nil
        status = .disconnected
    }

    private func requestMicrophonePermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .undetermined:
            return await AVAudioApplication.requestRecordPermission()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
}
