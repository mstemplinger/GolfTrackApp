import SwiftUI

// MARK: - Rahmen

/// Gemeinsamer Rahmen aller Tipp-Grafiken: Bühne mit Rasenverlauf, darunter Fußzeile.
struct TipVisualCard<Stage: View, Footer: View>: View {
    var height: CGFloat = 220
    @ViewBuilder var stage: () -> Stage
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 14) {
            stage()
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [AppTheme.green.opacity(0.0), AppTheme.green.opacity(0.35)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            footer()
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Phasenanzeige unter einer Grafik (folgt der Animation, nicht antippbar).
struct PhasePills: View {
    let labels: [LocalizedStringKey]
    let active: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(labels.indices, id: \.self) { i in
                Text(labels[i])
                    .font(.caption2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(i == active ? AppTheme.bg : AppTheme.textSec)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 4)
                    .background(i == active ? color : Color.white.opacity(0.07), in: Capsule())
            }
        }
        .animation(.easeInOut(duration: 0.25), value: active)
    }
}

/// Einzeiliger Hinweis in Akzentfarbe, z. B. was gerade passiert.
struct TipHint: View {
    let text: LocalizedStringKey
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Zeitsteuerung

/// Hilfen für zeitgesteuerte Endlosschleifen in `TimelineView(.animation)`.
enum Loop {
    static func seconds(_ date: Date) -> Double { date.timeIntervalSinceReferenceDate }

    /// Position innerhalb einer Periode in Sekunden.
    static func local(_ t: Double, period: Double) -> Double { t.truncatingRemainder(dividingBy: period) }

    static func smooth(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c * c * (3 - 2 * c)
    }

    /// Weicher Verlauf 0…1 zwischen den Zeitpunkten a und b.
    static func ramp(_ x: Double, _ a: Double, _ b: Double) -> Double { smooth((x - a) / (b - a)) }

    static func lerp(_ a: Double, _ b: Double, _ f: Double) -> Double { a + (b - a) * f }

    /// Stationen nacheinander: je `hold` Sekunden stehen, dann `move` Sekunden Übergang.
    /// `shown` ist die Station, die gerade überwiegt (für Beschriftungen).
    static func step(_ t: Double, count: Int, hold: Double, move: Double)
        -> (index: Int, next: Int, f: Double, shown: Int) {
        let slot = hold + move
        let x = local(t, period: slot * Double(count))
        let i = min(Int(x / slot), count - 1)
        let r = x - Double(i) * slot
        let f = r < hold ? 0 : smooth((r - hold) / move)
        let next = (i + 1) % count
        return (i, next, f, f > 0.5 ? next : i)
    }

    /// Wert zwischen den Stationen aus `step`.
    static func value(_ values: [Double], _ s: (index: Int, next: Int, f: Double, shown: Int)) -> Double {
        lerp(values[s.index], values[s.next], s.f)
    }
}

// MARK: - Golfer-Posen

extension GolferPose {
    // Schlägerwinkel bewusst über 360° bzw. unter 0°: so dreht der Schläger beim
    // Interpolieren in Schwungrichtung (Rückschwung 90→360, Durchschwung 360→−165,
    // Treffmoment bei 90°) statt auf dem kürzeren, falschen Weg.
    static let address  = GolferPose(hipShift: 0, arm: 90, club: 90, finish: 0)
    static let top      = GolferPose(hipShift: -9, arm: 218, club: 360, finish: 0)
    static let finished = GolferPose(hipShift: 18, arm: -40, club: -165, finish: 1)

    static func lerp(_ a: GolferPose, _ b: GolferPose, _ f: Double) -> GolferPose {
        GolferPose(hipShift: Loop.lerp(a.hipShift, b.hipShift, f),
                   arm: Loop.lerp(a.arm, b.arm, f),
                   club: Loop.lerp(a.club, b.club, f),
                   finish: Loop.lerp(a.finish, b.finish, f))
    }

    /// Pose zur Zeit `x` aus Schlüsselbildern (Sekunde, Pose), weich interpoliert.
    static func keyframes(_ frames: [(Double, GolferPose)], at x: Double) -> GolferPose {
        guard let first = frames.first else { return .address }
        if x <= first.0 { return first.1 }
        for (a, b) in zip(frames, frames.dropFirst()) where x <= b.0 {
            return lerp(a.1, b.1, Loop.ramp(x, a.0, b.0))
        }
        return frames.last!.1
    }

    /// Weniger Hüftbewegung, damit Kopf und Achse ruhig bleiben.
    func steady(_ factor: Double = 0.3) -> GolferPose {
        GolferPose(hipShift: hipShift * factor, arm: arm, club: club, finish: finish)
    }
}

// MARK: - Zeichenhilfen

extension GraphicsContext {
    /// Linie mit runden Enden.
    func line(_ points: [CGPoint], _ color: Color, _ width: CGFloat, dash: [CGFloat] = []) {
        var p = Path()
        p.addLines(points)
        stroke(p, with: .color(color),
               style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
    }

    func circle(_ c: CGPoint, _ r: CGFloat, _ color: Color) {
        fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(color))
    }

    func ring(_ c: CGPoint, _ r: CGFloat, _ color: Color, _ width: CGFloat, dash: [CGFloat] = []) {
        stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
               with: .color(color), style: StrokeStyle(lineWidth: width, dash: dash))
    }

    /// Golfball mit leichtem Schatten.
    func ball(_ c: CGPoint, _ r: CGFloat = 4.5) {
        circle(CGPoint(x: c.x + 0.6, y: c.y + 1.2), r, .black.opacity(0.35))
        circle(c, r, .white)
    }

    /// Fahne mit Loch, Fuß bei `base`.
    func flag(_ base: CGPoint, _ color: Color, height: CGFloat = 34) {
        fill(Path(ellipseIn: CGRect(x: base.x - 6, y: base.y - 2, width: 12, height: 4)), with: .color(.black.opacity(0.5)))
        line([base, CGPoint(x: base.x, y: base.y - height)], Color(white: 0.9), 1.6)
        var f = Path()
        f.move(to: CGPoint(x: base.x, y: base.y - height))
        f.addLine(to: CGPoint(x: base.x + 14, y: base.y - height + 5))
        f.addLine(to: CGPoint(x: base.x, y: base.y - height + 10))
        f.closeSubpath()
        fill(f, with: .color(color))
    }

    /// Text an einer Stelle zeichnen.
    func label(_ text: Text, at p: CGPoint, anchor: UnitPoint = .center) {
        draw(text, at: p, anchor: anchor)
    }
}

/// Punkt auf einer quadratischen Bézierkurve.
func quadPoint(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
    let u = 1 - t
    return CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
                   y: u * u * a.y + 2 * u * t * c.y + t * t * b.y)
}

/// Teilstück einer quadratischen Bézierkurve von 0 bis `t` als Pfad.
func quadPath(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, upTo t: Double, steps: Int = 40) -> Path {
    var p = Path()
    p.move(to: a)
    let n = max(Int(Double(steps) * t), 1)
    for i in 1...n { p.addLine(to: quadPoint(a, c, b, t * Double(i) / Double(n))) }
    return p
}
