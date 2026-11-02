import SwiftUI

// MARK: - Pre-Shot Routine

/// Sechs Schritte im Kreis, die Markierung läuft immer gleich herum.
struct PreShotRoutineVisual: View {
    let color: Color
    private let steps: [(String, LocalizedStringKey)] = [
        ("figure.stand", "Hinter den Ball stellen"),
        ("scope", "Ziellinie sehen"),
        ("arrow.triangle.2.circlepath", "Zwei Probeschwünge"),
        ("figure.walk", "Einsteigen"),
        ("line.diagonal.arrow", "Ausrichtung prüfen"),
        ("figure.golf", "Schlagen"),
    ]

    var body: some View {
        TimelineView(.animation) { tl in
            let slot = 1.2
            let x = Loop.local(Loop.seconds(tl.date), period: slot * Double(steps.count))
            let current = Int(x / slot)
            TipVisualCard(height: 230) {
                GeometryReader { geo in
                    let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let r: CGFloat = 80
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 2 * r, height: 2 * r).position(c)
                        Circle().trim(from: 0, to: x / (slot * Double(steps.count)))
                            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 2 * r, height: 2 * r).position(c)
                        ForEach(steps.indices, id: \.self) { i in
                            let a = (-90 + Double(i) * 60) * .pi / 180
                            let active = i == current
                            ZStack {
                                Circle().fill(i <= current ? color : AppTheme.cardAlt)
                                Image(systemName: steps[i].0)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(i <= current ? AppTheme.bg : AppTheme.textSec)
                            }
                            .frame(width: 38, height: 38)
                            .scaleEffect(active ? 1.18 : 1)
                            .shadow(color: active ? color.opacity(0.6) : .clear, radius: 8)
                            .position(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
                            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: current)
                        }
                        VStack(spacing: 2) {
                            Text("\(current + 1)")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(color)
                                .contentTransition(.numericText())
                            Text(steps[current].1)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.text)
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                        }
                        .position(c)
                        .animation(.easeInOut(duration: 0.25), value: current)
                    }
                }
            } footer: {
                TipHint(text: "Jedes Mal gleich – das beruhigt das Nervensystem", color: color)
            }
        }
    }
}

// MARK: - Einen Schlag nach dem anderen

/// Schläge ziehen vorbei: der missglückte wird abgehakt, im Fokus steht nur der nächste.
struct OneShotVisual: View {
    let color: Color
    private let red = Color(red: 0.92, green: 0.32, blue: 0.28)
    private let shots: [(String, LocalizedStringKey, Bool)] = [
        ("figure.golf", "Abschlag", true),
        ("xmark", "Ins Rough", false),
        ("arrow.up.forward", "Raus aufs Fairway", true),
        ("flag.fill", "Aufs Grün", true),
        ("circle.circle", "Putt", true),
    ]

    var body: some View {
        TimelineView(.animation) { tl in
            let t = Loop.seconds(tl.date)
            let s = Loop.step(t, count: shots.count, hold: 1.6, move: 0.7)
            // Vom letzten Schlag springt die Reihe ohne Zurückspulen an den Anfang
            let pos = Double(s.index) + (s.next == 0 ? 0 : s.f)
            TipVisualCard(height: 200) {
                GeometryReader { geo in
                    let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2 - 10)
                    ZStack {
                        Circle()
                            .stroke(color.opacity(0.5), lineWidth: 2)
                            .frame(width: 92, height: 92)
                            .scaleEffect(1 + 0.06 * sin(t * 2.4))
                            .position(c)
                        ForEach(shots.indices, id: \.self) { i in
                            let d = Double(i) - pos
                            let shot = shots[i]
                            let tint = shot.2 ? color : red
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(d < -0.5 ? AppTheme.cardAlt : tint.opacity(abs(d) < 0.5 ? 1 : 0.25))
                                    Image(systemName: d < -0.5 ? "checkmark" : shot.0)
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundStyle(abs(d) < 0.5 ? AppTheme.bg : AppTheme.textSec)
                                }
                                .frame(width: 72, height: 72)
                                Text(shot.1)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.text)
                                    .fixedSize()
                            }
                            .scaleEffect(1 - min(abs(d), 2) * 0.28)
                            .opacity(max(0, 1 - abs(d) * 0.55))
                            .position(x: c.x + d * 112, y: c.y + 14)
                        }
                    }
                }
            } footer: {
                TipHint(text: shots[s.shown].2 ? "Nur der nächste Schlag zählt"
                                               : "Fehler passiert – durchatmen und abhaken",
                        color: shots[s.shown].2 ? color : red)
            }
        }
    }
}

