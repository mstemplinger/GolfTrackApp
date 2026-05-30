import SwiftUI
import AVFoundation
import Combine
import MediaPlayer

// MARK: - Model

enum TrainingCategory: String, CaseIterable {
    case alle        = "Alle"
    case grundlagen  = "Grundlagen"
    case drive       = "Drive"
    case technik     = "Technik"
    case anspiel     = "Anspiel"
    case kurzspiel   = "Kurzspiel"
    case putten      = "Putten"
    case mental      = "Mental"
    case strategie   = "Strategie"

    var icon: String {
        switch self {
        case .alle:       return "square.grid.2x2.fill"
        case .grundlagen: return "star.fill"
        case .drive:      return "figure.golf"
        case .technik:    return "gearshape.fill"
        case .anspiel:    return "target"
        case .kurzspiel:  return "figure.golf.circle.fill"
        case .putten:     return "circle.fill"
        case .mental:     return "brain.head.profile"
        case .strategie:  return "map.fill"
        }
    }

    var color: Color {
        switch self {
        case .alle:       return AppTheme.gold
        case .grundlagen: return Color(red: 0.3, green: 0.85, blue: 0.5)
        case .drive:      return AppTheme.gold
        case .technik:    return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .anspiel:    return Color(red: 1.0, green: 0.6, blue: 0.3)
        case .kurzspiel:  return Color(red: 1.0, green: 0.5, blue: 0.3)
        case .putten:     return Color(red: 0.6, green: 0.5, blue: 1.0)
        case .mental:     return Color(red: 0.9, green: 0.4, blue: 0.7)
        case .strategie:  return Color(red: 0.4, green: 0.8, blue: 0.6)
        }
    }
}

struct TrainingLesson: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let category: TrainingCategory
    let durationLabel: String
    let audioFile: String?

    var isAvailable: Bool { audioFile != nil }
}

// MARK: - Content

private let allLessons: [TrainingLesson] = [
    TrainingLesson(id: "01", title: "Der richtige Griff",       subtitle: "Fundament jedes Schlags",               category: .grundlagen, durationLabel: "2 Min.",   audioFile: "01_grundlagen_griff"),
    TrainingLesson(id: "02", title: "Stand und Balance",         subtitle: "Stabilität für mehr Konsistenz",        category: .grundlagen, durationLabel: "2 Min.",   audioFile: "02_grundlagen_stand"),
    TrainingLesson(id: "03", title: "Driver-Strategie",          subtitle: "Warum fast immer der Driver besser ist", category: .drive,     durationLabel: "2,5 Min.", audioFile: "03_drive_strategie"),
    TrainingLesson(id: "04", title: "Gewichtsverlagerung",       subtitle: "Hüftrotation und Schwungkraft",         category: .technik,    durationLabel: "2,5 Min.", audioFile: "04_technik_schwung"),
    TrainingLesson(id: "05", title: "Weniger Lob-Wedge",         subtitle: "Die häufigste Kurzspiel-Falle",         category: .kurzspiel,  durationLabel: "2,5 Min.", audioFile: "05_kurzspiel_chip"),
    TrainingLesson(id: "06", title: "Drei-Putts vermeiden",      subtitle: "Distanzkontrolle auf dem Grün",         category: .putten,     durationLabel: "2,5 Min.", audioFile: "06_putten_distanzkontrolle"),
    TrainingLesson(id: "07", title: "Pre-Shot Routine",          subtitle: "Dein Anker auf dem Platz",              category: .mental,     durationLabel: "2 Min.",   audioFile: "07_mental_pre_shot"),
    TrainingLesson(id: "08", title: "Fehler loslassen",          subtitle: "Ein Schlag nach dem anderen",           category: .mental,     durationLabel: "2 Min.",   audioFile: "08_mental_fehler"),
    TrainingLesson(id: "09", title: "Course Management",         subtitle: "Smarter spielen, weniger Fehler",       category: .strategie,  durationLabel: "2,5 Min.", audioFile: "09_strategie_course_management"),
    TrainingLesson(id: "10", title: "Schlägerwahl beim Anspiel", subtitle: "Immer einen Schläger mehr nehmen",      category: .anspiel,    durationLabel: "2 Min.",   audioFile: "10_anspiel_schlaegewahl"),
    TrainingLesson(id: "11", title: "Bunker-Spiel",              subtitle: "Raus, und zwar sicher",                 category: .kurzspiel,  durationLabel: "2 Min.",   audioFile: nil),
    TrainingLesson(id: "12", title: "Den Ball sauber treffen",   subtitle: "Trefferfläche und Sweet Spot",          category: .technik,    durationLabel: "2 Min.",   audioFile: nil),
]

