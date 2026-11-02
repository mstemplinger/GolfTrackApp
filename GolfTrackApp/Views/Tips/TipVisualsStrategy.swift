import SwiftUI

private let hazardRed = Color(red: 0.92, green: 0.32, blue: 0.28)
private let water = Color(red: 0.12, green: 0.42, blue: 0.78)
private let sand = Color(red: 0.87, green: 0.78, blue: 0.56)

// MARK: - Course Management

/// Streuung der Schläge: auf die Fahne neben dem Wasser gegen auf die Grünmitte.
struct CourseManagementVisual: View {
    let color: Color
    private let spread: [CGPoint] = [
        CGPoint(x: 0, y: 0), CGPoint(x: 0.85, y: 0.3), CGPoint(x: -0.6, y: -0.55), CGPoint(x: 0.45, y: -0.9),
        CGPoint(x: -0.9, y: 0.45), CGPoint(x: 0.95, y: -0.25), CGPoint(x: 0.1, y: 0.85),
    ]

    var body: some View {
        TimelineView(.animation) { tl in
            let period = 4.0
            let t = Loop.seconds(tl.date)
            let pin = Int(t / period) % 2 == 0
            let x = Loop.local(t, period: period)
            let visible = min(spread.count, max(0, Int((x - 0.5) / 0.28) + 1))
            // Lage relativ zur Grünmitte ist breitenunabhängig, daher reicht eine feste Breite
            let layout = Layout(width: 325, height: 210)
            let aim = pin ? layout.pin : layout.greenCenter
            let dots = spread.map { CGPoint(x: aim.x + $0.x * 40, y: aim.y + $0.y * 30) }
            let onGreen = dots.prefix(visible).filter(layout.isOnGreen).count
            TipVisualCard(height: 210) {
                Canvas { ctx, size in
                    let l = Layout(width: size.width, height: size.height)
                    let aim = pin ? l.pin : l.greenCenter
                    // Fairway, Wasser, Bunker, Grün
                    var fairway = Path()
                    fairway.addRoundedRect(in: CGRect(x: 16, y: l.greenCenter.y - 24, width: l.greenCenter.x - 40, height: 48),
                                           cornerSize: CGSize(width: 24, height: 24))
                    ctx.fill(fairway, with: .color(AppTheme.green.opacity(0.55)))
                    var pond = Path()
                    pond.addRoundedRect(in: l.water, cornerSize: CGSize(width: 22, height: 22))
                    ctx.fill(pond, with: .color(water))
                    ctx.fill(Path(ellipseIn: l.greenRect), with: .color(Color(red: 0.25, green: 0.66, blue: 0.36)))
                    ctx.fill(Path(ellipseIn: CGRect(x: l.greenCenter.x + 4, y: l.greenRect.maxY - 14, width: 44, height: 22)),
                             with: .color(sand))
                    ctx.flag(l.pin, color, height: 26)

                    // Ziel und Streukreis
                    let tee = CGPoint(x: 30, y: l.greenCenter.y)
                    ctx.line([tee, aim], .white.opacity(0.4), 1.2, dash: [4, 4])
                    ctx.stroke(Path(ellipseIn: CGRect(x: aim.x - 44, y: aim.y - 33, width: 88, height: 66)),
                               with: .color(.white.opacity(0.6)), style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
                    ctx.ball(tee, 5)
                    for (i, d) in spread.prefix(visible).enumerated() {
                        let p = CGPoint(x: aim.x + d.x * 40, y: aim.y + d.y * 30)
                        let ok = l.isOnGreen(p)
                        ctx.circle(p, i == visible - 1 ? 6 : 5, ok ? .white : hazardRed)
                        if !ok { ctx.ring(p, 8, hazardRed.opacity(0.6), 1.5) }
                    }
                }
            } footer: {
                VStack(spacing: 10) {
                    HStack {
                        TipHint(text: pin ? "Auf die Fahne: Fehlschläge landen im Wasser"
                                          : "Grünmitte: auch Fehlschläge bleiben auf dem Grün",
                                color: pin ? hazardRed : color)
                    }
                    Text("\(onGreen) von \(visible) auf dem Grün")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(AppTheme.textSec)
                    PhasePills(labels: ["Auf die Fahne", "Grünmitte"], active: pin ? 0 : 1, color: pin ? hazardRed : color)
                }
            }
        }
    }

    private struct Layout {
        let width: CGFloat, height: CGFloat
        var greenCenter: CGPoint { CGPoint(x: width * 0.58, y: height / 2) }
        var greenRect: CGRect { CGRect(x: greenCenter.x - 66, y: greenCenter.y - 52, width: 132, height: 104) }
        var pin: CGPoint { CGPoint(x: greenCenter.x + 44, y: greenCenter.y - 10) }
        var water: CGRect { CGRect(x: greenCenter.x + 62, y: 18, width: width - greenCenter.x - 70, height: height - 36) }
        func isOnGreen(_ p: CGPoint) -> Bool {
            let dx = (p.x - greenCenter.x) / 66, dy = (p.y - greenCenter.y) / 52
            return dx * dx + dy * dy <= 1 && !water.contains(p)
        }
    }
}

// MARK: - Handicap klug nutzen

/// 18 Löcher mit Schwierigkeitsindex: Vorgabeschläge fallen auf die schwersten Löcher.
struct HandicapStrokesVisual: View {
    let color: Color
    private let si = [7, 15, 3, 11, 1, 17, 9, 13, 5, 8, 16, 4, 12, 2, 18, 10, 14, 6]
    private let hcp = 9

