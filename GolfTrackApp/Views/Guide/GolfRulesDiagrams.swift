import SwiftUI

// MARK: - Design Tokens

private enum GC {
    static let bg        = Color(red: 0.06, green: 0.11, blue: 0.06)
    static let grass     = Color(red: 0.13, green: 0.52, blue: 0.18)
    static let grassDark = Color(red: 0.05, green: 0.28, blue: 0.09)
    static let rough     = Color(red: 0.09, green: 0.36, blue: 0.12)
    static let sand      = Color(red: 0.87, green: 0.76, blue: 0.51)
    static let sandDark  = Color(red: 0.72, green: 0.60, blue: 0.36)
    static let water     = Color(red: 0.07, green: 0.38, blue: 0.80)
    static let waterDark = Color(red: 0.03, green: 0.20, blue: 0.52)
    static let optYellow = Color(red: 1.00, green: 0.84, blue: 0.10)
    static let optRed    = Color(red: 0.92, green: 0.22, blue: 0.18)
    static let optGreen  = Color(red: 0.16, green: 0.88, blue: 0.44)
    static let optOrange = Color(red: 0.98, green: 0.56, blue: 0.08)
    static let flagRed   = Color(red: 0.90, green: 0.18, blue: 0.18)
}

// MARK: - Shared Drawing Helpers

/// Arrow line drawn with Canvas — returns an overlay-safe View
private func arrow(from: CGPoint, to: CGPoint,
                   color: Color, width: CGFloat = 2) -> some View {
    Canvas { ctx, _ in
        let dx = to.x - from.x
        let dy = to.y - from.y
        let angle = atan2(dy, dx)
        let h: CGFloat = 10
        var p = Path()
        p.move(to: from); p.addLine(to: to)
        p.move(to: to)
        p.addLine(to: CGPoint(x: to.x - h * cos(angle - .pi/6),
                              y: to.y - h * sin(angle - .pi/6)))
        p.move(to: to)
        p.addLine(to: CGPoint(x: to.x - h * cos(angle + .pi/6),
                              y: to.y - h * sin(angle + .pi/6)))
        ctx.stroke(p, with: .color(color), lineWidth: width)
    }
}

/// Golf ball with radial gradient + shadow
private struct Ball: View {
    var size: CGFloat = 12
    var color: Color = .white
    var body: some View {
        Circle()
            .fill(RadialGradient(
                colors: [color, color.opacity(0.75)],
                center: .topLeading, startRadius: 0, endRadius: size))
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 2)
    }
}

/// Numbered option badge
private struct OptBadge: View {
    let n: String; let label: String; let color: Color
    var body: some View {
        HStack(spacing: 5) {
            Text(n)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 18, height: 18)
                .background(color, in: Circle())
            Text(label)
                .font(.caption2)
                .foregroundStyle(color)
        }
    }
}

/// Pill-shaped label
private struct Chip: View {
    let text: String
    var bg: Color = Color.white.opacity(0.12)
    var fg: Color = .white
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(fg.opacity(0.8))
            }
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(fg)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(bg, in: Capsule())
    }
}

/// Flag shape
private struct FlagPath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY * 0.6))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY * 1.2))
        p.closeSubpath()
        return p
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Diagram Container

private struct DiagramCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GC.optGreen)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))

            content()
        }
        .background(GC.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
}

// MARK: - 1. Abschlag / Teeing Area

