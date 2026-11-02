import SwiftUI

// MARK: - Schwungachse halten

/// Schwung um eine feste Achse durch Kopf und Hüfte.
struct SpineAxisVisual: View {
    let color: Color
    private let frames: [(Double, GolferPose)] = [
        (0, .address), (0.7, .address), (1.9, .top), (2.4, .finished),
        (3.5, .finished), (4.4, .address), (4.8, .address),
    ]

    var body: some View {
        TimelineView(.animation) { tl in
            let x = Loop.local(Loop.seconds(tl.date), period: 4.8)
            let pose = GolferPose.keyframes(frames, at: x).steady(0.15)
            TipVisualCard(height: 240) {
                GeometryReader { geo in
                    let center = geo.size.width / 2
                    let ground = geo.size.height - 30
                    let a = GolferJoints(pose: .address, center: center, ground: ground)
                    ZStack {
                        Canvas { ctx, size in
                            ctx.line([CGPoint(x: 12, y: ground), CGPoint(x: size.width - 12, y: ground)],
                                     Color.white.opacity(0.25), 1)
                        }
                        GolferFigure(pose: pose, center: center, ground: ground, accent: color)
                        Canvas { ctx, _ in
                            let top = CGPoint(x: center, y: a.head.y - 26)
                            let bottom = CGPoint(x: center, y: a.trailHip.y + 14)
                            ctx.line([top, bottom], color, 2, dash: [6, 4])
                            // Drehpfeil um die Achse auf Brusthöhe
                            let y = a.trailShoulder.y + 22
                            let sweep = Loop.ramp(x, 0.7, 1.9) - Loop.ramp(x, 1.9, 2.4) * 2
                            var arc = Path()
                            arc.addEllipse(in: CGRect(x: center - 34, y: y - 7, width: 68, height: 14))
                            ctx.stroke(arc, with: .color(color.opacity(0.35)), lineWidth: 1.5)
                            let t = Double.pi / 2 + sweep * Double.pi
                            ctx.circle(CGPoint(x: center + cos(t) * 34, y: y + sin(t) * 7), 4, color)
                            ctx.circle(top, 4, color)
                            ctx.circle(bottom, 4, color)
                        }
                        Text("Achse")
                            .font(.caption2.bold())
                            .foregroundStyle(color)
                            .position(x: center + 52, y: a.trailHip.y + 14)
                    }
                }
            } footer: {
                TipHint(text: "In der Vorbeuge bleiben – die Schultern drehen um die Achse", color: color)
            }
        }
    }
}

// MARK: - Hüftrotation

/// Draufsicht: Hüfte (dunkel) startet den Durchschwung, Schultern (hell) folgen.
struct HipRotationVisual: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { tl in
            let s = Loop.step(Loop.seconds(tl.date), count: 4, hold: 1.1, move: 0.7)
            let hip = Loop.value([-45, -15, 35, 80], s)
            let shoulder = Loop.value([-90, -80, 10, 100], s)
            TipVisualCard(height: 210) {
                Canvas { ctx, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2 - 6)
                    func bar(_ angle: Double, _ length: CGFloat, _ col: Color, _ width: CGFloat) {
                        let r = angle * .pi / 180
                        let dx = cos(r) * length / 2, dy = sin(r) * length / 2
                        ctx.line([CGPoint(x: c.x - dx, y: c.y - dy), CGPoint(x: c.x + dx, y: c.y + dy)], col, width)
                    }
                    // Ausgangsstellung parallel zur Ziellinie
                    ctx.line([CGPoint(x: c.x - 70, y: c.y), CGPoint(x: c.x + 70, y: c.y)],
                             Color.white.opacity(0.2), 1, dash: [4, 4])
                    bar(shoulder, 112, Color(white: 0.96), 16)
                    bar(hip, 70, Color(red: 0.30, green: 0.34, blue: 0.42), 18)
                    ctx.circle(c, 14, color)
                    // Ball vor dem Golfer
                    ctx.ball(CGPoint(x: c.x, y: c.y + 70), 5)
                    ctx.label(Text("Ziel →").font(.caption2.bold()).foregroundStyle(AppTheme.textTer),
                              at: CGPoint(x: size.width - 30, y: 16))
                    ctx.label(Text("Draufsicht").font(.caption2).foregroundStyle(AppTheme.textTer),
                              at: CGPoint(x: 40, y: 16))
                }
                .overlay(alignment: .bottom) {
                    HStack(spacing: 14) {
                        legend(Color(white: 0.96), "Schultern \(Int(abs(shoulder).rounded()))°")
                        legend(Color(red: 0.42, green: 0.47, blue: 0.56), "Hüfte \(Int(abs(hip).rounded()))°")
                    }
                    .padding(.bottom, 10)
                }
            } footer: {
                VStack(spacing: 10) {
                    TipHint(text: ["Ausholen: Schultern drehen weiter als die Hüfte",
                                   "Die Hüfte dreht zuerst zum Ziel",
                                   "Arme und Schultern folgen von selbst",
                                   "Hüfte und Brust zeigen zum Ziel"][s.shown], color: color)
                    PhasePills(labels: ["Ausholen", "Hüfte startet", "Treffen", "Finish"],
                               active: s.shown, color: color)
                }
            }
        }
    }

    private func legend(_ c: Color, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Capsule().fill(c).frame(width: 14, height: 6)
            Text(text).font(.caption2.bold().monospacedDigit()).foregroundStyle(AppTheme.textSec)
        }
    }
}

