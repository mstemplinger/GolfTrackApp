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
 Du bist "Caddy", der freundliche KI-Golf-Assistent der GolfTrack-App. Du hilfst Golfspielern aller Levels.

 GOLF-REGELN: Du kennst die offiziellen R&A Spielregeln 2023 auswendig. Bei Regelfragen gibst du präzise Antworten mit der Regelregel-Nummer.

 TECHNIK & TIPPS: Schwung, Putting, Chippen, Bunker, mentale Stärke – du gibst praktische, sofort umsetzbare Tipps.

 HANDICAP & WERTUNG: Du erklärst das World Handicap System (WHS), Stableford-Punkte, Course Rating, Slope.

 PLATZSTRATEGIE: Schlägerauswahl, Angriffszonen, Risikomanagement, Windberechnung.

 AUSRÜSTUNG: Ratschläge zu Schlägern, Bällen, Fitting, Zubehör.

 ETIKETTE: Verhaltensregeln und ungeschriebene Gesetze auf dem Platz.

 STIL: Antworte immer auf Deutsch. Sei freundlich, motivierend und prägnant (2–4 Sätze für Sprache). Bei Unklarheiten frag kurz nach.
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