struct TeeBoxDiagram: View {
    var body: some View {
        DiagramCard(title: "Abschlagsbereich – Vogelperspektive",
                    icon: "figure.golf") {
            ZStack {
                // Fairway gradient
                LinearGradient(
                    colors: [GC.grassDark, GC.rough.opacity(0.8)],
                    startPoint: .top, endPoint: .bottom)

                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    let bW = w * 0.50, bH = h * 0.33
                    let bX = (w - bW) / 2, bY = h * 0.44

                    // Fairway corridor
                    RoundedRectangle(cornerRadius: 40)
                        .fill(LinearGradient(
                            colors: [GC.grass.opacity(0.5), GC.grassDark.opacity(0.3)],
                            startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.32, height: h)
                        .position(x: w / 2, y: h / 2)

                    // Tee box fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(GC.grass.opacity(0.60))
                        .frame(width: bW, height: bH)
                        .position(x: w / 2, y: bY + bH / 2)

                    // Tee box dashed border
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.65),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .frame(width: bW, height: bH)
                        .position(x: w / 2, y: bY + bH / 2)

                    // Width arrow
                    arrow(from: CGPoint(x: bX + 4, y: bY - 11),
                          to:   CGPoint(x: bX + bW - 4, y: bY - 11),
                          color: .white.opacity(0.6), width: 1.5)
                    Text("Abschlagbreite")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .position(x: w / 2, y: bY - 22)

                    // 2-club-length right side bar
                    Canvas { ctx, _ in
                        var p = Path()
                        p.move(to:    CGPoint(x: bX + bW + 14, y: bY))
                        p.addLine(to: CGPoint(x: bX + bW + 14, y: bY + bH))
                        ctx.stroke(p, with: .color(GC.optYellow.opacity(0.8)),
                                   style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        let arr = arrowPath(
                            from: CGPoint(x: bX + bW + 14, y: bY + 6),
                            to:   CGPoint(x: bX + bW + 14, y: bY + bH - 6))
                        ctx.stroke(arr, with: .color(GC.optYellow.opacity(0.8)), lineWidth: 1.5)
                    }
                    Text("2 SL")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(GC.optYellow)
                        .rotationEffect(.degrees(90))
                        .position(x: bX + bW + 31, y: bY + bH / 2)

                    // Left marker peg
                    ZStack {
                        Circle().fill(GC.optRed)
                            .frame(width: 12, height: 12)
                            .shadow(color: GC.optRed.opacity(0.6), radius: 4)
                        Circle().stroke(Color.white.opacity(0.6), lineWidth: 1)
                            .frame(width: 12, height: 12)
                    }.position(x: bX, y: bY)

                    // Right marker peg
                    ZStack {
                        Circle().fill(GC.optRed)
                            .frame(width: 12, height: 12)
                            .shadow(color: GC.optRed.opacity(0.6), radius: 4)
                        Circle().stroke(Color.white.opacity(0.6), lineWidth: 1)
                            .frame(width: 12, height: 12)
                    }.position(x: bX + bW, y: bY)

                    // Ball on tee
                    ZStack {
                        Ball(size: 13)
                        // Tee stick
                        Path { p in
                            p.move(to: CGPoint(x: w / 2, y: bY + bH * 0.48 + 7))
                            p.addLine(to: CGPoint(x: w / 2, y: bY + bH * 0.48 + 16))
                        }
                        .stroke(GC.sand, lineWidth: 2)
                    }.position(x: w / 2, y: bY + bH * 0.48)

                    // Direction to hole
                    arrow(from: CGPoint(x: w / 2, y: bY - 32),
                          to:   CGPoint(x: w / 2, y: h * 0.05),
                          color: GC.optGreen, width: 2.5)
                    Chip(text: "Richtung Loch", bg: GC.optGreen.opacity(0.2), fg: GC.optGreen)
                        .position(x: w / 2, y: h * 0.13)

                    // Allowed zone chip
                    Chip(text: "✓ Erlaubter Bereich", bg: GC.optGreen.opacity(0.18), fg: GC.optGreen)
                        .position(x: w / 2, y: bY + bH + 18)
                }
            }
            .frame(height: 200)
        }
    }
}

private func arrowPath(from: CGPoint, to: CGPoint) -> Path {
    let dx = to.x - from.x, dy = to.y - from.y
    let angle = atan2(dy, dx), h: CGFloat = 10
    var p = Path()
    p.move(to: from); p.addLine(to: to)
    p.move(to: to)
    p.addLine(to: CGPoint(x: to.x - h*cos(angle - .pi/6),
                          y: to.y - h*sin(angle - .pi/6)))
    p.move(to: to)
    p.addLine(to: CGPoint(x: to.x - h*cos(angle + .pi/6),
                          y: to.y - h*sin(angle + .pi/6)))
    return p
}

// MARK: - 2. Penalty Area

