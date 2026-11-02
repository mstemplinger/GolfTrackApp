import SwiftUI

// MARK: - Griff entspannen

/// Druckanzeige 1–10: Zeiger springt von „zu fest“ in den lockeren Bereich.
struct GripVisual: View {
    let color: Color
    private let red = Color(red: 0.92, green: 0.32, blue: 0.28)

    var body: some View {
        TimelineView(.animation) { tl in
            let s = Loop.step(Loop.seconds(tl.date), count: 2, hold: 2.2, move: 1.1)
            let value = Loop.value([9, 4.5], s)
            TipVisualCard(height: 200) {
                GeometryReader { geo in
                    let c = CGPoint(x: geo.size.width / 2, y: geo.size.height - 44)
                    Canvas { ctx, _ in
                        let r: CGFloat = 100
                        func angle(_ v: Double) -> Angle { .degrees(180 + (v - 1) / 9 * 180) }
                        func arc(_ a: Double, _ b: Double, _ col: Color) {
                            var p = Path()
                            p.addArc(center: c, radius: r, startAngle: angle(a), endAngle: angle(b), clockwise: false)
                            ctx.stroke(p, with: .color(col), style: StrokeStyle(lineWidth: 14, lineCap: .butt))
                        }
                        arc(1, 3.2, Color.white.opacity(0.18))
                        arc(3.3, 6.2, color)
                        arc(6.3, 10, red.opacity(0.8))
                        for v in 1...10 {
                            let a = angle(Double(v)).radians
                            let p1 = CGPoint(x: c.x + cos(a) * (r - 13), y: c.y + sin(a) * (r - 13))
                            let p2 = CGPoint(x: c.x + cos(a) * (r - 19), y: c.y + sin(a) * (r - 19))
                            ctx.line([p1, p2], Color.white.opacity(0.35), 1.5)
                        }
                        let a = angle(value).radians
                        let tip = CGPoint(x: c.x + cos(a) * (r - 8), y: c.y + sin(a) * (r - 8))
                        ctx.line([c, tip], .white, 3.5)
                        ctx.circle(c, 8, .white)
                        ctx.circle(c, 3.5, AppTheme.bg)
                    }
                    Image(systemName: "bird.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                        .position(x: c.x, y: c.y - 140)
                    Text("locker").font(.caption2).foregroundStyle(AppTheme.textTer)
                        .position(x: c.x - 100, y: c.y + 18)
                    Text("fest").font(.caption2).foregroundStyle(AppTheme.textTer)
                        .position(x: c.x + 100, y: c.y + 18)
                    Text("Griffdruck \(Int(value.rounded())) / 10")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(AppTheme.text)
                        .position(x: c.x, y: c.y + 26)
                }
            } footer: {
                TipHint(text: s.shown == 0 ? "Zu fest: Handgelenke blockieren, Distanz geht verloren"
                                           : "Wie einen Vogel halten – fest genug, aber locker",
                        color: s.shown == 0 ? red : color)
            }
        }
    }
}

// MARK: - Standfläche prüfen

/// Draufsicht: Fußabstand und Ballposition je nach Schläger.
struct StanceVisual: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { tl in
            let s = Loop.step(Loop.seconds(tl.date), count: 3, hold: 2.0, move: 0.9)
            let half = Loop.value([30, 42, 56], s)        // halber Fußabstand
            let ballX = Loop.value([0, 10, 38], s)        // Ball relativ zur Mitte
            TipVisualCard(height: 210) {
                Canvas { ctx, size in
                    let cx = size.width / 2
                    let shoulderY: CGFloat = 58, feetY: CGFloat = 112, ballY: CGFloat = 168
                    let shoulder: CGFloat = 42

                    // Schulterbreite als Hilfslinien
                    for dx in [-shoulder, shoulder] {
                        ctx.line([CGPoint(x: cx + dx, y: shoulderY), CGPoint(x: cx + dx, y: ballY + 18)],
                                 Color.white.opacity(0.25), 1, dash: [3, 4])
                    }
                    // Oberkörper von oben: Schultern und Kopf
                    ctx.line([CGPoint(x: cx - shoulder, y: shoulderY), CGPoint(x: cx + shoulder, y: shoulderY)],
                             Color(white: 0.96), 16)
                    ctx.circle(CGPoint(x: cx, y: shoulderY + 2), 13, color)

                    // Füße, Spitzen leicht nach außen
                    for side in [-1.0, 1.0] {
                        let c = CGPoint(x: cx + side * half, y: feetY)
                        var foot = Path()
                        foot.addRoundedRect(in: CGRect(x: -8, y: -17, width: 16, height: 34),
                                            cornerSize: CGSize(width: 8, height: 8))
                        let tf = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: -side * 0.2)
                        ctx.fill(foot.applying(tf), with: .color(.white))
                    }
                    // Maß zwischen den Füßen
                    let my = feetY + 30
                    ctx.line([CGPoint(x: cx - half, y: my), CGPoint(x: cx + half, y: my)], color, 1.5)
                    for side in [-1.0, 1.0] {
                        ctx.line([CGPoint(x: cx + side * half, y: my - 5), CGPoint(x: cx + side * half, y: my + 5)], color, 1.5)
                    }
                    // Schläger und Ball
                    let ball = CGPoint(x: cx + ballX, y: ballY)
                    ctx.line([CGPoint(x: cx, y: shoulderY + 22), CGPoint(x: ball.x - 4, y: ball.y - 8)],
                             Color(white: 0.75), 2.2)
                    ctx.ball(ball, 5)

                    ctx.label(Text("Ziel →").font(.caption2.bold()).foregroundStyle(AppTheme.textTer),
                              at: CGPoint(x: size.width - 30, y: 16))
                }
            } footer: {
                VStack(spacing: 10) {
                    TipHint(text: ["Etwas enger, Ball in der Mitte",
                                   "Schulterbreit, Ball leicht vorne",
                                   "Breiter, Ball an der vorderen Ferse"][s.shown], color: color)
                    PhasePills(labels: ["Kurzes Eisen", "Mittleres Eisen", "Holz / Driver"],
                               active: s.shown, color: color)
                }
            }
        }
    }
}