private let availableLessons = allLessons.filter(\.isAvailable)

// MARK: - Player ViewModel

@MainActor
final class TrainingPlayerModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var currentLesson: TrainingLesson?

    @AppStorage("training_autoplay") var autoplay: Bool = true
    @AppStorage("training_speed")    var speedRaw: Double = 1.0

    var speed: Float { Float(speedRaw) }

    /// Wird von TrainingView aktuell gehalten
    var isSubscribed: Bool = false
    /// Callback → TrainingView zeigt die Paywall
    var onNeedsSubscription: (() -> Void)?

    private var player: AVAudioPlayer?
    private var timer: Timer?

    var progress: Double { duration > 0 ? currentTime / duration : 0 }

    var currentIndex: Int? {
        guard let lesson = currentLesson else { return nil }
        return availableLessons.firstIndex(where: { $0.id == lesson.id })
    }
    var canGoNext: Bool { (currentIndex ?? -1) < availableLessons.count - 1 }
    var canGoPrev: Bool { (currentIndex ?? 0) > 0 }

    private func lessonIsAccessible(_ lesson: TrainingLesson) -> Bool {
        lesson.id == "01" || isSubscribed
    }

    init() {
        setupRemoteCommands()
    }

    // MARK: Playback

    func load(_ lesson: TrainingLesson) {
        guard let file = lesson.audioFile,
              let url = Bundle.main.url(forResource: file, withExtension: "mp3") else { return }
        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.enableRate = true
            player?.rate = speed
            player?.prepareToPlay()
            duration = player?.duration ?? 1
            currentTime = 0
            currentLesson = lesson
            updateNowPlaying(playing: false)
        } catch {}
    }

    func play() {
        player?.rate = speed
        player?.play()
        isPlaying = true
        startTimer()
        updateNowPlaying(playing: true)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
        updateNowPlaying(playing: false)
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func stop() {
        player?.stop()
        isPlaying = false
        currentTime = 0
        stopTimer()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func seek(to fraction: Double) {
        let t = fraction * duration
        player?.currentTime = t
        currentTime = t
        updateNowPlayingProgress()
    }

    func skip(seconds: Double) {
        let t = min(max(0, (player?.currentTime ?? 0) + seconds), duration)
        player?.currentTime = t
        currentTime = t
        updateNowPlayingProgress()
    }

    func setSpeed(_ newSpeed: Float) {
        speedRaw = Double(newSpeed)
        player?.rate = newSpeed
        updateNowPlayingProgress()
    }

    func playNext() {
        guard let idx = currentIndex, idx < availableLessons.count - 1 else { return }
        let next = availableLessons[idx + 1]
        guard lessonIsAccessible(next) else {
            stop()
            onNeedsSubscription?()
            return
        }
        load(next)
        play()
    }

    func playPrev() {
        if currentTime > 3 {
            seek(to: 0)
        } else if let idx = currentIndex, idx > 0 {
            load(availableLessons[idx - 1])
            play()
        }
    }

    // MARK: Now Playing

    private func updateNowPlaying(playing: Bool) {
        guard let lesson = currentLesson else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:            lesson.title,
            MPMediaItemPropertyArtist:           "GolfTrack Training",
            MPMediaItemPropertyAlbumTitle:        lesson.category.rawValue,
            MPMediaItemPropertyPlaybackDuration:  duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: playing ? Double(speed) : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
        ]
        info[MPMediaItemPropertyArtwork] = makeArtwork(for: lesson)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingProgress() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(speed) : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func makeArtwork(for lesson: TrainingLesson) -> MPMediaItemArtwork {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor(AppTheme.bg).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor(lesson.category.color).withAlphaComponent(0.25).setFill()
            UIBezierPath(ovalIn: CGRect(x: 50, y: 50, width: 200, height: 200)).fill()
            let config = UIImage.SymbolConfiguration(pointSize: 88, weight: .semibold)
            if let symbol = UIImage(systemName: lesson.category.icon, withConfiguration: config)?
                .withTintColor(UIColor(lesson.category.color), renderingMode: .alwaysOriginal) {
                let x = (size.width - symbol.size.width) / 2
                let y = (size.height - symbol.size.height) / 2
                symbol.draw(at: CGPoint(x: x, y: y))
            }
        }
        return MPMediaItemArtwork(boundsSize: size) { _ in image }
    }

    // MARK: Remote Commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.play() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .noSuchContent }
            Task { @MainActor in
                guard self.canGoNext else { return }
                self.playNext()
            }
            return .success
        }
        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .noSuchContent }
            Task { @MainActor in self.playPrev() }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [30]
        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.addTarget { [weak self] event in
            guard let e = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.skip(seconds: e.interval) }
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.addTarget { [weak self] event in
            guard let e = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.skip(seconds: -e.interval) }
            return .success
        }
        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in
                self?.player?.currentTime = e.positionTime
                self?.currentTime = e.positionTime
                self?.updateNowPlayingProgress()
            }
            return .success
        }
    }

    // MARK: Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let p = self.player else { return }
            Task { @MainActor in
                self.currentTime = p.currentTime
                self.updateNowPlayingProgress()
                if !p.isPlaying && self.isPlaying {
                    self.isPlaying = false
                    self.stopTimer()
                    // Autoplay nur wenn nächste Lektion zugänglich ist
                    let nextIdx = (self.currentIndex ?? -1) + 1
                    let nextAccessible = nextIdx < availableLessons.count
                        && self.lessonIsAccessible(availableLessons[nextIdx])
                    if self.autoplay && self.canGoNext && nextAccessible {
                        self.playNext()
                    } else {
                        self.currentTime = 0
                        self.updateNowPlaying(playing: false)
                        if self.canGoNext && !nextAccessible {
                            self.onNeedsSubscription?()
                        }
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Main View

struct TrainingView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var playerModel = TrainingPlayerModel()
    @State private var selectedCategory: TrainingCategory = .alle
    @State private var showPlayer   = false
    @State private var showPaywall  = false

    private var filteredLessons: [TrainingLesson] {
        selectedCategory == .alle ? allLessons : allLessons.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                categoryFilter
                lessonList
            }

            if playerModel.currentLesson != nil {
                miniPlayer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showPlayer) {
            TrainingPlayerSheet(model: playerModel)
        }
        .sheet(isPresented: $showPaywall) {
            TrainingPaywallView()
                .environmentObject(subscriptionManager)
        }
        .animation(.spring(response: 0.35), value: playerModel.currentLesson?.id)
        .onAppear {
            playerModel.isSubscribed = subscriptionManager.isSubscribed
            playerModel.onNeedsSubscription = { showPaywall = true }
        }
        .onChange(of: subscriptionManager.isSubscribed) { _, subscribed in
            playerModel.isSubscribed = subscribed
            if !subscribed { playerModel.stop() }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Training")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.text)
            Spacer()
            if subscriptionManager.isSubscribed {
                Label("Pro", systemImage: "crown.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.gold, in: Capsule())
            } else {
                Button { showPaywall = true } label: {
                    Label("Pro freischalten", systemImage: "crown.fill")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.gold.opacity(0.15), in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.gold.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TrainingCategory.allCases, id: \.self) { cat in
                    categoryChip(cat)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    private func categoryChip(_ cat: TrainingCategory) -> some View {
        Button { selectedCategory = cat } label: {
            HStack(spacing: 5) {
                Image(systemName: cat.icon)
                    .font(.caption2.bold())
                Text(cat.rawValue)
                    .font(.caption.bold())
            }
            .foregroundStyle(selectedCategory == cat ? Color(red: 0.10, green: 0.22, blue: 0.13) : AppTheme.textSec)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(selectedCategory == cat ? cat.color : AppTheme.card, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Lesson List

    private var lessonList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(filteredLessons) { lesson in
                    lessonCard(lesson)
                }
                Spacer(minLength: playerModel.currentLesson != nil ? 90 : 30)
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }

    private func lessonCard(_ lesson: TrainingLesson) -> some View {
        // Zugriffslogik:
        // - kein audioFile               → "Bald verfügbar", kein Tap
        // - audioFile, erste Lektion     → immer kostenlos spielbar
        // - audioFile, kein Abo          → Paywall zeigen
        // - audioFile + Abo              → Normal abspielen
        let hasAudio     = lesson.isAvailable
        let isFree       = lesson.id == "01"
        let canPlay      = hasAudio && (subscriptionManager.isSubscribed || isFree)
        let needsPaywall = hasAudio && !subscriptionManager.isSubscribed && !isFree
        let isActive     = playerModel.currentLesson?.id == lesson.id

        return Button {
            if needsPaywall {
                showPaywall = true
            } else if canPlay {
                if isActive {
                    playerModel.toggle()
                } else {
                    playerModel.load(lesson)
                    playerModel.play()
                }
            }
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasAudio ? lesson.category.color.opacity(0.18) : AppTheme.cardAlt)
                        .frame(width: 50, height: 50)
                    Image(systemName: lesson.category.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(hasAudio ? lesson.category.color : AppTheme.textTer)
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(lesson.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(hasAudio ? AppTheme.text : AppTheme.textSec)
                    Text(lesson.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(lesson.durationLabel)
                            .font(.caption2)
                        Text("·")
                            .font(.caption2)
                        Text(lesson.category.rawValue)
                            .font(.caption2)
                        if isFree {
                            Text("·")
                                .font(.caption2)
                            Text("Gratis")
                                .font(.caption2.bold())
                                .foregroundStyle(Color(red: 0.3, green: 0.85, blue: 0.5))
                        }
                    }
                    .foregroundStyle(AppTheme.textTer)
                }

                Spacer()

                // Rechtes Icon
                if isActive && canPlay {
                    Image(systemName: playerModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(lesson.category.color)
                } else if canPlay {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(lesson.category.color)
                } else if needsPaywall {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.gold)
                } else {
                    // kein audioFile → bald verfügbar
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textTer)
                }
            }
            .padding(14)
            .background(
                isActive && canPlay
                    ? lesson.category.color.opacity(0.1)
                    : AppTheme.card,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                if isActive && canPlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lesson.category.color.opacity(0.4), lineWidth: 1)
                } else if needsPaywall {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.gold.opacity(0.15), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(hasAudio ? 1.0 : 0.45)
    }

    // MARK: Mini Player

    private var miniPlayer: some View {
        Button { showPlayer = true } label: {
            HStack(spacing: 12) {
                if let lesson = playerModel.currentLesson {
                    ZStack {
                        Circle()
                            .fill(lesson.category.color.opacity(0.2))
                            .frame(width: 38, height: 38)
                        Image(systemName: lesson.category.icon)
                            .font(.system(size: 15))
                            .foregroundStyle(lesson.category.color)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(lesson.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                        Text(timeString(playerModel.currentTime) + " / " + timeString(playerModel.duration))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSec)
                    }

                    Spacer()

                    Button { playerModel.skip(seconds: -15) } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 17))
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .buttonStyle(.plain)

                    Button { playerModel.toggle() } label: {
                        Image(systemName: playerModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.text)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.gold, in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button { playerModel.playNext() } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(playerModel.canGoNext ? AppTheme.textSec : AppTheme.textTer)
                    }
                    .buttonStyle(.plain)
                    .disabled(!playerModel.canGoNext)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.cardDark, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.gold.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Player Sheet

struct TrainingPlayerSheet: View {
    @ObservedObject var model: TrainingPlayerModel
    @Environment(\.dismiss) private var dismiss

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    private var lesson: TrainingLesson? { model.currentLesson }
    private var accentColor: Color { lesson?.category.color ?? AppTheme.gold }

    private var displayProgress: Double { isDragging ? dragProgress : model.progress }
    private var displayTime: Double { isDragging ? dragProgress * model.duration : model.currentTime }

    private let speedOptions: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                dragIndicator

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        artwork
                        if let lesson { meta(lesson) }
                        progressSection
                        controls
                        speedPicker
                        settingsRow
                        if let lesson { descriptionCard(lesson) }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: Sub-views

    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(AppTheme.textTer)
            .frame(width: 36, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }

    private var artwork: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.08))
                .frame(width: 160, height: 160)
            Circle()
                .fill(accentColor.opacity(0.14))
                .frame(width: 120, height: 120)
            if let lesson {
                Image(systemName: lesson.category.icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .scaleEffect(model.isPlaying ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: model.isPlaying)
            }
        }
        .padding(.top, 8)
    }

    private func meta(_ lesson: TrainingLesson) -> some View {
        VStack(spacing: 6) {
            Text(lesson.category.rawValue.uppercased())
                .font(.caption.bold())
                .kerning(1.2)
                .foregroundStyle(accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(accentColor.opacity(0.12), in: Capsule())

            Text(lesson.title)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.text)
                .multilineTextAlignment(.center)
                .animation(.none, value: lesson.id)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.cardAlt).frame(height: 5)
                    Capsule()
                        .fill(accentColor)
                        .frame(width: geo.size.width * max(0, min(1, displayProgress)), height: 5)
                }
                .contentShape(Rectangle().size(CGSize(width: geo.size.width, height: 28)).offset(y: -11))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            dragProgress = min(max(0, value.location.x / geo.size.width), 1)
                        }
                        .onEnded { value in
                            model.seek(to: min(max(0, value.location.x / geo.size.width), 1))
                            isDragging = false
                        }
                )
            }
            .frame(height: 5)

            HStack {
                Text(timeString(displayTime))
                Spacer()
                Text(timeString(model.duration))
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSec)
        }
    }

    private var controls: some View {
        HStack(spacing: 28) {
            Button { model.playPrev() } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(model.canGoPrev ? AppTheme.textSec : AppTheme.textTer)
            }
            .buttonStyle(.plain)
            .disabled(!model.canGoPrev)

            Button { model.skip(seconds: -15) } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.textSec)
            }
            .buttonStyle(.plain)

            Button { model.toggle() } label: {
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 70, height: 70)
                    Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                        .offset(x: model.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(.plain)

            Button { model.skip(seconds: 30) } label: {
                Image(systemName: "goforward.30")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.textSec)
            }
            .buttonStyle(.plain)

            Button { model.playNext() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(model.canGoNext ? AppTheme.textSec : AppTheme.textTer)
            }
            .buttonStyle(.plain)
            .disabled(!model.canGoNext)
        }
        .padding(.vertical, 4)
    }

    private var speedPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wiedergabegeschwindigkeit")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
                .padding(.horizontal, 4)

            HStack(spacing: 6) {
                ForEach(speedOptions, id: \.self) { s in
                    Button { model.setSpeed(s) } label: {
                        Text(speedLabel(s))
                            .font(.caption.bold())
                            .foregroundStyle(model.speed == s
                                ? Color(red: 0.08, green: 0.18, blue: 0.11)
                                : AppTheme.textSec)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(model.speed == s ? accentColor : AppTheme.cardAlt, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private var settingsRow: some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.textSec)
            Text("Nächste Einheit automatisch abspielen")
                .font(.subheadline)
                .foregroundStyle(AppTheme.text)
            Spacer()
            Toggle("", isOn: $model.autoplay)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func descriptionCard(_ lesson: TrainingLesson) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Über diese Einheit", systemImage: "text.alignleft")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSec)

            Text(lesson.subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Label(lesson.durationLabel, systemImage: "clock")
                Label(lesson.category.rawValue, systemImage: lesson.category.icon)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textTer)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Helpers

private func timeString(_ seconds: Double) -> String {
    let s = max(0, Int(seconds))
    return String(format: "%d:%02d", s / 60, s % 60)
}

private func speedLabel(_ speed: Float) -> String {
    speed == 1.0 ? "1×" : speed == 1.25 ? "1.25×" : speed == 1.5 ? "1.5×" : speed == 0.75 ? "0.75×" : speed == 0.5 ? "0.5×" : "2×"
}
