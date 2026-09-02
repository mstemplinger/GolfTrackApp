import SwiftUI

/// Schematische Draufsicht einer genormten Miniaturgolfbahn.
///
/// Absichtlich schematisch und nicht maßstäblich: Die verbindlichen Zeichnungen
/// liegen beim Weltverband, hier geht es nur darum, dass man die Bahn vor Ort
/// wiedererkennt. Abschlag links, Ziel rechts.
struct MinigolfLaneSketch: View {
    let shape: MinigolfLaneShape
    let glyph: MinigolfLaneGlyph

    /// Kleine Variante für die Liste, große für die Detailansicht.
    var lineWidth: CGFloat = 1.6

    private let laneColor   = Color.white.opacity(0.55)
    private let fillColor   = Color.white.opacity(0.07)
    private let teeColor    = Color.white.opacity(0.22)
    private let targetColor = Color(red: 0.35, green: 0.80, blue: 0.50)

    var body: some View {
        Canvas { ctx, size in
            let g = Geometry(size: size, shape: shape)

            drawLane(ctx: &ctx, g: g)
            drawTarget(ctx: &ctx, g: g)
            drawTee(ctx: &ctx, g: g)
            drawGlyph(ctx: &ctx, g: g)
        }
        .aspectRatio(3.0, contentMode: .fit)
    }

    // MARK: - Maße der Skizze

    private struct Geometry {
        let size: CGSize
        let shape: MinigolfLaneShape

        var inset: CGFloat { max(6, size.height * 0.10) }
        var midY: CGFloat { size.height / 2 }

        /// Halbe Bahnbreite (die Bahn ist 0,90 m breit, der Zielkreis 1,40 m).
        var half: CGFloat { size.height * 0.19 }
        var laneTop: CGFloat { midY - half }
        var laneBottom: CGFloat { midY + half }
        var laneLeft: CGFloat { inset }

        /// Radius des Zielkreises bzw. des schrägen Kreises.
        var targetRadius: CGFloat {
            switch shape {
            case .straight:     return half * 1.55
            case .tiltedCircle: return size.height * 0.44
            case .jump:         return size.height * 0.30
            }
        }

        var targetCenter: CGPoint {
            CGPoint(x: size.width - inset - targetRadius, y: midY)
        }

        /// Rechtes Ende des geraden Bahnteils.
        var laneRight: CGFloat {
            switch shape {
            case .straight:     return targetCenter.x - targetRadius * 0.25
            case .tiltedCircle: return targetCenter.x - targetRadius * 0.55
            case .jump:         return laneLeft + (size.width - 2 * inset) * 0.34
            }
        }

        var laneRect: CGRect {
            CGRect(x: laneLeft, y: laneTop, width: laneRight - laneLeft, height: half * 2)
        }

        /// Punkt auf der Bahnachse bei `t` (0 = Abschlag, 1 = Ende des geraden Teils).
        func x(_ t: CGFloat) -> CGFloat { laneLeft + (laneRight - laneLeft) * t }
        /// Punkt quer zur Bahn (-1 = obere Bande, 1 = untere Bande).
        func y(_ t: CGFloat) -> CGFloat { midY + half * t }
    }

    // MARK: - Grundformen

    private func drawLane(ctx: inout GraphicsContext, g: Geometry) {
        let lane = Path(roundedRect: g.laneRect, cornerRadius: g.half * 0.25)
        ctx.fill(lane, with: .color(fillColor))
        ctx.stroke(lane, with: .color(laneColor), lineWidth: lineWidth)

        if g.shape == .jump {
            // Zwischen Rampe und Netz gibt es keine Bahn – gestrichelte Fluglinie.
            var flight = Path()
            flight.move(to: CGPoint(x: g.laneRight, y: g.midY))
            flight.addQuadCurve(
                to: CGPoint(x: g.targetCenter.x - g.targetRadius, y: g.midY),
                control: CGPoint(x: (g.laneRight + g.targetCenter.x) / 2, y: g.midY - g.size.height * 0.34)
            )
            ctx.stroke(flight, with: .color(AppTheme.gold.opacity(0.7)),
                       style: StrokeStyle(lineWidth: lineWidth, dash: [4, 3]))
        }
    }