// MARK: - Auge auf dem Ball

/// Schwung mit Blicklinie: Kopf bleibt ruhig, der Blick bleibt auch nach dem Treffer am Punkt.
struct EyeOnBallVisual: View {
    let color: Color
    private let frames: [(Double, GolferPose)] = [
        (0, .address), (0.8, .address), (2.0, .top), (2.5, .finished),
        (3.7, .finished), (4.6, .address), (5.0, .address),
    ]

    var body: some View {
        TimelineView(.animation) { tl in
            let x = Loop.local(Loop.seconds(tl.date), period: 5.0)
            let pose = GolferPose.keyframes(frames, at: x).steady(0.25)
            let hit = x > 2.25 && x < 4.5
            TipVisualCard(height: 240) {
                GeometryReader { geo in
                    let center = geo.size.width / 2
                    let ground = geo.size.height - 30
                    let j = GolferJoints(pose: pose, center: center, ground: ground)
                    let ball = CGPoint(x: center, y: ground - 4.5)
                    // Blick hängt nach dem Treffer noch kurz am Punkt, dann geht der Kopf mit
                    let gaze = 1 - Loop.ramp(x, 2.9, 3.3)
                    ZStack {
                        Canvas { ctx, size in
                            ctx.line([CGPoint(x: 12, y: ground), CGPoint(x: size.width - 12, y: ground)],
                                     Color.white.opacity(0.25), 1)
                            // Kopfhöhe als Referenz
                            let headY = GolferJoints(pose: .address, center: center, ground: ground).head.y
                            ctx.line([CGPoint(x: center - 70, y: headY - 12), CGPoint(x: center + 70, y: headY - 12)],
                                     Color.white.opacity(0.18), 1, dash: [4, 4])
                        }
                        GolferFigure(pose: pose, center: center, ground: ground, accent: color)
                        Canvas { ctx, _ in
                            if !hit { ctx.ball(ball) }
                            let eye = CGPoint(x: j.head.x + 4, y: j.head.y + 4)
                            ctx.line([eye, ball], color.opacity(gaze), 2.2, dash: [3, 4])
                            ctx.ring(ball, 9 + 2 * sin(x * 6), color.opacity(gaze), 1.6)
                        }
                    }
                }
            } footer: {
                TipHint(text: hit ? "Kopf unten lassen, bis der Ball weg ist"
                                  : "Einen Punkt am Ball fixieren", color: color)
            }
        }
    }
}

// MARK: - Tempo ist alles

/// Rückschwung dreimal so lang wie der Durchschwung, mit Taktpunkten.
struct TempoVisual: View {
    let color: Color
    private let frames: [(Double, GolferPose)] = [
        (0, .address), (0.4, .address), (1.9, .top), (2.4, .finished),
        (3.5, .finished), (4.4, .address), (4.8, .address),
    ]