struct PenaltyAreaDiagram: View {
    var body: some View {
        DiagramCard(title: "Penalty Area – Erleichterungsoptionen",
                    icon: "drop.fill") {
            ZStack {
                LinearGradient(
                    colors: [GC.grassDark, GC.rough.opacity(0.7)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)

                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    let cx = w * 0.40, cy = h * 0.45
                    let wW = w * 0.38, wH = h * 0.38

                    // Water glow
                    Ellipse()
                        .fill(GC.waterDark.opacity(0.5))
                        .frame(width: wW + 14, height: wH + 14)
                        .position(x: cx, y: cy)
                        .blur(radius: 8)

                    // Water body
                    Ellipse()
                        .fill(LinearGradient(
                            colors: [GC.water, GC.waterDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: wW, height: wH)
                        .position(x: cx, y: cy)

                    // Water shimmer
                    Ellipse()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: wW * 0.5, height: wH * 0.25)
                        .position(x: cx - wW * 0.08, y: cy - wH * 0.12)

                    // Yellow border ring
                    Ellipse()
                        .stroke(GC.optYellow.opacity(0.85),
                                style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: wW + 10, height: wH + 10)
                        .position(x: cx, y: cy)

                    // Red border ring (outer)
                    Ellipse()
                        .stroke(GC.optRed.opacity(0.75),
                                style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: wW + 22, height: wH + 22)
                        .position(x: cx, y: cy)

                    // Water label
                    VStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Penalty Area")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .position(x: cx, y: cy)

                    // Ball trajectory dashed curve
                    Canvas { ctx, _ in
                        var p = Path()
                        p.move(to: CGPoint(x: w * 0.10, y: h * 0.22))
                        p.addQuadCurve(
                            to: CGPoint(x: cx - wW * 0.1, y: cy + wH * 0.3),
                            control: CGPoint(x: w * 0.26, y: h * 0.03))
                        ctx.stroke(p, with: .color(.white.opacity(0.45)),
                                   style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }

                    // Entry point dot
                    ZStack {
                        Circle().fill(GC.optYellow)
                            .frame(width: 10, height: 10)
                            .shadow(color: GC.optYellow.opacity(0.8), radius: 5)
                        Text("E")
                            .font(.system(size: 7, weight: .black))
                            .foregroundStyle(.black)
                    }.position(x: cx - wW * 0.1, y: cy + wH * 0.3)

                    // Abschlag ball
                    Ball(size: 10).position(x: w * 0.10, y: h * 0.22)

                    // Option A — hintere Linie
                    Canvas { ctx, _ in
                        var p = Path()
                        p.move(to: CGPoint(x: w * 0.10, y: h * 0.22))
                        p.addLine(to: CGPoint(x: cx - wW * 0.1, y: cy + wH * 0.3))
                        p.addLine(to: CGPoint(x: w * 0.08, y: h * 0.80))
                        ctx.stroke(p, with: .color(GC.optYellow.opacity(0.6)),
                                   style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }
                    ZStack {
                        Circle().fill(GC.optYellow)
                            .frame(width: 20, height: 20)
                            .shadow(color: GC.optYellow.opacity(0.5), radius: 5)
                        Text("A")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.black)
                    }.position(x: w * 0.08, y: h * 0.80)

                    // Option B — 2 SL seitlich (nur rot)
                    ZStack {
                        Circle()
                            .stroke(GC.optRed.opacity(0.35),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            .frame(width: 52, height: 52)
                        Circle()
                            .fill(GC.optRed.opacity(0.12))
                            .frame(width: 52, height: 52)
                        ZStack {
                            Circle().fill(GC.optRed)
                                .frame(width: 20, height: 20)
                                .shadow(color: GC.optRed.opacity(0.5), radius: 5)
                            Text("B")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white)
                        }
                    }.position(x: w * 0.75, y: cy)

                    Text("2 SL")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(GC.optRed.opacity(0.8))
                        .position(x: w * 0.81, y: cy + 26)
                }

                // Legend
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Chip(text: "A – Hintere Linie (+1)", bg: GC.optYellow.opacity(0.18), fg: GC.optYellow)
                        Chip(text: "B – 2 SL seitlich, nur 🔴 (+1)", bg: GC.optRed.opacity(0.18), fg: GC.optRed)
                    }
                    .padding(.horizontal, 12).padding(.bottom, 10)
                }
            }
            .frame(height: 215)
        }
    }
}

// MARK: - 3. Bunker