    private func drawTarget(ctx: inout GraphicsContext, g: Geometry) {
        let r = g.targetRadius
        let circle = Path(ellipseIn: CGRect(x: g.targetCenter.x - r, y: g.targetCenter.y - r,
                                            width: r * 2, height: r * 2))
        ctx.fill(circle, with: .color(fillColor))
        ctx.stroke(circle, with: .color(g.shape == .jump ? AppTheme.gold : targetColor),
                   lineWidth: lineWidth)

        if g.shape == .tiltedCircle {
            // Neigung andeuten: kurze Hangstriche am oberen Kreisrand.
            for i in 0..<5 {
                let angle = CGFloat.pi * (1.12 + 0.19 * CGFloat(i))
                var tick = Path()
                let outer = CGPoint(x: g.targetCenter.x + cos(angle) * r,
                                    y: g.targetCenter.y + sin(angle) * r)
                let inner = CGPoint(x: g.targetCenter.x + cos(angle) * r * 0.78,
                                    y: g.targetCenter.y + sin(angle) * r * 0.78)
                tick.move(to: outer)
                tick.addLine(to: inner)
                ctx.stroke(tick, with: .color(laneColor.opacity(0.7)), lineWidth: lineWidth * 0.7)
            }
        }

        if g.shape != .jump {
            let hr = max(2, g.half * 0.24)
            let hole = Path(ellipseIn: CGRect(x: g.targetCenter.x - hr, y: g.targetCenter.y - hr,
                                              width: hr * 2, height: hr * 2))
            ctx.fill(hole, with: .color(targetColor))
        } else {
            // Netzring
            let ir = r * 0.55
            let ring = Path(ellipseIn: CGRect(x: g.targetCenter.x - ir, y: g.targetCenter.y - ir,
                                              width: ir * 2, height: ir * 2))
            ctx.stroke(ring, with: .color(AppTheme.gold), lineWidth: lineWidth)
        }
    }

    private func drawTee(ctx: inout GraphicsContext, g: Geometry) {
        let w = (g.laneRight - g.laneLeft) * 0.09
        let tee = Path(CGRect(x: g.laneLeft + lineWidth, y: g.laneTop + lineWidth,
                              width: w, height: g.half * 2 - lineWidth * 2))
        ctx.fill(tee, with: .color(teeColor))

        let br = max(1.5, g.half * 0.17)
        let ball = Path(ellipseIn: CGRect(x: g.laneLeft + w / 2 - br, y: g.midY - br,
                                          width: br * 2, height: br * 2))
        ctx.fill(ball, with: .color(.white))
    }

    // MARK: - Hindernisse