// MARK: - Flaches Anspiel

/// Draufsicht: Der Golfer steht oben, „innen“ ist seine Körperseite der Ziellinie.
/// Abwechselnd die Bahn von innen nach außen (Draw) und von außen nach innen (Slice).
struct SwingPathVisual: View {
    let color: Color
    private let red = Color(red: 0.92, green: 0.32, blue: 0.28)

    var body: some View {
        TimelineView(.animation) { tl in
            let period = 4.2
            let t = Loop.seconds(tl.date)
            let good = Int(t / period) % 2 == 0
            let x = Loop.local(t, period: period)
            let col = good ? color : red
            TipVisualCard(height: 230) {
                Canvas { ctx, size in
                    let lineY: CGFloat = 132
                    let ball = CGPoint(x: 122, y: lineY)
                    let flag = CGPoint(x: size.width - 34, y: lineY)

                    // Seiten der Ziellinie
                    ctx.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: lineY)), with: .color(.white.opacity(0.05)))
                    ctx.label(Text("innen").font(.caption.bold()).foregroundStyle(AppTheme.textSec),
                              at: CGPoint(x: 14, y: lineY - 14), anchor: .leading)
                    ctx.label(Text("außen").font(.caption.bold()).foregroundStyle(AppTheme.textSec),
                              at: CGPoint(x: 14, y: lineY + 16), anchor: .leading)

                    // Golfer von oben: Schultern und Kappe, Blick zum Ball
                    let body = CGPoint(x: ball.x, y: 40)
                    ctx.line([CGPoint(x: body.x - 34, y: body.y), CGPoint(x: body.x + 34, y: body.y)], Color(white: 0.96), 16)
                    ctx.circle(body, 12, color)
                    ctx.line([CGPoint(x: body.x - 12, y: body.y + 9), CGPoint(x: body.x + 12, y: body.y + 9)], color, 3)
                    ctx.label(Text("Du").font(.caption2).foregroundStyle(AppTheme.textTer),
                              at: CGPoint(x: body.x + 44, y: body.y), anchor: .leading)

                    // Ziellinie zur Fahne
                    ctx.line([CGPoint(x: 64, y: lineY), CGPoint(x: size.width - 20, y: lineY)],
                             Color.white.opacity(0.35), 1.2, dash: [5, 5])
                    ctx.circle(flag, 10, AppTheme.green.opacity(0.9))
                    ctx.flag(flag, color, height: 26)
                    ctx.label(Text("Ziellinie").font(.caption2).foregroundStyle(AppTheme.textTer),
                              at: CGPoint(x: (ball.x + flag.x) / 2, y: lineY - 9))

                    // Schlägerbahn mit Pfeil
                    let from = good ? CGPoint(x: ball.x - 62, y: lineY - 44) : CGPoint(x: ball.x - 62, y: lineY + 44)
                    let to = good ? CGPoint(x: ball.x + 62, y: lineY + 44) : CGPoint(x: ball.x + 62, y: lineY - 44)
                    ctx.line([from, to], col.opacity(0.4), 2, dash: [4, 4])
                    let ang = atan2(to.y - from.y, to.x - from.x)
                    for d in [-0.5, 0.5] {
                        ctx.line([to, CGPoint(x: to.x - 11 * cos(ang + d), y: to.y - 11 * sin(ang + d))], col.opacity(0.6), 2)
                    }
                    let swing = Loop.ramp(x, 0.3, 1.2)
                    let head = CGPoint(x: from.x + (to.x - from.x) * swing, y: from.y + (to.y - from.y) * swing)
                    if x > 0.3 { ctx.line([from, head], col, 3.5) }
                    if swing > 0 && swing < 1 {
                        var club = Path()
                        club.addRoundedRect(in: CGRect(x: -4, y: -11, width: 8, height: 22), cornerSize: CGSize(width: 3, height: 3))
                        ctx.fill(club.applying(CGAffineTransform(translationX: head.x, y: head.y)),
                                 with: .color(Color(white: 0.88)))
                    }

                    // Ballflug: Draw zurück zur Fahne bzw. Slice weg
                    let fly = Loop.ramp(x, 0.8, 2.6)
                    let end = good ? flag : CGPoint(x: flag.x - 24, y: lineY + 70)
                    let control = good ? CGPoint(x: (ball.x + flag.x) / 2, y: lineY + 58)
                                       : CGPoint(x: (ball.x + flag.x) / 2, y: lineY - 58)
                    if x > 0.8 {
                        ctx.stroke(quadPath(ball, control, end, upTo: fly), with: .color(col),
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                    ctx.ball(x > 0.8 ? quadPoint(ball, control, end, fly) : ball, 5)
                    if x > 2.6 {
                        ctx.label(Text(good ? "Draw" : "Slice").font(.caption.bold()).foregroundStyle(col),
                                  at: CGPoint(x: end.x - 6, y: end.y + (good ? 22 : -14)), anchor: .trailing)
                    }
                }
            } footer: {
                VStack(spacing: 10) {
                    TipHint(text: good ? "Richtig: Schläger kommt von innen und schwingt nach außen durch"
                                       : "Falsch: Schläger kommt von außen quer über den Ball",
                            color: col)
                    PhasePills(labels: ["Von innen (Inside-Out)", "Von außen (Over the Top)"],
                               active: good ? 0 : 1, color: col)
                }
            }
        }
    }
}