struct BunkerDiagram: View {
    var body: some View {
        DiagramCard(title: "Bunker – Regeln & Erleichterungsoptionen",
                    icon: "circle.bottomhalf.filled") {
            VStack(spacing: 0) {
                // Illustration
                ZStack {
                    LinearGradient(
                        colors: [GC.grassDark, GC.rough.opacity(0.7)],
                        startPoint: .top, endPoint: .bottom)

                    GeometryReader { geo in
                        let w = geo.size.width, h = geo.size.height
                        let bx = w * 0.38, by = h * 0.18
                        let bW = w * 0.42, bH = h * 0.64

                        // Bunker shadow/depth
                        Ellipse()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: bW + 8, height: bH + 8)
                            .position(x: bx + bW/2, y: by + bH/2 + 3)

                        // Bunker sand body
                        Ellipse()
                            .fill(LinearGradient(
                                colors: [GC.sand, GC.sandDark],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: bW, height: bH)
                            .position(x: bx + bW/2, y: by + bH/2)

                        // Sand texture dots
                        Canvas { ctx, _ in
                            for i in 0..<20 {
                                let fx = CGFloat(i % 5) / 4.0
                                let fy = CGFloat(i / 5) / 3.0
                                let cx2 = bx + bW * (0.15 + fx * 0.7)
                                let cy2 = by + bH * (0.15 + fy * 0.7)
                                var dot = Path()
                                dot.addEllipse(in: CGRect(x: cx2-1.5, y: cy2-1.5, width: 3, height: 3))
                                ctx.fill(dot, with: .color(GC.sandDark.opacity(0.5)))
                            }
                        }

                        // BUNKER label
                        Text("BUNKER")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(GC.sandDark.opacity(0.7))
                            .position(x: bx + bW/2, y: by + bH * 0.82)

                        // Ball in bunker
                        Ball(size: 13).position(x: bx + bW/2, y: by + bH * 0.5)

                        // Club shaft (approaching)
                        Path { p in
                            p.move(to: CGPoint(x: w * 0.28, y: h * 0.05))
                            p.addLine(to: CGPoint(x: bx + bW * 0.35, y: by + bH * 0.45))
                        }
                        .stroke(Color.gray.opacity(0.85), lineWidth: 4)
                        .shadow(color: .black.opacity(0.3), radius: 2)

                        // Forbidden X
                        ZStack {
                            Circle()
                                .fill(GC.optRed.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Circle()
                                .stroke(GC.optRed, lineWidth: 1.5)
                                .frame(width: 28, height: 28)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(GC.optRed)
                        }
                        .position(x: w * 0.28, y: h * 0.20)

                        Chip(text: "Sand nicht berühren!",
                             bg: GC.optRed.opacity(0.20), fg: GC.optRed)
                            .position(x: w * 0.18, y: h * 0.06)
                    }
                }
                .frame(height: 120)

                // Options grid
                VStack(spacing: 0) {
                    Divider().overlay(Color.white.opacity(0.08))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
                        optionCell("1", "Schlag & Distanz", "+1", GC.optOrange)
                        optionCell("2", "Im Bunker, hintere Linie", "+1", GC.optYellow)
                        optionCell("3", "Im Bunker, seitlich 2 SL", "+1", GC.optYellow)
                        optionCell("4", "Außerhalb Bunker", "+2", GC.optRed)
                    }
                    .padding(10)
                }
                .background(Color.white.opacity(0.04))
            }
        }
    }

    private func optionCell(_ n: String, _ label: String,
                             _ cost: String, _ color: Color) -> some View {
        HStack(spacing: 7) {
            Text(n)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 18, height: 18)
                .background(color, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(cost)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
            }
            Spacer()
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 4. Unspielbar – 3 Optionen

struct UnplayableDiagram: View {
    var body: some View {
        DiagramCard(title: "Unspielbare Lage – 3 Optionen (je +1 Schlag)",
                    icon: "exclamationmark.triangle.fill") {
            ZStack {
                LinearGradient(
                    colors: [GC.rough.opacity(0.8), GC.grassDark],
                    startPoint: .topLeading, endPoint: .bottomTrailing)

                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    let ballPt  = CGPoint(x: w * 0.50, y: h * 0.50)
                    let holePt  = CGPoint(x: w * 0.50, y: h * 0.08)
                    let opt1Pt  = CGPoint(x: w * 0.50, y: h * 0.86)
                    let opt2Pt  = CGPoint(x: w * 0.13, y: h * 0.70)
                    let opt3Pt  = CGPoint(x: w * 0.84, y: h * 0.50)

                    // Hole-to-ball extension line (option 2 axis)
                    Canvas { ctx, _ in
                        var p = Path()
                        p.move(to: holePt)
                        p.addLine(to: CGPoint(x: w * 0.10, y: h * 0.92))
                        ctx.stroke(p, with: .color(GC.optYellow.opacity(0.3)),
                                   style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }

                    // 2-SL radius circle (option 3)
                    Circle()
                        .stroke(GC.optGreen.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .frame(width: 68, height: 68)
                        .position(x: ballPt.x, y: ballPt.y)

                    // Arrows
                    arrow(from: ballPt, to: opt1Pt, color: GC.optOrange.opacity(0.9), width: 2)
                    arrow(from: ballPt, to: opt2Pt, color: GC.optYellow.opacity(0.9), width: 2)
                    arrow(from: ballPt, to: opt3Pt, color: GC.optGreen.opacity(0.9), width: 2)

                    // Hole marker
                    ZStack {
                        Circle().fill(Color.black).frame(width: 10, height: 10)
                        Path { p in
                            p.move(to: holePt)
                            p.addLine(to: CGPoint(x: holePt.x, y: holePt.y - 24))
                        }.stroke(Color.white, lineWidth: 1.5)
                        FlagPath()
                            .fill(GC.flagRed)
                            .frame(width: 14, height: 10)
                            .position(x: holePt.x + 7, y: holePt.y - 20)
                    }.position(x: holePt.x, y: holePt.y)

                    // Ball (unplayable)
                    ZStack {
                        Circle()
                            .fill(GC.rough.opacity(0.8))
                            .frame(width: 22, height: 22)
                            .shadow(color: GC.optRed.opacity(0.5), radius: 6)
                        Ball(size: 14)
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .black))
                            .foregroundStyle(GC.optRed)
                            .offset(x: 6, y: -6)
                    }.position(x: ballPt.x, y: ballPt.y)

                    // Option badges
                    optBadgeView("1", "Schlag &\nDistanz", GC.optOrange)
                        .position(x: opt1Pt.x, y: opt1Pt.y + 18)

                    optBadgeView("2", "Hintere\nLinie", GC.optYellow)
                        .position(x: opt2Pt.x - 14, y: opt2Pt.y + 20)

                    optBadgeView("3", "2 SL\nseitlich", GC.optGreen)
                        .position(x: opt3Pt.x + 18, y: opt3Pt.y + 20)
                }
            }
            .frame(height: 220)
        }
    }

    private func optBadgeView(_ n: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(n)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 22, height: 22)
                .background(color, in: Circle())
                .shadow(color: color.opacity(0.5), radius: 4)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(color)
        }
    }
}