    private func drawGlyph(ctx: inout GraphicsContext, g: Geometry) {
        let gold = GraphicsContext.Shading.color(AppTheme.gold)
        let goldSoft = GraphicsContext.Shading.color(AppTheme.gold.opacity(0.35))

        switch glyph {
        case .keines:
            break

        case .pyramiden:
            // Zwei Dreiecke, die die Bahn von oben und unten verengen.
            for (t, side) in [(CGFloat(0.42), CGFloat(-1)), (CGFloat(0.60), CGFloat(1))] {
                var p = Path()
                p.move(to: CGPoint(x: g.x(t - 0.09), y: g.y(side)))
                p.addLine(to: CGPoint(x: g.x(t + 0.09), y: g.y(side)))
                p.addLine(to: CGPoint(x: g.x(t), y: g.y(side * -0.15)))
                p.closeSubpath()
                ctx.fill(p, with: goldSoft)
                ctx.stroke(p, with: gold, lineWidth: lineWidth)
            }

        case .salto:
            // Looping: Kreis über der Bahn, Ein- und Ausgang auf der Achse.
            let r = g.half * 0.85
            let c = CGPoint(x: g.x(0.5), y: g.midY - r * 0.15)
            let loop = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ctx.stroke(loop, with: gold, lineWidth: lineWidth * 1.2)
            var rails = Path()
            rails.move(to: CGPoint(x: g.x(0.34), y: g.y(-0.5)))
            rails.addLine(to: CGPoint(x: g.x(0.34), y: g.y(0.5)))
            rails.move(to: CGPoint(x: g.x(0.66), y: g.y(-0.5)))
            rails.addLine(to: CGPoint(x: g.x(0.66), y: g.y(0.5)))
            ctx.stroke(rails, with: gold, lineWidth: lineWidth)

        case .niere:
            // Nierenförmiges Hindernis mit Tunnel in der Mitte.
            let rect = CGRect(x: g.x(0.40), y: g.y(-0.7),
                              width: (g.laneRight - g.laneLeft) * 0.20, height: g.half * 1.4)
            let kidney = Path(roundedRect: rect, cornerRadius: rect.height / 2)
            ctx.fill(kidney, with: goldSoft)
            ctx.stroke(kidney, with: gold, lineWidth: lineWidth)
            var tunnel = Path()
            tunnel.move(to: CGPoint(x: rect.minX, y: g.midY))
            tunnel.addLine(to: CGPoint(x: rect.maxX, y: g.midY))
            ctx.stroke(tunnel, with: .color(.white.opacity(0.85)), lineWidth: lineWidth * 1.4)

        case .doppelwellen:
            for t in [CGFloat(0.42), CGFloat(0.60)] {
                var wave = Path()
                wave.move(to: CGPoint(x: g.x(t), y: g.y(-1)))
                wave.addQuadCurve(to: CGPoint(x: g.x(t), y: g.y(1)),
                                  control: CGPoint(x: g.x(t) + g.half * 0.7, y: g.midY))
                ctx.stroke(wave, with: gold, lineWidth: lineWidth * 1.2)
            }

        case .liegendeSchleife:
            // Waagrechte Schleife: Kreisbogen mit Ein- und Ausgang.
            let r = g.half * 0.95
            let c = CGPoint(x: g.x(0.5), y: g.midY)
            var loop = Path()
            loop.addArc(center: c, radius: r, startAngle: .degrees(35), endAngle: .degrees(325),
                        clockwise: false)
            ctx.stroke(loop, with: gold, lineWidth: lineWidth * 1.2)
            var inner = Path()
            inner.addArc(center: c, radius: r * 0.5, startAngle: .degrees(0), endAngle: .degrees(360),
                         clockwise: false)
            ctx.stroke(inner, with: goldSoft, lineWidth: lineWidth)

        case .bruecke, .mittelhuegel:
            hill(ctx: &ctx, g: g, at: 0.5, width: 0.16)

        case .passagen:
            // Zwei Passagen mit je einem Hügel.
            var walls = Path()
            walls.move(to: CGPoint(x: g.x(0.36), y: g.midY))
            walls.addLine(to: CGPoint(x: g.x(0.70), y: g.midY))
            ctx.stroke(walls, with: gold, lineWidth: lineWidth * 1.2)
            hill(ctx: &ctx, g: g, at: 0.53, width: 0.12, from: -1, to: -0.05)
            hill(ctx: &ctx, g: g, at: 0.53, width: 0.12, from: 0.05, to: 1)

        case .sprungschanze:
            // Rampe am Bahnende (die Bahn selbst ist der Anlauf).
            var ramp = Path()
            ramp.move(to: CGPoint(x: g.x(0.55), y: g.y(-1)))
            ramp.addLine(to: CGPoint(x: g.x(1.0), y: g.y(-1)))
            ramp.addLine(to: CGPoint(x: g.x(1.0), y: g.y(1)))
            ramp.addLine(to: CGPoint(x: g.x(0.55), y: g.y(1)))
            ctx.stroke(ramp, with: gold, lineWidth: lineWidth)
            var slope = Path()
            slope.move(to: CGPoint(x: g.x(0.55), y: g.y(1)))
            slope.addLine(to: CGPoint(x: g.x(1.0), y: g.y(-1)))
            ctx.stroke(slope, with: goldSoft, lineWidth: lineWidth)

        case .zielkreisfenster, .auflaufkeil:
            // Quermauer mit schmalem Fenster.
            let t: CGFloat = glyph == .auflaufkeil ? 0.58 : 0.66
            var wall = Path()
            wall.move(to: CGPoint(x: g.x(t), y: g.y(-1)))
            wall.addLine(to: CGPoint(x: g.x(t), y: g.y(-0.22)))
            wall.move(to: CGPoint(x: g.x(t), y: g.y(0.22)))
            wall.addLine(to: CGPoint(x: g.x(t), y: g.y(1)))
            ctx.stroke(wall, with: gold, lineWidth: lineWidth * 1.6)
            if glyph == .auflaufkeil {
                // Auflaufkeil: Steigung vor der Mauer.
                var wedge = Path()
                wedge.move(to: CGPoint(x: g.x(t - 0.16), y: g.y(-1)))
                wedge.addLine(to: CGPoint(x: g.x(t), y: g.y(-1)))
                wedge.move(to: CGPoint(x: g.x(t - 0.16), y: g.y(1)))
                wedge.addLine(to: CGPoint(x: g.x(t), y: g.y(1)))
                ctx.stroke(wedge, with: goldSoft, lineWidth: lineWidth * 2.2)
            }

        case .rohr:
            let t: CGFloat = 0.52
            let len = (g.laneRight - g.laneLeft) * 0.22
            let rect = CGRect(x: g.x(t), y: g.midY - g.half * 0.22, width: len, height: g.half * 0.44)
            let pipe = Path(roundedRect: rect, cornerRadius: rect.height / 2)
            ctx.fill(pipe, with: goldSoft)
            ctx.stroke(pipe, with: gold, lineWidth: lineWidth)
            var block = Path()
            block.move(to: CGPoint(x: rect.midX, y: g.y(-1)))
            block.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            block.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            block.addLine(to: CGPoint(x: rect.midX, y: g.y(1)))
            ctx.stroke(block, with: gold, lineWidth: lineWidth * 1.4)

        case .staebe:
            for (t, side) in [(CGFloat(0.34), CGFloat(-1)), (CGFloat(0.52), CGFloat(1)), (CGFloat(0.70), CGFloat(-1))] {
                var rod = Path()
                rod.move(to: CGPoint(x: g.x(t), y: g.y(side)))
                rod.addLine(to: CGPoint(x: g.x(t), y: g.y(side * -0.35)))
                ctx.stroke(rod, with: gold, lineWidth: lineWidth * 1.6)
            }

        case .labyrinth:
            let side = g.half * 1.5
            let rect = CGRect(x: g.x(0.5) - side / 2, y: g.midY - side / 2, width: side, height: side)
            let box = Path(rect)
            ctx.stroke(box, with: gold, lineWidth: lineWidth)
            let inner = Path(CGRect(x: rect.midX - side * 0.14, y: rect.midY - side * 0.18,
                                    width: side * 0.28, height: side * 0.36))
            ctx.stroke(inner, with: goldSoft, lineWidth: lineWidth)
            // Vier Eingänge auf der Abschlagseite, einer offen.
            for i in 0..<4 {
                let y = rect.minY + side * (0.2 + 0.2 * CGFloat(i))
                var gate = Path()
                gate.move(to: CGPoint(x: rect.minX - g.half * 0.35, y: y))
                gate.addLine(to: CGPoint(x: rect.minX, y: y))
                let shading: GraphicsContext.Shading = i == 2
                    ? .color(.white.opacity(0.85))
                    : goldSoft
                ctx.stroke(gate, with: shading, lineWidth: lineWidth)
            }

        case .kegel:
            for t in [CGFloat(0.42), CGFloat(0.62)] {
                let r = g.half * 0.55
                let c = CGPoint(x: g.x(t), y: g.midY + (t < 0.5 ? -g.half * 0.35 : g.half * 0.35))
                let outer = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                ctx.fill(outer, with: goldSoft)
                ctx.stroke(outer, with: gold, lineWidth: lineWidth)
                let ir = r * 0.45
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - ir, y: c.y - ir, width: ir * 2, height: ir * 2)),
                           with: gold, lineWidth: lineWidth * 0.8)
            }

        case .doppelkeile:
            for side in [CGFloat(-1), CGFloat(1)] {
                var wedge = Path()
                wedge.move(to: CGPoint(x: g.x(0.40), y: g.y(side)))
                wedge.addLine(to: CGPoint(x: g.x(0.66), y: g.y(side)))
                wedge.addLine(to: CGPoint(x: g.x(0.66), y: g.y(side * 0.2)))
                wedge.closeSubpath()
                ctx.fill(wedge, with: goldSoft)
                ctx.stroke(wedge, with: gold, lineWidth: lineWidth)
            }

        case .vulkan:
            let r = g.half * 1.05
            let c = CGPoint(x: g.x(0.62), y: g.midY)
            for factor in [CGFloat(1.0), CGFloat(0.62)] {
                let rr = r * factor
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)),
                           with: gold, lineWidth: lineWidth)
            }

        case .vHindernis:
            var v = Path()
            v.move(to: CGPoint(x: g.x(0.38), y: g.y(-1)))
            v.addLine(to: CGPoint(x: g.x(0.74), y: g.y(-0.18)))
            v.move(to: CGPoint(x: g.x(0.38), y: g.y(1)))
            v.addLine(to: CGPoint(x: g.x(0.74), y: g.y(0.18)))
            ctx.stroke(v, with: gold, lineWidth: lineWidth * 1.6)

        case .winkel:
            var wall = Path()
            wall.move(to: CGPoint(x: g.x(0.34), y: g.y(-1)))
            wall.addLine(to: CGPoint(x: g.x(0.62), y: g.y(0.35)))
            ctx.stroke(wall, with: gold, lineWidth: lineWidth * 1.8)

        case .blitz:
            var wall = Path()
            wall.move(to: CGPoint(x: g.x(0.26), y: g.y(-1)))
            wall.addLine(to: CGPoint(x: g.x(0.50), y: g.y(0.25)))
            wall.move(to: CGPoint(x: g.x(0.52), y: g.y(1)))
            wall.addLine(to: CGPoint(x: g.x(0.76), y: g.y(-0.25)))
            ctx.stroke(wall, with: gold, lineWidth: lineWidth * 1.8)

        case .plateau:
            let rect = CGRect(x: g.x(0.52), y: g.y(-0.78),
                              width: (g.laneRight - g.laneLeft) * 0.34, height: g.half * 1.56)
            let plateau = Path(roundedRect: rect, cornerRadius: g.half * 0.2)
            ctx.fill(plateau, with: goldSoft)
            ctx.stroke(plateau, with: gold, lineWidth: lineWidth)
            var rampe = Path()
            rampe.move(to: CGPoint(x: g.x(0.36), y: g.midY - g.half * 0.24))
            rampe.addLine(to: CGPoint(x: rect.minX, y: g.midY - g.half * 0.24))
            rampe.move(to: CGPoint(x: g.x(0.36), y: g.midY + g.half * 0.24))
            rampe.addLine(to: CGPoint(x: rect.minX, y: g.midY + g.half * 0.24))
            ctx.stroke(rampe, with: gold, lineWidth: lineWidth)

        case .steilschraege:
            for i in 0..<4 {
                let t = 0.34 + 0.11 * CGFloat(i)
                var line = Path()
                line.move(to: CGPoint(x: g.x(t), y: g.y(-1)))
                line.addLine(to: CGPoint(x: g.x(t + 0.06), y: g.y(1)))
                ctx.stroke(line, with: goldSoft, lineWidth: lineWidth)
            }

        case .rampe:
            var ramp = Path()
            ramp.move(to: CGPoint(x: g.x(0.46), y: g.y(-1)))
            ramp.addLine(to: CGPoint(x: g.x(0.46), y: g.y(1)))
            ramp.move(to: CGPoint(x: g.x(0.62), y: g.y(-1)))
            ramp.addLine(to: CGPoint(x: g.x(0.62), y: g.y(1)))
            ctx.stroke(ramp, with: gold, lineWidth: lineWidth * 1.4)
            var arrow = Path()
            arrow.move(to: CGPoint(x: g.x(0.46), y: g.midY))
            arrow.addLine(to: CGPoint(x: g.x(0.62), y: g.midY))
            ctx.stroke(arrow, with: goldSoft, lineWidth: lineWidth)

        case .raute:
            var rhombus = Path()
            rhombus.move(to: CGPoint(x: g.x(0.40), y: g.midY))
            rhombus.addLine(to: CGPoint(x: g.x(0.54), y: g.y(-0.8)))
            rhombus.addLine(to: CGPoint(x: g.x(0.68), y: g.midY))
            rhombus.addLine(to: CGPoint(x: g.x(0.54), y: g.y(0.8)))
            rhombus.closeSubpath()
            ctx.fill(rhombus, with: goldSoft)
            ctx.stroke(rhombus, with: gold, lineWidth: lineWidth)

        case .zielhuegel:
            let r = g.targetRadius * 0.72
            let c = g.targetCenter
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                       with: gold, lineWidth: lineWidth)
        }
    }

    /// Hügel quer über die Bahn – als Höhenlinien angedeutet.
    private func hill(ctx: inout GraphicsContext, g: Geometry, at t: CGFloat, width: CGFloat,
                      from: CGFloat = -1, to: CGFloat = 1) {
        for (i, offset) in [-width, CGFloat(0), width].enumerated() {
            var line = Path()
            line.move(to: CGPoint(x: g.x(t + offset), y: g.y(from)))
            line.addLine(to: CGPoint(x: g.x(t + offset), y: g.y(to)))
            ctx.stroke(line,
                       with: .color(AppTheme.gold.opacity(i == 1 ? 1.0 : 0.35)),
                       lineWidth: i == 1 ? lineWidth * 1.4 : lineWidth)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(MinigolfStandardLanes.all) { lane in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(lane.normNumber). \(lane.name)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    MinigolfLaneSketch(shape: lane.shape, glyph: lane.glyph)
                        .frame(height: 70)
                }
                .padding(10)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    .background(AppTheme.bg)
}