// MARK: - Bogey akzeptieren

/// Neun Löcher im Vergleich: konstant Bogey gegen Achterbahn mit Doppelbogeys.
struct AcceptBogeyVisual: View {
    let color: Color
    private let steady = [1, 1, 1, 1, 1, 1, 1, 1, 1]
    private let risky  = [0, 2, 0, 3, 1, 0, 2, -1, 3]

    var body: some View {
        TimelineView(.animation) { tl in
            let x = Loop.local(Loop.seconds(tl.date), period: 7.5)
            let shown = min(9, Int(x / 0.38))
            TipVisualCard(height: 190) {
                VStack(alignment: .leading, spacing: 16) {
                    row("Bogey-Golf", steady, shown: shown)
                    row("Auf Risiko", risky, shown: shown)
                    HStack(spacing: 12) {
                        key(color, "Bogey")
                        key(Color(red: 0.98, green: 0.56, blue: 0.08), "Doppel")
                        key(Color(red: 0.92, green: 0.32, blue: 0.28), "Triple")
                    }
                }
                .padding(.horizontal, 14)
            } footer: {
                TipHint(text: "Wer Doppelbogeys vermeidet, spielt die bessere Runde", color: color)
            }
        }
    }

    private func row(_ title: LocalizedStringKey, _ scores: [Int], shown: Int) -> some View {
        let total = scores.prefix(shown).reduce(0, +)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption.bold()).foregroundStyle(AppTheme.text)
                Spacer()
                Text(total >= 0 ? "+\(total)" : "\(total)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(shown == 9 ? AppTheme.text : AppTheme.textSec)
                    .contentTransition(.numericText(value: Double(total)))
                    .animation(.snappy, value: total)
            }
            HStack(spacing: 4) {
                ForEach(0..<9, id: \.self) { i in
                    let v = scores[i]
                    RoundedRectangle(cornerRadius: 5)
                        .fill(i < shown ? fill(v) : Color.white.opacity(0.06))
                        .overlay {
                            if i < shown {
                                Text(v == 0 ? "P" : v > 0 ? "+\(v)" : "\(v)")
                                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                                    .foregroundStyle(v == 0 || v < 0 ? AppTheme.text : AppTheme.bg)
                            }
                        }
                        .frame(height: 26)
                        .scaleEffect(i < shown ? 1 : 0.7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: shown)
                }
            }
        }
    }

    private func fill(_ v: Int) -> Color {
        switch v {
        case ..<0: return AppTheme.green
        case 0: return Color.white.opacity(0.18)
        case 1: return color
        case 2: return Color(red: 0.98, green: 0.56, blue: 0.08)
        default: return Color(red: 0.92, green: 0.32, blue: 0.28)
        }
    }

    private func key(_ c: Color, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 10, height: 10)
            Text(text).font(.caption2).foregroundStyle(AppTheme.textTer)
        }
    }
}

// MARK: - Visualisierung

