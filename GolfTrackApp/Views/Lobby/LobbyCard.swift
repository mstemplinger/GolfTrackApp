import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins

/// „Mit Freunden spielen" beim Rundenstart: Lobby anlegen, mit Code oder
/// QR-Code beitreten, wer dabei ist, und ob man sich gegenseitig orten kann.
struct LobbyCard: View {
    @Binding var selectedCourse: Course?
    let courses: [Course]
    let playerName: String
    /// Code aus einem gescannten Universal Link – tritt beim Erscheinen bei.
    var pendingJoinCode: String?

    private let lobby = LobbyService.shared
    @Environment(\.modelContext) private var context
    @State private var enteringCode = false
    @State private var codeInput = ""
    @State private var showScanner = false
    @State private var showQRLarge = false
    @State private var trackingOnCreate = true
    @FocusState private var codeFocused: Bool

    private let darkText = Color(red: 0.06, green: 0.14, blue: 0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let state = lobby.state, lobby.isActive {
                activeContent(state)
            } else if lobby.isActive {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Lobby wird geladen …")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                }
            } else {
                idleContent
            }

            if let error = lobby.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showScanner) {
            LobbyScannerView { code in
                showScanner = false
                Task { await join(code) }
            }
        }
        .sheet(isPresented: $showQRLarge) {
            if let code = lobby.code { LobbyQRSheet(code: code) }
        }
        .onAppear {
            lobby.startPolling()
            if let code = pendingJoinCode, lobby.code != code {
                // Neuer Code gescannt, während noch eine alte Lobby offen ist: wechseln.
                Task {
                    if lobby.isActive { await lobby.leave() }
                    await join(code)
                }
            } else {
                adoptHostCourse()
            }
        }
        .onDisappear { lobby.pauseIfIdle() }
        .onChange(of: lobby.state?.courseName) { _, _ in adoptHostCourse() }
        .onChange(of: selectedCourse) { _, course in
            // Gastgeber wechselt den Platz → Gäste ziehen mit. Gäste selbst
            // springen auf den Platz der Lobby zurück.
            if lobby.isHost, let course {
                Task { await lobby.setCourse(name: course.name, slug: catalogSlug(for: course),
                                             holes: course.numberOfHoles) }
            } else {
                adoptHostCourse()
            }
        }
        .alert("Lobby beendet", isPresented: Binding(
            get: { lobby.endedNotice != nil },
            set: { if !$0 { lobby.endedNotice = nil } }
        )) {
            Button("OK", role: .cancel) { lobby.endedNotice = nil }
        } message: {
            Text(lobby.endedNotice ?? "")
        }
    }

    // MARK: Noch keine Lobby

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.gold)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.gold.opacity(0.15), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mit Freunden spielen")
                        .font(.headline)
                        .foregroundStyle(AppTheme.text)
                    Text("Jeder zählt auf seinem iPhone – ihr seht live die Schläge der anderen.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle(isOn: $trackingOnCreate) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Gegenseitig orten")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.text)
                    Text("Während der Runde seht ihr, wo die anderen gerade sind.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
            }
            .tint(AppTheme.gold)

            HStack(spacing: 8) {
                Button {
                    Haptics.medium()
                    Task {
                        await lobby.create(
                            name: playerName,
                            courseName: selectedCourse?.name ?? "",
                            courseSlug: catalogSlug(for: selectedCourse),
                            holes: selectedCourse?.numberOfHoles ?? 18,
                            tracking: trackingOnCreate)
                        if lobby.isActive { Haptics.success() }
                    }
                } label: {
                    Label("Lobby erstellen", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(darkText)
                }
                .buttonStyle(.plain)
                .disabled(lobby.isBusy)

                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { enteringCode.toggle() }
                    codeFocused = enteringCode
                } label: {
                    Label("Code", systemImage: "number")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        .background(AppTheme.gold.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(AppTheme.gold)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.tap()
                    showScanner = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        .background(AppTheme.gold.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(AppTheme.gold)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("QR-Code scannen")
            }

            if enteringCode {
                HStack(spacing: 8) {
                    TextField("5-stelliger Code", text: $codeInput)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .focused($codeFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 10))
                        .onChange(of: codeInput) { _, value in
                            let digits = String(value.filter(\.isNumber).prefix(5))
                            if digits != value { codeInput = digits }
                        }
                    Button {
                        Task { await join(codeInput) }
                    } label: {
                        Group {
                            if lobby.isBusy { ProgressView() } else { Text("Beitreten") }
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        .background(codeInput.count == 5 ? AppTheme.gold : Color.secondary.opacity(0.3),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(codeInput.count == 5 ? darkText : AppTheme.textSec)
                    }
                    .buttonStyle(.plain)
                    .disabled(codeInput.count != 5 || lobby.isBusy)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: In der Lobby

    private func activeContent(_ state: LobbyState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                Button {
                    Haptics.tap()
                    showQRLarge = true
                } label: {
                    LobbyQRCode(code: state.code)
                        .frame(width: 84, height: 84)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("QR-Code groß anzeigen")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Lobby-Code")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(AppTheme.textTer)
                    Text(spaced(state.code))
                        .font(.system(size: 32, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppTheme.gold)
                        .textSelection(.enabled)
                    ShareLink(item: LobbyService.joinURL(code: state.code),
                              message: Text("Spiel mit mir bei GolfTrack – Lobby-Code \(state.code)")) {
                        Label("Einladen", systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.gold)
                    }
                }
                Spacer(minLength: 0)
            }

            if !state.courseName.isEmpty {
                Label(lobby.isHost ? state.courseName
                                   : String(localized: "\(state.courseName) – vom Gastgeber übernommen"),
                      systemImage: "flag.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(2)
            }

            VStack(spacing: 8) {
                ForEach(state.members) { member in
                    memberRow(member, isMe: member.id == state.me)
                }
                if state.members.count < 2 {
                    Text("Warte auf Freunde – sie scannen den QR-Code oder geben den Code ein.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Divider().overlay(AppTheme.textTer.opacity(0.3))

            if lobby.isHost {
                Toggle(isOn: Binding(
                    get: { state.tracking },
                    set: { value in Haptics.selection(); Task { await lobby.setTracking(value) } }
                )) {
                    Text("Gegenseitig orten")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.text)
                }
                .tint(AppTheme.gold)
            } else {
                Label(state.tracking ? "Gegenseitiges Orten ist an" : "Gegenseitiges Orten ist aus",
                      systemImage: state.tracking ? "location.fill" : "location.slash")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSec)
            }
            if state.tracking {
                Toggle(isOn: Binding(get: { lobby.shareLocation }, set: { lobby.shareLocation = $0 })) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Meinen Standort teilen")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                        Text("Nur während der Runde, nur für diese Lobby.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
                .tint(AppTheme.gold)
            }

            Button(role: .destructive) {
                Haptics.warning()
                Task { await lobby.leave() }
            } label: {
                Text(lobby.isHost ? "Lobby auflösen" : "Lobby verlassen")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
    }

    private func memberRow(_ member: LobbyMember, isMe: Bool) -> some View {
        HStack(spacing: 12) {
            Text(String(member.name.prefix(1)).uppercased())
                .font(.subheadline.bold())
                .foregroundStyle(darkText)
                .frame(width: 32, height: 32)
                .background(AppTheme.gold.opacity(isMe ? 0.85 : 0.55), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(isMe ? "\(member.name) (du)" : member.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                if member.isHost {
                    Text("Gastgeber")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.gold)
                }
            }
            Spacer(minLength: 0)
            if lobby.isHost && !isMe {
                Button {
                    Haptics.decrement()
                    Task { await lobby.remove(member) }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.textTer)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(member.name) entfernen")
            }
        }
    }

    // MARK: Hilfen

    private func join(_ raw: String) async {
        Haptics.medium()
        await lobby.join(code: raw, name: playerName)
        if lobby.isActive {
            Haptics.success()
            adoptHostCourse()
            enteringCode = false
            codeInput = ""
            codeFocused = false
        } else {
            Haptics.error()
        }
    }

    /// Gäste spielen den Platz des Gastgebers: aus den eigenen Plätzen, sonst
    /// aus dem Verzeichnis übernommen (wie beim Scan eines Platz-QR-Codes).
    private func adoptHostCourse() {
        guard !lobby.isHost, let state = lobby.state, !state.courseName.isEmpty else { return }
        let name = Self.normalized(state.courseName)
        if let current = selectedCourse, Self.normalized(current.name) == name { return }

        if let own = courses.first(where: { Self.normalized($0.name) == name }) {
            selectedCourse = own
            return
        }
        let catalog = CourseCatalogService.shared
        let entry = (state.courseSlug.isEmpty ? nil : catalog.golfCourse(slug: state.courseSlug))
            ?? catalog.allGolfCourses.first { Self.normalized($0.name) == name }
        if let entry {
            selectedCourse = Course.stored(for: entry, in: context)
        }
    }

    /// Kennung des Platzes im Verzeichnis – damit Gäste ihn auch finden, wenn
    /// sie ihn noch nie gespielt haben.
    private func catalogSlug(for course: Course?) -> String {
        guard let course else { return "" }
        let name = Self.normalized(course.name)
        return CourseCatalogService.shared.allGolfCourses
            .first { Self.normalized($0.name) == name }?.slug ?? ""
    }

    /// Platznamen vergleichbar machen: „Golf- und Landclub Bayerwald e.V.“ und
    /// „golf und landclub bayerwald“ sind derselbe Platz.
    static func normalized(_ name: String) -> String {
        var text = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        for suffix in [" e.v.", " e. v.", " ev"] where text.hasSuffix(suffix) {
            text.removeLast(suffix.count)
        }
        return text.unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init).joined()
    }

    private func spaced(_ code: String) -> String {
        code.map(String.init).joined(separator: " ")
    }
}

// MARK: - QR-Code

struct LobbyQRCode: View {
    let code: String

    var body: some View {
        if let image = Self.image(for: LobbyService.joinURL(code: code).absoluteString) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(6)
                .background(.white, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    static func image(for text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cg = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

private struct LobbyQRSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            Text("Zum Beitreten scannen")
                .font(.headline)
                .foregroundStyle(AppTheme.textSec)
            LobbyQRCode(code: code)
                .frame(maxWidth: 300)
            Text(code.map(String.init).joined(separator: " "))
                .font(.system(size: 44, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(AppTheme.gold)
            Text("Freunde öffnen GolfTrack → Neue Runde → Mit Freunden spielen und scannen den Code – oder geben die fünf Ziffern ein.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Fertig") {
                Haptics.tap()
                dismiss()
            }
            .font(.headline)
            .foregroundStyle(AppTheme.gold)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.bg.ignoresSafeArea())
        .presentationDetents([.large])
    }
}
