import SwiftUI
import SwiftData
import PhotosUI
import GameKit

struct ProfileView: View {
    @Query(sort: \Round.date, order: .reverse) private var allRounds: [Round]
    @AppStorage("playerName") private var playerName = "Golfer"
    @State private var editingName = false
    @State private var draftName = ""

    // Profilbild
    @State private var photoItem: PhotosPickerItem?
    @State private var profileImage: UIImage? = nil
    @State private var imageToCrop: UIImage?

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters
    @ObservedObject private var gc = GameCenterManager.shared
    @State private var selectedAchievement: GCAchievement?

    private var completedRounds: [Round] { allRounds.filter(\.isComplete) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                    .onAppear {
                        if profileImage == nil {
                            Task.detached(priority: .userInitiated) {
                                let img = ProfileImageStore.load()
                                await MainActor.run { profileImage = img }
                            }
                        }
                    }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("Profil")
                                .font(.title2.bold())
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // Avatar + name
                        VStack(spacing: 14) {
                            // Avatar mit Foto-Picker
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                ZStack(alignment: .bottomTrailing) {
                                    avatarImage
                                        .frame(width: 88, height: 88)
                                        .clipShape(Circle())

                                    // Kamera-Badge
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.gold)
                                            .frame(width: 28, height: 28)
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                                    }
                                    .offset(x: 4, y: 4)
                                }
                            }
                            .onChange(of: photoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let img = UIImage(data: data) {
                                        imageToCrop = img
                                    }
                                }
                            }
                            .sheet(isPresented: Binding(get: { imageToCrop != nil }, set: { if !$0 { imageToCrop = nil } })) {
                                if let img = imageToCrop {
                                    ImageCropView(image: img) { cropped in
                                        profileImage = cropped
                                        ProfileImageStore.save(cropped)
                                        imageToCrop = nil
                                    }
                                }
                            }

                            // Name
                            if editingName {
                                HStack {
                                    TextField("Dein Name", text: $draftName)
                                        .font(.title3.bold())
                                        .foregroundStyle(AppTheme.text)
                                        .multilineTextAlignment(.center)
                                        .textFieldStyle(.plain)
                                    Button {
                                        playerName = draftName.isEmpty ? playerName : draftName
                                        editingName = false
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.gold)
                                    }
                                }
                                .padding(.horizontal, 40)
                            } else {
                                Button {
                                    draftName = playerName
                                    editingName = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(playerName)
                                            .font(.title3.bold())
                                            .foregroundStyle(AppTheme.text)
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSec)
                                    }
                                }
                            }
                            Text("Golfer")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSec)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .cardStyle()
                        .padding(.horizontal)
                        .tutorialAnchor(.profileHeader)

                        // Stats summary
                        HStack(spacing: 12) {
                            statBox(value: "\(completedRounds.count)", label: "Runden")
                            statBox(value: bestScore, label: "Bestleistung")
                            statBox(value: avgPutts, label: "Ø Putts")
                        }
                        .padding(.horizontal)

                        // WHS Handicap Card
                        handicapCard
                            .padding(.horizontal)
                            .tutorialAnchor(.handicapCard)

                        // Dokumente (Mitgliedskarte, Belege)
                        DocumentsCard()
                            .padding(.horizontal)

                        // Game Center
                        gameCenterCard
                            .padding(.horizontal)

                        // Settings links
                        settingsSection

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 4)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarImage: some View {
        if let img = profileImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle()
                    .fill(AppTheme.gold.opacity(0.2))
                Text(String(playerName.prefix(1)).uppercased())
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(AppTheme.gold)
            }
        }
    }

    // MARK: - Stat Box

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Distance unit picker
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.3, green: 0.7, blue: 1.0))
                }
                Text("Distanzeinheit")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Picker("Einheit", selection: $distanceUnit) {
                    Text("Meter").tag(DistanceUnit.meters)
                    Text("Yards").tag(DistanceUnit.yards)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            Divider().background(AppTheme.cardAlt).padding(.leading, 62)
            settingsRow(icon: "bag.fill", color: AppTheme.gold, title: "Meine Schläger") {
                AnyView(ClubBagView())
            }
            Divider().background(AppTheme.cardAlt).padding(.leading, 62)
            settingsRow(icon: "mappin.and.ellipse", color: AppTheme.gold, title: "Golfplätze verwalten") {
                AnyView(CourseListView())
            }
            Divider().background(AppTheme.cardAlt).padding(.leading, 62)
            settingsRow(icon: "figure.golf", color: Color(red: 0.3, green: 0.85, blue: 0.5), title: "Minigolf") {
                AnyView(MinigolfView())
            }
            Divider().background(AppTheme.cardAlt).padding(.leading, 62)
            settingsRow(icon: "key.fill", color: Color(red: 0.6, green: 0.5, blue: 1.0), title: "API-Einstellungen") {
                AnyView(APIKeySettingsView())
            }
            Divider().background(AppTheme.cardAlt).padding(.leading, 62)
            settingsRow(icon: "questionmark.circle.fill", color: Color(red: 1.0, green: 0.6, blue: 0.3), title: "Hilfe & Anleitung") {
                AnyView(HelpView())
            }
            Divider().background(AppTheme.cardAlt).padding(.leading, 62)
            Button {
                hasSeenOnboarding = false
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(AppTheme.gold.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.gold)
                    }
                    Text("Tutorial neu starten")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTer)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func settingsRow(icon: String, color: Color, title: String, destination: @escaping () -> AnyView) -> some View {
        NavigationLink { destination() } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.18)).frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTer)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
    }

    // MARK: - WHS Handicap Card

    private var handicapCard: some View {
        let info = HandicapCalculator.progressInfo(from: completedRounds)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Handicap Index")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Text("World Handicap System (WHS)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundStyle(AppTheme.gold)
            }

            Divider().background(AppTheme.cardAlt)

            if let info {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", info.handicapIndex))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.gold)
                    Text("HCP")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.textSec)
                        .padding(.bottom, 6)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Beste \(info.usedRounds) von \(info.eligibleRounds)")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textSec)
                        if let best = info.bestDifferentials.min() {
                            Text("Bestes Diff.: \(String(format: "%.1f", best))")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTer)
                        }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(AppTheme.gold)
                    Text("Durchschnitt der \(info.usedRounds) besten Score-Differentials × 0,96")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                .padding(10)
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 8))

                if !info.allDifferentials.isEmpty {
                    let bestIndices: Set<Int> = {
                        let sorted = info.allDifferentials
                            .enumerated()
                            .sorted { $0.element < $1.element }
                        return Set(sorted.prefix(info.usedRounds).map { $0.offset })
                    }()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Score Differentials (letzte Runden)")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textSec)
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                            spacing: 6
                        ) {
                            ForEach(Array(info.allDifferentials.enumerated()), id: \.offset) { i, diff in
                                let isUsed = bestIndices.contains(i)
                                Text(String(format: "%.1f", diff))
                                    .font(.system(size: 12, weight: isUsed ? .bold : .regular))
                                    .foregroundStyle(isUsed ? AppTheme.gold : AppTheme.textTer)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        isUsed ? AppTheme.gold.opacity(0.15) : AppTheme.cardAlt,
                                        in: RoundedRectangle(cornerRadius: 6)
                                    )
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "flag.slash")
                        .font(.title)
                        .foregroundStyle(AppTheme.textTer)
                    Text("Noch nicht genug Daten")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textSec)
                    let missing = max(0, 3 - completedRounds.count)
                    Text(missing > 0
                         ? "Spiele noch \(missing) Runde\(missing == 1 ? "" : "n"), um einen Handicap-Index zu erhalten."
                         : "Für einen vollständigen Index werden Runden mit Course-Rating & Slope-Rating benötigt.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTer)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
        }
        .padding(20)
        .cardStyle()
    }

    // MARK: - Game Center Card

    private var gameCenterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Errungenschaften")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Text("Game Center")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Image(systemName: "gamecontroller.fill")
                    .foregroundStyle(AppTheme.gold)
            }

            Divider().background(AppTheme.cardAlt)

            // Achievement grid – immer sichtbar (lokal gespeichert)
            let achievements = GCAchievement.allCases
            let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(achievements, id: \.rawValue) { a in
                    achievementBadge(a)
                        .onTapGesture { selectedAchievement = a }
                }
            }

            // Game Center Buttons
            if gc.isAuthenticated {
                HStack(spacing: 10) {
                    // Bestenliste
                    Button {
                        gc.showLeaderboard()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "list.number")
                            Text("Bestenliste")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                    }
                    // Errungenschaften / Dashboard
                    Button {
                        gc.showGameCenter()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                            Text("Freunde")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(AppTheme.text)
                    }
                }
            } else {
                Button {
                    gc.authenticate()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gamecontroller.fill")
                        Text("Mit Game Center verbinden")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(AppTheme.textSec)
                }
            }
        }
        .padding(20)
        .cardStyle()
        .onAppear {
            gc.evaluateAchievements(rounds: allRounds)
        }
        .onChange(of: completedRounds.count) { _, _ in
            gc.evaluateAchievements(rounds: allRounds)
        }
        .sheet(item: $selectedAchievement) { a in
            AchievementDetailSheet(achievement: a, isUnlocked: gc.isUnlocked(a), progress: gc.progress(for: a))
        }
    }

    private func achievementBadge(_ achievement: GCAchievement) -> some View {
        let unlocked = gc.isUnlocked(achievement)
        let progress = gc.progress(for: achievement)
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(unlocked ? AppTheme.gold.opacity(0.2) : AppTheme.cardAlt)
                    .frame(width: 44, height: 44)
                Image(systemName: achievement.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(unlocked ? AppTheme.gold : AppTheme.textTer)
                if !unlocked && progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress / 100)
                        .stroke(AppTheme.gold.opacity(0.5), lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                }
            }
            Text(achievement.displayTitle)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(unlocked ? AppTheme.text : AppTheme.textTer)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(unlocked ? AppTheme.gold.opacity(0.07) : AppTheme.cardAlt,
                    in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var bestScore: String {
        let strokes = completedRounds.compactMap { $0.totalStrokes > 0 ? $0.totalStrokes : nil }
        guard let best = strokes.min() else { return "–" }
        return "\(best)"
    }

    private var avgPutts: String {
        let putts = completedRounds.filter { $0.totalPutts > 0 }.map { $0.totalPutts }
        guard !putts.isEmpty else { return "–" }
        return String(format: "%.0f", Double(putts.reduce(0, +)) / Double(putts.count))
    }
}

// MARK: - Profile Image Store

enum ProfileImageStore {
    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_image.jpg")
    }

    static func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