// MARK: - 5. Putting Green

struct PuttingGreenDiagram: View {
    var body: some View {
        DiagramCard(title: "Putting Green – Regeln auf einen Blick",
                    icon: "circle.fill") {
            ZStack {
                LinearGradient(
                    colors: [GC.grassDark, GC.bg],
                    startPoint: .topLeading, endPoint: .bottomTrailing)

                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    let cx = w * 0.38, cy = h * 0.50

                    // Green glow
                    Ellipse()
                        .fill(GC.grass.opacity(0.15))
                        .frame(width: w * 0.60 + 20, height: h * 0.72 + 20)
                        .position(x: cx, y: cy)
                        .blur(radius: 12)

                    // Green surface
                    Ellipse()
                        .fill(LinearGradient(
                            colors: [GC.grass.opacity(0.75), GC.grassDark.opacity(0.9)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: w * 0.60, height: h * 0.72)
                        .position(x: cx, y: cy)

                    // Mow lines (subtle)
                    Canvas { ctx, size in
                        for i in 0..<5 {
                            let y2 = cy - h * 0.28 + CGFloat(i) * (h * 0.56 / 4)
                            var p = Path()
                            p.move(to:    CGPoint(x: cx - w*0.27, y: y2))
                            p.addLine(to: CGPoint(x: cx + w*0.27, y: y2))
                            ctx.stroke(p, with: .color(.white.opacity(0.04)), lineWidth: 3)
                        }
                    }

                    // Hole
                    Circle()
                        .fill(Color.black)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black, radius: 4)
                        .position(x: cx, y: cy - h * 0.18)

                    // Flagstick
                    Path { p in
                        p.move(to:    CGPoint(x: cx, y: cy - h * 0.18))
                        p.addLine(to: CGPoint(x: cx, y: cy - h * 0.52))
                    }
                    .stroke(Color.white.opacity(0.85), lineWidth: 2)
                    .shadow(color: .black.opacity(0.4), radius: 2)

                    // Flag
                    FlagPath()
                        .fill(GC.flagRed)
                        .frame(width: 20, height: 14)
                        .shadow(color: .black.opacity(0.4), radius: 2)
                        .position(x: cx + 10, y: cy - h * 0.47)

                    // Ball
                    Ball(size: 12).position(x: cx - w * 0.14, y: cy + h * 0.12)

                    // Ball marker
                    Capsule()
                        .fill(Color(red:0.6, green:0.45, blue:0.15))
                        .frame(width: 14, height: 5)
                        .position(x: cx - w * 0.14, y: cy + h * 0.23)

                    // Pitch mark
                    Ellipse()
                        .stroke(Color(red:0.5, green:0.3, blue:0.1), lineWidth: 1.5)
                        .frame(width: 13, height: 8)
                        .position(x: cx + w * 0.08, y: cy + h * 0.05)

                    // Repair checkmark
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(GC.optGreen)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .position(x: cx + w * 0.16, y: cy + h * 0.03)
                }

                // Annotation panel
                VStack(alignment: .leading, spacing: 5) {
                    annotRow("⛳", "Fahne drin lassen – straflos",   GC.optGreen)
                    annotRow("⚪", "Ball markieren & reinigen",       .white.opacity(0.9))
                    annotRow("▬",  "Marker direkt hinter Ball",       Color(red:0.75,green:0.55,blue:0.2))
                    annotRow("✓",  "Pitchmarks reparieren",          GC.optGreen)
                    annotRow("✗",  "Normalen Verschleiß nicht",      GC.optRed)
                }
                .padding(10)
                .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 12)
                .padding(.bottom, 10)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 210)
        }
    }

    private func annotRow(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Text(icon).font(.system(size: 10)).frame(width: 14)
            Text(text).font(.system(size: 9)).foregroundStyle(color)
        }
    }
}