/// Erst die Flugbahn im Kopf zeichnen, dann den Ball genau so fliegen lassen.
struct VisualizationVisual: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { tl in
            let x = Loop.local(Loop.seconds(tl.date), period: 6.0)
            let phase = x < 1.8 ? 0 : x < 2.7 ? 1 : 2
            TipVisualCard(height: 200) {
                Canvas { ctx, size in
                    let ground = size.height - 34
                    let ball = CGPoint(x: 36, y: ground - 4.5)
                    let land = CGPoint(x: size.width - 84, y: ground - 4.5)
                    let pin = CGPoint(x: size.width - 56, y: ground)
                    let control = CGPoint(x: (ball.x + land.x) / 2, y: 0)

                    ctx.line([CGPoint(x: 10, y: ground), CGPoint(x: size.width - 10, y: ground)],
                             Color.white.opacity(0.25), 1)
                    ctx.fill(Path(ellipseIn: CGRect(x: pin.x - 50, y: ground - 3, width: 100, height: 8)),
                             with: .color(AppTheme.green))
                    ctx.flag(pin, color, height: 40)

                    // Gedachte Flugbahn
                    let sketch = Loop.ramp(x, 0.2, 1.6)
                    let ghostAlpha = 1 - Loop.ramp(x, 4.6, 5.6)
                    ctx.stroke(quadPath(ball, control, land, upTo: sketch),
                               with: .color(.white.opacity(0.55 * ghostAlpha)),
                               style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [3, 5]))
                    // Landepunkt
                    if x > 1.8 {
                        let pulse = Loop.ramp(x, 1.8, 2.6)
                        ctx.ring(land, 6 + 10 * pulse, color.opacity(ghostAlpha * (1 - pulse * 0.5)), 2)
                    }
                    // Echter Ball
                    let fly = Loop.ramp(x, 2.8, 4.1)
                    var p = ball
                    if x >= 2.8 && x < 4.1 {
                        p = quadPoint(ball, control, land, fly)
                        ctx.stroke(quadPath(ball, control, land, upTo: fly), with: .color(color),
                                   style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    } else if x >= 4.1 {
                        let roll = Loop.ramp(x, 4.1, 4.7)
                        p = CGPoint(x: land.x + (pin.x - 8 - land.x) * roll, y: land.y)
                        ctx.stroke(quadPath(ball, control, land, upTo: 1), with: .color(color.opacity(ghostAlpha)),
                                   style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    }
                    ctx.ball(p)
                    // Gedankenblase beim Sehen
                    if phase < 2 {
                        ctx.label(Text(Image(systemName: "brain.head.profile")).font(.system(size: 22)).foregroundStyle(color),
                                  at: CGPoint(x: 30, y: 28))
                    }
                }
            } footer: {
                VStack(spacing: 10) {
                    TipHint(text: ["Ziel und Flugbahn vor dem inneren Auge zeichnen",
                                   "Den Ball landen sehen",
                                   "Der Körper schlägt, was der Kopf gesehen hat"][phase], color: color)
                    PhasePills(labels: ["Flugbahn sehen", "Landung sehen", "Schlagen"], active: phase, color: color)
                }
            }
        }
    }
}

// MARK: - Umgang mit Druck

/// Atemkreis: 4 s ein, 2 s halten, 6 s aus – der Puls sinkt.
struct PressureVisual: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { tl in
            let t = Loop.seconds(tl.date)
            let x = Loop.local(t, period: 12)
            let scale = x < 4 ? Loop.lerp(0.55, 1, Loop.smooth(x / 4))
                : x < 6 ? 1 : Loop.lerp(1, 0.55, Loop.smooth((x - 6) / 6))
            let bpm = x < 6 ? Loop.lerp(84, 98, Loop.smooth(x / 6)) : Loop.lerp(98, 84, Loop.smooth((x - 6) / 6))
            let label: LocalizedStringKey = x < 4 ? "Einatmen" : x < 6 ? "Halten" : "Ausatmen"
            let left = x < 4 ? 4 - x : x < 6 ? 6 - x : 12 - x
            let beat = pow(max(0, sin(t * .pi * 2 * bpm / 60)), 12)
            TipVisualCard(height: 220) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [color.opacity(0.55), color.opacity(0.08)],
                                             center: .center, startRadius: 10, endRadius: 100))
                        .frame(width: 180, height: 180)
                        .scaleEffect(scale)
                    Circle()
                        .stroke(color.opacity(0.6), lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .scaleEffect(scale)
                    VStack(spacing: 4) {
                        Text(label).font(.headline).foregroundStyle(AppTheme.text)
                        Text("\(Int(left.rounded(.up))) s")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color(red: 0.92, green: 0.32, blue: 0.28))
                            .scaleEffect(1 + 0.25 * beat)
                        Text("\(Int(bpm)) bpm")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .padding(12)
                }
            } footer: {
                TipHint(text: "Langsam ausatmen senkt den Puls – Nervosität ist Energie", color: color)
            }
        }
    }
}