// MARK: - Trefferfläche kontrollieren

/// Schlagfläche mit Treffermarken und der Distanz, die jeder Treffer bringt.
struct ImpactVisual: View {
    let color: Color
    private let hits: [(CGPoint, Int, LocalizedStringKey)] = [
        (CGPoint(x: 0, y: 2), 100, "Mitte"),
        (CGPoint(x: 34, y: -4), 88, "Spitze"),
        (CGPoint(x: -3, y: -6), 98, "fast Mitte"),
        (CGPoint(x: -36, y: 6), 86, "Ferse"),
        (CGPoint(x: 4, y: 4), 100, "Mitte"),
    ]

    var body: some View {
        TimelineView(.animation) { tl in
            let slot = 1.5
            let x = Loop.local(Loop.seconds(tl.date), period: slot * Double(hits.count))
            let current = Int(x / slot)
            let pop = Loop.ramp(x - Double(current) * slot, 0, 0.25)
            let hit = hits[current]
            TipVisualCard(height: 200) {
                Canvas { ctx, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2 - 4)
                    // Eisen-Schlagfläche
                    var face = Path()
                    face.move(to: CGPoint(x: c.x - 92, y: c.y - 22))
                    face.addQuadCurve(to: CGPoint(x: c.x + 96, y: c.y - 44), control: CGPoint(x: c.x, y: c.y - 40))
                    face.addQuadCurve(to: CGPoint(x: c.x + 86, y: c.y + 40), control: CGPoint(x: c.x + 112, y: c.y + 20))
                    face.addLine(to: CGPoint(x: c.x - 88, y: c.y + 38))
                    face.addQuadCurve(to: CGPoint(x: c.x - 92, y: c.y - 22), control: CGPoint(x: c.x - 100, y: c.y + 10))
                    ctx.fill(face, with: .linearGradient(Gradient(colors: [Color(white: 0.86), Color(white: 0.62)]),
                                                         startPoint: CGPoint(x: c.x, y: c.y - 44),
                                                         endPoint: CGPoint(x: c.x, y: c.y + 40)))
                    // Schaft
                    ctx.line([CGPoint(x: c.x - 92, y: c.y - 20), CGPoint(x: c.x - 120, y: c.y - 92)], Color(white: 0.7), 6)
                    // Rillen
                    for i in 0..<6 {
                        let y = c.y - 22 + CGFloat(i) * 10
                        ctx.line([CGPoint(x: c.x - 70, y: y), CGPoint(x: c.x + 76, y: y - 3)], Color.black.opacity(0.18), 1.2)
                    }
                    // Sweetspot
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 26, y: c.y - 20, width: 52, height: 40)),
                             with: .radialGradient(Gradient(colors: [color.opacity(0.55), color.opacity(0)]),
                                                   center: c, startRadius: 0, endRadius: 26))
                    // Treffer bis jetzt
                    for i in 0...current {
                        let p = CGPoint(x: c.x + hits[i].0.x, y: c.y + hits[i].0.y)
                        let isNow = i == current
                        let r: CGFloat = isNow ? 4 + 5 * (1 - pop) + 2 : 4
                        ctx.circle(p, r, isNow ? AppTheme.bg : AppTheme.bg.opacity(0.35))
                        if isNow { ctx.ring(p, 10 + 10 * pop, color.opacity(1 - pop), 2) }
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(hit.2).font(.caption.bold()).foregroundStyle(AppTheme.text)
                        Spacer()
                        Text("\(hit.1) % Distanz")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(hit.1 >= 98 ? color : Color(red: 0.92, green: 0.32, blue: 0.28))
                    }
                    GeometryReader { g in
                        let f = CGFloat(hit.1 - 75) / 25
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule().fill(hit.1 >= 98 ? color : Color(red: 0.92, green: 0.32, blue: 0.28))
                                .frame(width: g.size.width * f)
                        }
                    }
                    .frame(height: 8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: current)
                    Text("Außerhalb der Mitte gehen 10–15 % Länge verloren")
                        .font(.caption2).foregroundStyle(AppTheme.textTer)
                }
            }
        }
    }
}