// MARK: - 6. Out of Bounds

struct OutOfBoundsDiagram: View {
    var body: some View {
        DiagramCard(title: "Außerhalb der Grenzen (AUS)",
                    icon: "xmark.circle.fill") {
            ZStack {
                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    let boundary = w * 0.60

                    // In-play side
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [GC.grass.opacity(0.4), GC.grassDark.opacity(0.7)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: boundary, height: h)
                        .position(x: boundary / 2, y: h / 2)

                    // OB side
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [GC.optRed.opacity(0.08), GC.optRed.opacity(0.18)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: w - boundary, height: h)
                        .position(x: boundary + (w - boundary) / 2, y: h / 2)

                    // Boundary line
                    Path { p in
                        p.move(to:    CGPoint(x: boundary, y: 0))
                        p.addLine(to: CGPoint(x: boundary, y: h))
                    }
                    .stroke(Color.white.opacity(0.7), lineWidth: 2)

                    // OB stakes along boundary
                    ForEach([0.12, 0.35, 0.58, 0.82], id: \.self) { frac in
                        VStack(spacing: 0) {
                            Triangle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 7, height: 5)
                            Rectangle()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 2.5, height: 18)
                        }.position(x: boundary, y: h * frac)
                    }

                    // "Im Spiel" label
                    Chip(text: "Im Spiel", bg: GC.optGreen.opacity(0.2), fg: GC.optGreen)
                        .position(x: boundary * 0.42, y: h * 0.10)

                    // "AUS" label
                    Chip(text: "AUS", bg: GC.optRed.opacity(0.25), fg: GC.optRed, icon: "xmark")
                        .position(x: boundary + (w - boundary) * 0.5, y: h * 0.10)

                    // Ball trajectory
                    Canvas { ctx, _ in
                        var p = Path()
                        p.move(to: CGPoint(x: w * 0.14, y: h * 0.65))
                        p.addQuadCurve(
                            to:      CGPoint(x: w * 0.80, y: h * 0.42),
                            control: CGPoint(x: w * 0.47, y: h * 0.07))
                        ctx.stroke(p, with: .color(.white.opacity(0.45)),
                                   style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }

                    // Abschlag ball
                    Ball(size: 11).position(x: w * 0.14, y: h * 0.65)
                    Text("Abschlag")
                        .font(.system(size: 8)).foregroundStyle(.white.opacity(0.55))
                        .position(x: w * 0.14, y: h * 0.76)

                    // OB ball
                    ZStack {
                        Circle().fill(GC.optRed.opacity(0.8))
                            .frame(width: 12, height: 12)
                            .shadow(color: GC.optRed.opacity(0.6), radius: 4)
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                    }.position(x: w * 0.80, y: h * 0.42)

                    // Return arrow
                    arrow(from: CGPoint(x: w * 0.46, y: h * 0.65),
                          to:   CGPoint(x: w * 0.18, y: h * 0.65),
                          color: GC.optOrange, width: 2)

                    // Penalty chip
                    Chip(text: "+1 → zurück zum Abschlag",
                         bg: GC.optOrange.opacity(0.2), fg: GC.optOrange)
                        .position(x: w * 0.32, y: h * 0.82)

                    // Stakes legend
                    Chip(text: "◻ Weiße Pfähle = Grenze", bg: .clear, fg: .white.opacity(0.45))
                        .position(x: boundary / 2, y: h * 0.93)
                }
            }
            .frame(height: 200)
        }
    }
}

// MARK: - 7. Drop-Verfahren