    var body: some View {
        TimelineView(.animation) { tl in
            let x = Loop.local(Loop.seconds(tl.date), period: 7.5)
            // Stand der Verteilung: 0 … hcp, als Dezimalzahl für das Fallen
            let progress = max(0, (x - 0.5) / 0.45)
            TipVisualCard(height: 170) {
                VStack(spacing: 10) {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(0..<18, id: \.self) { i in
                            let rank = Double(si[i])
                            let drop = min(max(progress - (rank - 1), 0), 1)
                            let gets = si[i] <= hcp
                            VStack(spacing: 4) {
                                Text("\(i + 1)")
                                    .font(.system(size: 9, weight: .bold).monospacedDigit())
                                    .foregroundStyle(AppTheme.textTer)
                                ZStack(alignment: .top) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(gets && drop >= 1 ? color.opacity(0.25) : Color.white.opacity(0.07))
                                        .frame(height: 64 - CGFloat(si[i]) * 2.2)
                                    if gets && drop > 0 {
                                        Circle().fill(color)
                                            .frame(width: 9, height: 9)
                                            .offset(y: -30 + 36 * Loop.smooth(drop))
                                            .opacity(min(drop * 3, 1))
                                    }
                                }
                                .frame(height: 64, alignment: .bottom)
                                Text("\(si[i])")
                                    .font(.system(size: 9, weight: si[i] <= hcp ? .heavy : .regular).monospacedDigit())
                                    .foregroundStyle(si[i] <= hcp ? color : AppTheme.textTer)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    HStack {
                        Text("Loch").font(.caption2).foregroundStyle(AppTheme.textTer)
                        Spacer()
                        Text("Höhe = Schwierigkeit, unten: SI").font(.caption2).foregroundStyle(AppTheme.textTer)
                    }
                }
                .padding(.horizontal, 12)
            } footer: {
                VStack(spacing: 6) {
                    Text("Handicap \(hcp): je ein Vorgabeschlag auf SI 1–\(hcp)")
                        .font(.caption.bold()).foregroundStyle(AppTheme.text)
                    TipHint(text: "Ein Netto-Par auf den schwersten Löchern ist Gold wert", color: color)
                }
            }
        }
    }
}

// MARK: - Wind berücksichtigen

/// Seitenansicht: Flugbahn bei Gegen- und Rückenwind gegen die windstille Bahn.
struct WindVisual: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { tl in
            let period = 3.6
            let t = Loop.seconds(tl.date)
            let head = Int(t / period) % 2 == 0
            let x = Loop.local(t, period: period)
            TipVisualCard(height: 200) {
                Canvas { ctx, size in
                    let ground = size.height - 30
                    let ball = CGPoint(x: 28, y: ground - 4)
                    let calm = CGPoint(x: size.width * 0.7, y: ground - 4)
                    let end = head ? CGPoint(x: size.width * 0.52, y: ground - 4) : CGPoint(x: size.width * 0.86, y: ground - 4)
                    let calmControl = CGPoint(x: (ball.x + calm.x) / 2, y: 10)
                    let control = head ? CGPoint(x: (ball.x + end.x) * 0.58, y: -20)
                                       : CGPoint(x: (ball.x + end.x) / 2, y: 30)

                    ctx.line([CGPoint(x: 10, y: ground), CGPoint(x: size.width - 10, y: ground)], Color.white.opacity(0.25), 1)
                    // Windstriche ziehen in Windrichtung
                    for i in 0..<7 {
                        let speed = 60.0
                        let raw = Double(i) * 53 + t * speed
                        let span = Double(size.width + 60)
                        var px = CGFloat(raw.truncatingRemainder(dividingBy: span)) - 30
                        if head { px = size.width - px }
                        let py = 24 + CGFloat((i * 37) % 90)
                        let dir: CGFloat = head ? -1 : 1
                        ctx.line([CGPoint(x: px, y: py), CGPoint(x: px + dir * 22, y: py)], Color.white.opacity(0.22), 1.6)
                    }
                    // Windstille Bahn als Vergleich
                    ctx.stroke(quadPath(ball, calmControl, calm, upTo: 1), with: .color(.white.opacity(0.3)),
                               style: StrokeStyle(lineWidth: 1.4, dash: [3, 5]))
                    ctx.circle(calm, 3, .white.opacity(0.4))
                    // Aktuelle Bahn
                    let fly = Loop.ramp(x, 0.3, 1.8)
                    ctx.stroke(quadPath(ball, control, end, upTo: fly), with: .color(color),
                               style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    ctx.ball(quadPoint(ball, control, end, fly))
                    if x > 1.8 {
                        let diff = head ? "−15 m" : "+12 m"
                        ctx.label(Text(diff).font(.caption.bold()).foregroundStyle(color),
                                  at: CGPoint(x: end.x, y: ground + 14))
                    }
                    ctx.label(Text("windstill").font(.caption2).foregroundStyle(AppTheme.textTer),
                              at: CGPoint(x: calm.x, y: ground + 14))
                }
            } footer: {
                VStack(spacing: 10) {
                    TipHint(text: head ? "Gegenwind: einen Schläger mehr, ruhiger schwingen"
                                       : "Rückenwind: der Ball fliegt und rollt weiter",
                            color: color)
                    PhasePills(labels: ["Gegenwind", "Rückenwind"], active: head ? 0 : 1, color: color)
                }
            }
        }
    }
}

// MARK: - Putt-Strategie

/// Draufsicht aufs Grün: erster Putt in die 50-cm-Zone, zweiter fest ins Loch.
struct PuttStrategyVisual: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { tl in
            let x = Loop.local(Loop.seconds(tl.date), period: 6.0)
            let second = x > 2.9
            TipVisualCard(height: 190) {
                Canvas { ctx, size in
                    let hole = CGPoint(x: size.width - 70, y: size.height / 2 - 6)
                    let start = CGPoint(x: 34, y: size.height / 2 + 30)
                    let rest = CGPoint(x: hole.x - 20, y: hole.y + 12)

                    ctx.fill(Path(ellipseIn: CGRect(x: 8, y: 14, width: size.width - 16, height: size.height - 28)),
                             with: .color(Color(red: 0.25, green: 0.66, blue: 0.36).opacity(0.55)))
                    // Zone
                    ctx.circle(hole, 34, color.opacity(0.14))
                    ctx.ring(hole, 34, color, 1.6, dash: [4, 4])
                    ctx.label(Text("50 cm").font(.caption2.bold()).foregroundStyle(color),
                              at: CGPoint(x: hole.x, y: hole.y - 44))
                    ctx.circle(hole, 6, .black.opacity(0.7))

                    // Erster Putt mit leichtem Break, rollt aus
                    let control = CGPoint(x: (start.x + rest.x) / 2, y: start.y + 34)
                    let roll1 = 1 - pow(1 - Loop.smooth((x - 0.4) / 2.0), 2)
                    let roll2 = Loop.ramp(x, 3.2, 3.9)
                    var ball = x < 0.4 ? start : quadPoint(start, control, rest, min(max(roll1, 0), 1))
                    ctx.stroke(quadPath(start, control, rest, upTo: min(max(roll1, 0.001), 1)),
                               with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 1.4, dash: [2, 4]))
                    if second {
                        ball = CGPoint(x: rest.x + (hole.x - rest.x) * roll2, y: rest.y + (hole.y - rest.y) * roll2)
                        ctx.line([rest, ball], .white.opacity(0.5), 1.4)
                    }
                    if roll2 < 1 { ctx.ball(ball, 5) }
                    else { ctx.ring(hole, 9 + 8 * Loop.ramp(x, 3.9, 4.5), color.opacity(1 - Loop.ramp(x, 3.9, 4.5)), 2) }
                    ctx.label(Text("10 m").font(.caption2.bold()).foregroundStyle(AppTheme.textTer),
                              at: CGPoint(x: start.x + 4, y: start.y + 18))
                }
            } footer: {
                VStack(spacing: 10) {
                    TipHint(text: second ? "Kurzer Putt: festes Tempo, aufs Loch schauen"
                                         : "Langer Putt: nur in die Zone, kein Dreiputt",
                            color: color)
                    PhasePills(labels: ["1. Putt: Zone", "2. Putt: einlochen"], active: second ? 1 : 0, color: color)
                }
            }
        }
    }
}