    var body: some View {
        TimelineView(.animation) { tl in
            let x = Loop.local(Loop.seconds(tl.date), period: 4.8)
            let pose = GolferPose.keyframes(frames, at: x)
            let beats = [0.9, 1.4, 1.9, 2.15]
            TipVisualCard(height: 240) {
                GeometryReader { geo in
                    let center = geo.size.width / 2
                    let ground = geo.size.height - 30
                    ZStack {
                        Canvas { ctx, size in
                            ctx.line([CGPoint(x: 12, y: ground), CGPoint(x: size.width - 12, y: ground)],
                                     Color.white.opacity(0.25), 1)
                        }
                        GolferFigure(pose: pose, center: center, ground: ground, accent: color)
                        Canvas { ctx, _ in
                            if !(x > 2.15 && x < 4.4) { ctx.ball(CGPoint(x: center, y: ground - 4.5)) }
                        }
                        Text("3 : 1")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(color.opacity(0.85))
                            .position(x: 40, y: 30)
                    }
                }
            } footer: {
                HStack(spacing: 0) {
                    ForEach(beats.indices, id: \.self) { i in
                        let on = x >= beats[i] && x < 4.0
                        VStack(spacing: 5) {
                            Circle()
                                .fill(on ? color : Color.white.opacity(0.12))
                                .frame(width: i == 3 ? 16 : 12, height: i == 3 ? 16 : 12)
                                .scaleEffect(on && x - beats[i] < 0.15 ? 1.3 : 1)
                            Text(["eins", "zwei", "drei", "Schlag"][i])
                                .font(.caption2.bold())
                                .foregroundStyle(on ? AppTheme.text : AppTheme.textTer)
                        }
                        .frame(maxWidth: .infinity)
                        if i == 2 {
                            Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 28)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Chip-Technik

/// Kurze Pendelbewegung aus den Schultern, Dreieck bleibt fest, Ball rollt aus.
struct ChipVisual: View {
    let color: Color
    private static let base    = GolferPose(hipShift: 6, arm: 90, club: 90, finish: 0)
    private static let back    = GolferPose(hipShift: 6, arm: 120, club: 114, finish: 0)
    private static let through = GolferPose(hipShift: 7, arm: 62, club: 64, finish: 0)
    private let frames: [(Double, GolferPose)] = [
        (0, base), (0.5, base), (1.3, back), (1.75, through), (2.9, through), (3.6, base), (4.0, base),
    ]

    var body: some View {
        TimelineView(.animation) { tl in
            let x = Loop.local(Loop.seconds(tl.date), period: 4.0)
            let pose = GolferPose.keyframes(frames, at: x)
            TipVisualCard(height: 240) {
                GeometryReader { geo in
                    let center = geo.size.width / 2 - 30
                    let ground = geo.size.height - 30
                    let j = GolferJoints(pose: pose, center: center, ground: ground)
                    ZStack {
                        Canvas { ctx, size in
                            ctx.line([CGPoint(x: 12, y: ground), CGPoint(x: size.width - 12, y: ground)],
                                     Color.white.opacity(0.25), 1)
                            ctx.flag(CGPoint(x: size.width - 34, y: ground), color, height: 40)
                        }
                        GolferFigure(pose: pose, center: center, ground: ground, accent: color)
                        Canvas { ctx, size in
                            // Dreieck Schultern–Hände
                            var tri = Path()
                            tri.addLines([j.trailShoulder, j.leadShoulder, j.hands])
                            tri.closeSubpath()
                            ctx.fill(tri, with: .color(color.opacity(0.18)))
                            ctx.stroke(tri, with: .color(color), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

                            // Ball: kurzer Flug, dann Rollen
                            let start = CGPoint(x: center, y: ground - 4.5)
                            let end = CGPoint(x: size.width - 48, y: ground - 4.5)
                            let land = CGPoint(x: center + (end.x - center) * 0.35, y: start.y)
                            var ball = start
                            if x > 1.52 && x < 3.4 {
                                let fly = Loop.ramp(x, 1.52, 1.95)
                                if fly < 1 {
                                    ball = quadPoint(start, CGPoint(x: (start.x + land.x) / 2, y: start.y - 34), land, fly)
                                } else {
                                    let roll = 1 - pow(1 - min((x - 1.95) / 1.0, 1), 2)
                                    ball = CGPoint(x: land.x + (end.x - land.x) * roll, y: start.y)
                                }
                            }
                            if x < 3.4 { ctx.ball(ball) }
                        }
                        Text("60 % vorne")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.textSec)
                            .position(x: center + 46, y: ground + 16)
                    }
                }
            } footer: {
                TipHint(text: "Pendel aus den Schultern – das Dreieck bleibt fest", color: color)
            }
        }
    }
}
