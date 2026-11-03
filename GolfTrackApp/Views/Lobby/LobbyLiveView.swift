import SwiftUI
import MapKit

/// Leiste unter der Lochkarte: wo die Freunde aus der Lobby gerade stehen.
struct LobbyStrip: View {
    let pars: [Int]
    let onOpen: () -> Void

    private let lobby = LobbyService.shared

    var body: some View {
        if let state = lobby.state, !state.others.isEmpty {
            Button {
                Haptics.tap()
                onOpen()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(state.others) { member in
                                chip(member)
                            }
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textTer)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lobby öffnen")
        }
    }

    private func chip(_ member: LobbyMember) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(member.isStale ? AppTheme.textTer : .green)
                .frame(width: 6, height: 6)
            Text(member.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
            Text(LobbyFormat.toPar(member.toPar(pars: pars)))
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(AppTheme.gold)
            if member.currentHole > 0 {
                Text("L\(member.currentHole)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(AppTheme.textSec)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.bg, in: Capsule())
    }
}

/// Die Lobby während der Runde: Ergebnisse aller, Schläge der Freunde je Loch
/// und – wenn eingeschaltet – die Karte, auf der man sich wiederfindet.
struct LobbyLiveSheet: View {
    let pars: [Int]

    private let lobby = LobbyService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .scores
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)

    enum Tab: Hashable { case scores, map }

    var body: some View {
        NavigationStack {
            Group {
                if let state = lobby.state {
                    VStack(spacing: 0) {
                        Picker("Ansicht", selection: $tab) {
                            Text("Ergebnisse").tag(Tab.scores)
                            Text("Karte").tag(Tab.map)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .onChange(of: tab) { _, _ in Haptics.selection() }

                        switch tab {
                        case .scores: scores(state)
                        case .map: map(state)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(lobby.code.map { "Lobby \($0)" } ?? "Lobby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        Haptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.gold)
                }
            }
            .navigationDestination(for: LobbyMember.self) { member in
                LobbyMemberDetail(memberID: member.id, pars: pars)
            }
        }
        .task { await lobby.refresh() }
    }

    // MARK: Ergebnisse

    private func scores(_ state: LobbyState) -> some View {
        let ranked = state.members.sorted {
            ($0.toPar(pars: pars) ?? .max, $0.name) < ($1.toPar(pars: pars) ?? .max, $1.name)
        }
        return List {
            Section {
                ForEach(ranked) { member in
                    NavigationLink(value: member) {
                        HStack(spacing: 12) {
                            Text(String(member.name.prefix(1)).uppercased())
                                .font(.subheadline.bold())
                                .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                                .frame(width: 32, height: 32)
                                .background(AppTheme.gold.opacity(member.id == state.me ? 0.85 : 0.55), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.id == state.me ? "\(member.name) (du)" : member.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)
                                Text(status(member))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSec)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(LobbyFormat.toPar(member.toPar(pars: pars)))
                                    .font(.title3.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(AppTheme.gold)
                                Text("\(member.totalStrokes) Schläge")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSec)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.card)
                }
            } footer: {
                Text("Jeder zählt auf seinem eigenen iPhone. Aktualisiert sich alle paar Sekunden.")
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func status(_ member: LobbyMember) -> String {
        var parts: [String] = []
        if member.currentHole > 0 { parts.append(String(localized: "Loch \(member.currentHole)")) }
        parts.append(String(localized: "\(member.playedHoles.count) gespielt"))
        if member.isStale {
            parts.append(String(localized: "zuletzt \(member.seenAt.formatted(.relative(presentation: .named)))"))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: Karte

    @ViewBuilder
    private func map(_ state: LobbyState) -> some View {
        if !state.tracking {
            ContentUnavailableView(
                "Orten ist aus",
                systemImage: "location.slash",
                description: Text(lobby.isHost
                                  ? "Schalte „Gegenseitig orten“ beim Rundenstart in der Lobby ein."
                                  : "Der Gastgeber hat das gegenseitige Orten nicht eingeschaltet."))
        } else {
            let located = state.others.filter { $0.location != nil }
            VStack(spacing: 0) {
                Map(position: $camera) {
                    UserAnnotation()
                    ForEach(located) { member in
                        if let location = member.location {
                            Annotation(member.name, coordinate: location.coordinate) {
                                Text(String(member.name.prefix(1)).uppercased())
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                                    .frame(width: 34, height: 34)
                                    .background(AppTheme.gold, in: Circle())
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                                    .shadow(radius: 3)
                            }
                        }
                    }
                }
                .mapStyle(.hybrid(elevation: .flat))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .frame(maxHeight: .infinity)

                VStack(spacing: 8) {
                    if !lobby.shareLocation {
                        Label("Du teilst deinen Standort gerade nicht.", systemImage: "location.slash")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if located.isEmpty {
                        Text("Noch kein Standort von deinen Freunden – sie müssen ihn in der Lobby teilen und die Runde gestartet haben.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                            .multilineTextAlignment(.center)
                    }
                    ForEach(located) { member in
                        friendRow(member)
                    }
                }
                .padding(12)
            }
        }
    }

    private func friendRow(_ member: LobbyMember) -> some View {
        let location = member.location!
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                Text(locationText(location))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer()
            Button {
                Haptics.tap()
                withAnimation {
                    camera = .region(MKCoordinateRegion(center: location.coordinate,
                                                        latitudinalMeters: 250, longitudinalMeters: 250))
                }
            } label: {
                Image(systemName: "scope")
                    .padding(8)
                    .background(AppTheme.gold.opacity(0.15), in: Circle())
            }
            .accessibilityLabel("\(member.name) auf der Karte zeigen")
            Button {
                Haptics.tap()
                let item = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
                item.name = member.name
                item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
            } label: {
                Image(systemName: "figure.walk")
                    .padding(8)
                    .background(AppTheme.gold.opacity(0.15), in: Circle())
            }
            .accessibilityLabel("Zu \(member.name) gehen")
        }
        .foregroundStyle(AppTheme.gold)
        .padding(10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }

    private func locationText(_ location: LobbyLocation) -> String {
        let age = location.at.formatted(.relative(presentation: .named))
        guard let me = lobby.myLocation else { return age }
        let them = CLLocation(latitude: location.lat, longitude: location.lon)
        let meters = Int(me.distance(from: them).rounded())
        let direction = LobbyFormat.compass(from: me.coordinate, to: location.coordinate)
        return "\(meters) m \(direction) · \(age)"
    }
}

/// Schläge eines Mitspielers Loch für Loch, mit Schlägern und Längen.
private struct LobbyMemberDetail: View {
    let memberID: String
    let pars: [Int]

    private let lobby = LobbyService.shared

    var body: some View {
        if let member = lobby.state?.members.first(where: { $0.id == memberID }) {
            List {
                ForEach(member.scores.filter { $0.strokes > 0 }.sorted { $0.hole > $1.hole }, id: \.hole) { hole in
                    Section {
                        HStack {
                            stat("Schläge", "\(hole.strokes)")
                            stat("Putts", "\(hole.putts)")
                            if hole.hole - 1 < pars.count {
                                stat("Par", "\(pars[hole.hole - 1])")
                            }
                            if hole.fairway { badge("Fairway") }
                            if hole.gir { badge("GIR") }
                        }
                        ForEach(hole.shots, id: \.n) { shot in
                            HStack {
                                Text("\(shot.n).")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(AppTheme.textTer)
                                    .frame(width: 24, alignment: .leading)
                                Text(shot.club.isEmpty ? String(localized: "Schlag") : shot.club)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.text)
                                Spacer()
                                if let meters = shot.meters, meters > 0 {
                                    Text("\(Int(meters)) m")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(AppTheme.textSec)
                                }
                            }
                        }
                    } header: {
                        Text("Loch \(hole.hole)")
                    }
                    .listRowBackground(AppTheme.card)
                }
                if member.playedHoles.isEmpty {
                    Text("\(member.name) hat noch kein Loch gespielt.")
                        .foregroundStyle(AppTheme.textSec)
                        .listRowBackground(AppTheme.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle(member.name)
        } else {
            ContentUnavailableView("Nicht mehr in der Lobby", systemImage: "person.slash")
        }
    }

    private func stat(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(AppTheme.gold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(minWidth: 52)
    }

    private func badge(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(AppTheme.gold.opacity(0.2), in: Capsule())
            .foregroundStyle(AppTheme.gold)
    }
}

enum LobbyFormat {
    static func toPar(_ value: Int?) -> String {
        guard let value else { return "–" }
        if value == 0 { return "E" }
        return value > 0 ? "+\(value)" : "\(value)"
    }

    /// Himmelsrichtung von `from` nach `to` (N, NO, O, …).
    static func compass(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> String {
        let lat1 = from.latitude * .pi / 180, lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        let names = [String(localized: "N"), String(localized: "NO"), String(localized: "O"), String(localized: "SO"),
                     String(localized: "S"), String(localized: "SW"), String(localized: "W"), String(localized: "NW")]
        return names[Int((bearing + 22.5) / 45) % 8]
    }
}