// MARK: - Risiko vs. Belohnung

/// Über das Wasser (Platsch, Strafschlag) gegen sicheres Vorlegen.
struct RiskRewardVisual: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { tl in
            let period = 4.4
            let t = Loop.seconds(tl.date)
            let risky = Int(t / period) % 2 == 0
            let x = Loop.local(t, period: period)
            TipVisualCard(height: 210) {
                Canvas { ctx, size in
                    let tee = CGPoint(x: 30, y: size.height - 36)
                    let pin = CGPoint(x: size.width - 46, y: 54)
                    let pond = CGRect(x: size.width / 2 - 62, y: 40, width: 124, height: 96)

                    var fair = Path()
                    fair.move(to: CGPoint(x: 18, y: size.height - 14))
                    fair.addQuadCurve(to: CGPoint(x: size.width - 20, y: 90),
                                      control: CGPoint(x: size.width / 2, y: size.height + 20))
                    ctx.stroke(fair, with: .color(AppTheme.green.opacity(0.6)), style: StrokeStyle(lineWidth: 38, lineCap: .round))
                    ctx.fill(Path(ellipseIn: pond), with: .color(water))
                    ctx.fill(Path(ellipseIn: CGRect(x: pin.x - 38, y: pin.y - 26, width: 76, height: 52)),
                             with: .color(Color(red: 0.25, green: 0.66, blue: 0.36)))
                    ctx.flag(pin, color, height: 24)
                    ctx.circle(tee, 7, .white.opacity(0.25))

                    if risky {
                        let splash = CGPoint(x: pond.midX + 26, y: pond.midY - 6)
                        let control = CGPoint(x: (tee.x + splash.x) / 2, y: 10)
                        let fly = Loop.ramp(x, 0.3, 1.6)
                        ctx.stroke(quadPath(tee, control, splash, upTo: fly), with: .color(hazardRed),
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        if fly < 1 { ctx.ball(quadPoint(tee, control, splash, fly), 5) }
                        else {
                            for k in 0..<3 {
                                let r = Loop.ramp(x, 1.6 + Double(k) * 0.25, 2.8 + Double(k) * 0.25)
                                ctx.ring(splash, 4 + 22 * r, .white.opacity(0.8 * (1 - r)), 1.6)
                            }
                            ctx.label(Text("+1 Strafschlag").font(.caption.bold()).foregroundStyle(hazardRed),
                                      at: CGPoint(x: splash.x, y: pond.maxY + 14))
                        }
                    } else {
                        let layup = CGPoint(x: size.width / 2 + 8, y: size.height - 46)
                        let near = CGPoint(x: pin.x - 10, y: pin.y + 8)
                        let c1 = CGPoint(x: (tee.x + layup.x) / 2, y: size.height - 120)
                        let c2 = CGPoint(x: (layup.x + near.x) / 2 + 20, y: 40)
                        let f1 = Loop.ramp(x, 0.3, 1.4)
                        let f2 = Loop.ramp(x, 1.8, 2.9)
                        ctx.stroke(quadPath(tee, c1, layup, upTo: f1), with: .color(color),
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        if x > 1.8 {
                            ctx.stroke(quadPath(layup, c2, near, upTo: f2), with: .color(color),
                                       style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        }
                        ctx.ball(x < 1.8 ? quadPoint(tee, c1, layup, f1) : quadPoint(layup, c2, near, f2), 5)
                    }
                }
            } footer: {
                VStack(spacing: 10) {
                    TipHint(text: risky ? "Über das Wasser: geht es schief, droht ein Doppelbogey"
                                        : "Vorlegen: zwei sichere Schläge, Bogey im Sack",
                            color: risky ? hazardRed : color)
                    PhasePills(labels: ["Über das Wasser", "Vorlegen"], active: risky ? 0 : 1, color: risky ? hazardRed : color)
                }
            }
        }
    }
}
