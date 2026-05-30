import SwiftUI
import MapKit

// MARK: - Card embedded in RoundCompleteSheet

struct RoundShotMapCard: View {
    let round: Round

    @State private var isExpanded = false
    @State private var isSatellite = false

    // One colour per hole (cycles for 18+)
    private static let palette: [Color] = [
        Color(red: 0.20, green: 0.52, blue: 0.96),   // blue
        Color(red: 0.96, green: 0.52, blue: 0.20),   // orange
        Color(red: 0.22, green: 0.78, blue: 0.38),   // green
        Color(red: 0.78, green: 0.30, blue: 0.96),   // purple
        Color(red: 0.96, green: 0.28, blue: 0.28),   // red
        Color(red: 0.10, green: 0.80, blue: 0.78),   // teal
        Color(red: 0.85, green: 0.70, blue: 0.20),   // gold
        Color(red: 0.40, green: 0.80, blue: 0.40),   // lime
        Color(red: 0.90, green: 0.40, blue: 0.60),   // pink
        Color(red: 0.40, green: 0.40, blue: 0.90),   // indigo
    ]

    // Flat list of all tracked shots enriched with display info
    private struct ShotItem: Identifiable {
        let id: String          // "h3s2" → hole 3, shot 2
        let shotNumber: Int
        let holeNumber: Int
        let fromCoord: CLLocationCoordinate2D
        let toCoord: CLLocationCoordinate2D
        let color: Color
    }

    private var items: [ShotItem] {
        round.sortedScores
            .filter { !$0.sortedShots.isEmpty }
            .enumerated()
            .flatMap { holeIdx, hs in
                let c = Self.palette[holeIdx % Self.palette.count]
                return hs.sortedShots.map {
                    ShotItem(id: "h\(hs.holeNumber)s\($0.shotNumber)",
                             shotNumber: $0.shotNumber,
                             holeNumber: hs.holeNumber,
                             fromCoord: $0.fromCoordinate,
                             toCoord: $0.toCoordinate,
                             color: c)
                }
            }
    }

    private var holes: [(number: Int, color: Color)] {
        var seen = Set<Int>()
        return items.compactMap { item in
            guard !seen.contains(item.holeNumber) else { return nil }
            seen.insert(item.holeNumber)
            return (item.holeNumber, item.color)
        }
    }

    // MapKit's .automatic camera fits all annotations; no manual region needed.

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack {
                Label("Schläge auf der Karte", systemImage: "map.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Button { isExpanded = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text("Vollbild")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.gold)
                }
            }

            // Compact map (non-interactive)
            mapContent(interactive: false)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .allowsHitTesting(false)

            // Per-hole colour legend
            if holes.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(holes, id: \.number) { h in
                            HStack(spacing: 5) {
                                Circle().fill(h.color).frame(width: 8, height: 8)
                                Text("Loch \(h.number)")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSec)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .fullScreenCover(isPresented: $isExpanded) { expandedView }
    }

    // MARK: - Map builder

    @ViewBuilder
    private func mapContent(interactive: Bool) -> some View {
        // .automatic lets MapKit frame all annotations perfectly — no manual region math.
        Map(initialPosition: .automatic) {
            ForEach(items) { item in
                // Shot path line
                MapPolyline(coordinates: [item.fromCoord, item.toCoord])
                    .stroke(item.color.opacity(0.85), lineWidth: 2.5)

                // Numbered start marker — empty title suppresses the callout label
                Annotation("", coordinate: item.fromCoord, anchor: .center) {
                    ZStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 22, height: 22)
                            .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                        Text("\(item.shotNumber)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                // Small landing dot
                Annotation("", coordinate: item.toCoord, anchor: .center) {
                    Circle()
                        .fill(item.color.opacity(0.75))
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.2), radius: 1)
                }
            }
        }
        .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard)
        .mapControls {
            if interactive {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
        }
    }

    // MARK: - Full-screen expanded view

    private var expandedView: some View {
        NavigationStack {
            mapContent(interactive: true)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Schlagkarte")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Schließen") { isExpanded = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isSatellite.toggle()
                        } label: {
                            Image(systemName: isSatellite ? "map" : "globe.europe.africa")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if holes.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(holes, id: \.number) { h in
                                    HStack(spacing: 5) {
                                        Circle().fill(h.color).frame(width: 9, height: 9)
                                        Text("Loch \(h.number)")
                                            .font(.caption.bold())
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .background(.ultraThinMaterial)
                    }
                }
        }
    }
}