struct DropProcedureDiagram: View {
    var body: some View {
        DiagramCard(title: "Drop-Verfahren – Regel 14.3",
                    icon: "arrow.down.circle.fill") {
            HStack(spacing: 0) {
                // Visual illustration
                ZStack {
                    LinearGradient(
                        colors: [GC.grassDark, GC.rough.opacity(0.7)],
                        startPoint: .top, endPoint: .bottom)

                    GeometryReader { geo in
                        let w = geo.size.width, h = geo.size.height

                        // Relief zone circle
                        Circle()
                            .stroke(GC.optYellow.opacity(0.6),
                                    style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                            .frame(width: w * 0.55, height: w * 0.55)
                            .position(x: w * 0.50, y: h * 0.60)
                        Circle()
                            .fill(GC.optYellow.opacity(0.06))
                            .frame(width: w * 0.55, height: w * 0.55)
                            .position(x: w * 0.50, y: h * 0.60)

                        // Reference point
                        ZStack {
                            Circle().fill(GC.optOrange)
                                .frame(width: 10, height: 10)
                                .shadow(color: GC.optOrange.opacity(0.7), radius: 4)
                        }.position(x: w * 0.50, y: h * 0.60)
                        Text("Referenz")
                            .font(.system(size: 8))
                            .foregroundStyle(GC.optOrange.opacity(0.8))
                            .position(x: w * 0.50, y: h * 0.73)

                        // Drop arc
                        Canvas { ctx, _ in
                            var p = Path()
                            p.move(to: CGPoint(x: w * 0.50, y: h * 0.06))
                            p.addQuadCurve(
                                to: CGPoint(x: w * 0.35, y: h * 0.53),
                                control: CGPoint(x: w * 0.18, y: h * 0.22))
                            ctx.stroke(p, with: .color(.white.opacity(0.55)),
                                       style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        }

                        // Hand emoji
                        Text("✋")
                            .font(.system(size: 22))
                            .shadow(color: .black.opacity(0.4), radius: 3)
                            .position(x: w * 0.50, y: h * 0.08)

                        // Ball dropped
                        Ball(size: 11).position(x: w * 0.35, y: h * 0.53)

                        // Knee height annotation
                        Chip(text: "Kniehöhe", bg: .white.opacity(0.12), fg: .white.opacity(0.75))
                            .position(x: w * 0.50, y: h * 0.24)
                    }
                }
                .frame(width: 130)

                // Rules list
                VStack(alignment: .leading, spacing: 7) {
                    dropRule("checkmark.circle.fill", "Aus Kniehöhe loslassen",     GC.optGreen)
                    dropRule("checkmark.circle.fill", "Innerhalb der Zone landen",  GC.optGreen)
                    dropRule("checkmark.circle.fill", "Nicht näher zum Loch",       GC.optGreen)
                    Divider().overlay(Color.white.opacity(0.1)).padding(.vertical, 2)
                    dropRule("xmark.circle.fill",     "Nicht platzieren",           GC.optRed)
                    dropRule("xmark.circle.fill",     "Außerhalb Zone → neu droppen", GC.optRed)
                    dropRule("arrow.clockwise",       "3. Versuch → platzieren",    GC.optYellow)
                }
                .padding(12)
                .frame(maxHeight: .infinity)
                .background(Color.white.opacity(0.03))
            }
            .frame(height: 200)
        }
    }

    private func dropRule(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .frame(width: 14)
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 8. Ball-Suche / 3 Minuten

struct BallSearchDiagram: View {
    var body: some View {
        DiagramCard(title: "Suchzeit – max. 3 Minuten (Regel 18.2)",
                    icon: "timer") {
            VStack(spacing: 12) {
                // Timeline bar
                GeometryReader { geo in
                    let w = geo.size.width
                    let barH: CGFloat = 22

                    // Background track
                    RoundedRectangle(cornerRadius: barH / 2)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: barH)

                    // Gradient fill
                    RoundedRectangle(cornerRadius: barH / 2)
                        .fill(LinearGradient(
                            colors: [GC.optGreen, GC.optYellow, GC.optOrange, GC.optRed],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(height: barH)

                    // Minute tick marks
                    ForEach(0...3, id: \.self) { min in
                        let x = w * CGFloat(min) / 3
                        Path { p in
                            p.move(to:    CGPoint(x: x, y: -6))
                            p.addLine(to: CGPoint(x: x, y: barH + 6))
                        }
                        .stroke(GC.bg.opacity(0.6), lineWidth: 1.5)

                        Text("\(min) min")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .position(x: x, y: barH + 18)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, 14)
                .padding(.top, 10)

                // Events
                HStack(spacing: 0) {
                    eventChip("Suche beginnt", GC.optGreen, "play.fill")
                    Spacer()
                    eventChip("VERLOREN", GC.optRed, "xmark.circle.fill")
                }
                .padding(.horizontal, 14)

                Divider().overlay(Color.white.opacity(0.08)).padding(.horizontal, 14)

                // Steps
                VStack(alignment: .leading, spacing: 6) {
                    stepRow("1", "Provisorischen Ball spielen (vor der Suche!)", GC.optGreen)
                    stepRow("2", "Max. 3 Minuten suchen", GC.optYellow)
                    stepRow("3", "Nicht gefunden → Provisorischer Ball gilt (+1)", GC.optOrange)
                    stepRow("⚠", "Kein prov. Ball? → Zurück zum Abschlag (+1)", GC.optRed)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
    }

    private func eventChip(_ text: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold)).foregroundStyle(color)
            Text(text).font(.system(size: 9, weight: .bold)).foregroundStyle(color)
        }
    }

    private func stepRow(_ n: String, _ text: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(n)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 18, height: 18)
                .background(color, in: Circle())
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 9. Scoring-Tabelle

struct ScoringTableDiagram: View {
    private let rows: [(String, String, Int, Color)] = [
        ("Condor / Albatross", "−4 / −3", 5, Color(red: 0.70, green: 0.20, blue: 0.80)),
        ("Eagle",              "−2",      4, Color(red: 0.90, green: 0.65, blue: 0.00)),
        ("Birdie",             "−1",      3, Color(red: 0.12, green: 0.80, blue: 0.28)),
        ("Par",                " 0",      2, Color(red: 0.25, green: 0.55, blue: 0.95)),
        ("Bogey",              "+1",      1, Color(red: 0.95, green: 0.60, blue: 0.10)),
        ("Double Bogey",       "+2",      0, Color(red: 0.88, green: 0.25, blue: 0.20)),
        ("Triple+ Bogey",      "+3+",     0, Color(red: 0.55, green: 0.08, blue: 0.08)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Text("Bezeichnung")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("vs. Par")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(width: 52, alignment: .center)
                Text("Stableford")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))

            ForEach(rows, id: \.0) { name, par, pts, color in
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 9, height: 9)
                            .shadow(color: color.opacity(0.6), radius: 3)
                        Text(name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(par)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(color)
                        .frame(width: 52, alignment: .center)
                        .monospacedDigit()

                    stablefordBadge(pts, color)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(color.opacity(0.07))

                if name != rows.last?.0 {
                    Divider()
                        .overlay(Color.white.opacity(0.06))
                }
            }
        }
        .background(GC.bg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    private func stablefordBadge(_ pts: Int, _ color: Color) -> some View {
        Group {
            if pts == 0 {
                Text("0 Pkt.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.28))
            } else {
                HStack(spacing: 3) {
                    ForEach(0..<min(pts, 4), id: \.self) { _ in
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                    }
                    Text("\(pts) Pkt.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(color)
                }
            }
        }
    }
}

// MARK: - 10. Matchplay

struct MatchplayDiagram: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(GC.optGreen)
                Text("Matchplay – Lochspiel-Wertung")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))

            // Scoreboard
            HStack(spacing: 0) {
                // Player A
                VStack(spacing: 6) {
                    Chip(text: "Spieler A", bg: GC.optGreen.opacity(0.2), fg: GC.optGreen)
                    Text("3")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(GC.optGreen)
                        .shadow(color: GC.optGreen.opacity(0.4), radius: 8)
                    Text("gewonnene Löcher")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(GC.optGreen.opacity(0.06))

                // Center result
                VStack(spacing: 10) {
                    Text("VS")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.3))

                    VStack(spacing: 4) {
                        Text("2 up")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(GC.optGreen)
                            .shadow(color: GC.optGreen.opacity(0.4), radius: 6)
                        Text("Führung A")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(GC.optGreen.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

                    Chip(text: "noch 4 Löcher",
                         bg: .white.opacity(0.08), fg: .white.opacity(0.55))
                }
                .frame(width: 110)
                .padding(.vertical, 18)

                // Player B
                VStack(spacing: 6) {
                    Chip(text: "Spieler B", bg: GC.optOrange.opacity(0.2), fg: GC.optOrange)
                    Text("1")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(GC.optOrange)
                        .shadow(color: GC.optOrange.opacity(0.4), radius: 8)
                    Text("gewonnene Löcher")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(GC.optOrange.opacity(0.05))
            }

            // Result format legend
            Divider().overlay(Color.white.opacity(0.06))
            HStack(spacing: 12) {
                resultHint("2 up", "Vorsprung 2 Löcher", GC.optGreen)
                resultHint("3&2", "3 Löcher Vorsp., 2 zu spielen → Sieg", GC.optOrange)
                resultHint("A.S.", "All Square = Gleichstand", .white.opacity(0.5))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.white.opacity(0.03))
        }
        .background(GC.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    private func resultHint(_ code: String, _ desc: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(code)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(color)
            Text(desc)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
