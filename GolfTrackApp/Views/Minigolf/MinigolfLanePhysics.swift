import Foundation
import simd

// MARK: - Geometrie

/// Geometrie einer Normbahn – gemeinsame Grundlage für das 3D-Modell und die
/// Ballsimulation, damit Spur und sichtbare Körper nicht auseinanderlaufen.
///
/// Koordinaten wie im Modell, in Metern: x längs (0 = Abschlag), y oben,
/// z quer (+z = rechte Bande). Bewusst ohne SceneKit/UIKit, damit die
/// Schlagsuche auch außerhalb der App laufen kann.
struct MinigolfLaneCourse {
    static let ballRadius: Float = 0.03
    static let half: Float = 0.45            // halbe Bahnbreite
    static let bandeHeight: Float = 0.08
    static let bandeThickness: Float = 0.04
    static let holeRadius: Float = 0.05
    /// Unterkante des Sockels, auf dem Bahn und Zielkreis stehen.
    static let base: Float = -0.2

    enum Surface { case felt, obstacle, bande }

    /// Körper auf der Bahn. Alle außer `profile` und nicht festen Kegeln sind
    /// zugleich Kollisionskörper; die Kollisionsform wird aus denselben Maßen abgeleitet.
    enum Part {
        case box(x0: Float, x1: Float, z0: Float, z1: Float, y0: Float, y1: Float, Surface, chamfer: Float)
        /// Gerade Wand zwischen zwei Punkten der Draufsicht (x, z).
        case wall(from: SIMD2<Float>, to: SIMD2<Float>, height: Float, thickness: Float)
        /// Flacher Körper mit Grundriss (x, z).
        case plate([SIMD2<Float>], y0: Float, height: Float)
        /// Ringförmige Wand, Winkel 0 = Spielrichtung, positiv zur rechten Bande.
        case arcWall(center: SIMD2<Float>, radiusIn: Float, radiusOut: Float, from: Float, to: Float,
                     y0: Float, height: Float)
        case pyramid(x: Float, z: Float, width: Float, height: Float)
        case cone(x: Float, z: Float, bottomRadius: Float, topRadius: Float, height: Float, solid: Bool)
        case cylinder(x: Float, z: Float, radius: Float, height: Float)
        /// Senkrechter Ring (Salto), steht bei (x, z) auf der Bahn.
        case ring(x: Float, z: Float, radius: Float, pipe: Float)
        /// Rohr längs der Bahn.
        case pipe(x0: Float, x1: Float, axisY: Float, inner: Float, outer: Float)
        /// Geländekörper mit Seitenprofil (x, y) – die Höhe steckt in `laneTerrain`, keine Kollision.
        case profile([SIMD2<Float>], z0: Float, z1: Float, Surface)
    }

    /// Senkrechter Looping: Ball läuft innen im Kreis um (x, centerY).
    struct Salto {
        var x: Float
        var centerY: Float
        var radius: Float           // Radius der Ballmitte
        var halfGap: Float          // erlaubte |z| der Ballmitte im Durchgang
        var shift: Float            // seitlicher Versatz zwischen Ein- und Ausgang
    }

    /// Liegende Schleife: Rinne um `center`, der Ball läuft einmal ganz herum.
    struct Rinne {
        var center: SIMD2<Float>
        var radius: Float           // Ballmitte an der Außenwand
        var entryZ: ClosedRange<Float>
        var maxSpeed: Float
        /// Winkel über die volle Runde hinaus, an dem die Auslauflippe den Ball
        /// freigibt – so zeigt er beim Verlassen auf das Ziel.
        var exitExtra: Float = 0
    }

    struct Pipe {
        var x0: Float
        var x1: Float
        var inner: Float
    }

    enum Goal {
        case hole(SIMD3<Float>)
        /// Labyrinth: Loch oder liegen bleiben in der Zielkammer.
        case chamber(hole: SIMD3<Float>, x: ClosedRange<Float>, z: ClosedRange<Float>)
        /// Sprungschanze: Ball fällt von oben durch den Netzring.
        case net(center: SIMD3<Float>, radius: Float)

        var point: SIMD3<Float> {
            switch self {
            case .hole(let p), .chamber(let p, _, _): return p
            case .net(let c, _): return c
            }
        }
    }

    let lane: MinigolfStandardLane

    /// Ende der Banden des geraden Teils.
    private(set) var wallEnd: Float = 0
    /// Mitte und Radius des Zielkreises (bei der Sprungschanze nil).
    private(set) var circleCenter: Float?
    private(set) var circleRadius: Float = 0.7
    private(set) var tilt: Float = 0
    private(set) var targetY: Float = 0
    private(set) var extent: Float = 6.25

    /// Höhe der Bahnoberfläche im geraden Teil.
    private(set) var laneTerrain: (Float, Float) -> Float = { _, _ in 0 }
    /// Zusätzliche Höhe im Zielkreis (Zielhügel), Koordinaten relativ zur Kreismitte.
    private(set) var circleTerrain: (Float, Float) -> Float = { _, _ in 0 }

    private(set) var parts: [Part] = []
    private(set) var goal: Goal = .hole(.zero)
    /// Liegt das Loch im Zielkreis (sonst gehört es zu einem Hindernis)?
    private(set) var holeInCircle = true
    private(set) var salto: Salto?
    private(set) var rinne: Rinne?
    private(set) var pipe: Pipe?
    /// Bahn, auf der laut Tipp über Bande oder Hindernis gespielt wird.
    private(set) var prefersBank = false
    private(set) var colliders: [MinigolfCollider] = []

    init(lane: MinigolfStandardLane) {
        self.lane = lane
        switch lane.shape {
        case .straight:
            circleCenter = 5.55
            circleRadius = 0.70
        case .tiltedCircle:
            circleCenter = 4.45
            circleRadius = 1.15
            tilt = 0.10
            extent = 5.6
        case .jump:
            circleCenter = nil
            wallEnd = 2.5
            extent = 4.4
        }
        if let cx = circleCenter {
            wallEnd = cx - (circleRadius * circleRadius - Self.half * Self.half).squareRoot()
        }
        buildObstacles()
        if holeInCircle, let cx = circleCenter {
            goal = .hole(SIMD3(cx, targetY + circleTerrain(0, 0), 0))
        }
        if var rn = rinne {
            rn.exitExtra = atan2(rn.radius - goal.point.z, goal.point.x - rn.center.x)
            rinne = rn
        }
        buildColliders()
    }

    /// Höhe der Oberfläche an (x, z) – Bahn, Zielkreis oder (hinter der Schanze) der Boden.
    func ground(_ x: Float, _ z: Float) -> Float {
        if let cx = circleCenter, x > wallEnd - 0.01 {
            let dx = x - cx
            if (dx * dx + z * z).squareRoot() <= circleRadius + 0.01 {
                return targetY - z * sin(tilt) + circleTerrain(dx, z)
            }
        }
        if circleCenter == nil && x > wallEnd { return Self.base }
        return laneTerrain(x, z)
    }

    // MARK: Hindernisse je Bahn

    private mutating func buildObstacles() {
        let h = Self.half
        switch lane.glyph {
        case .keines:
            break

        case .pyramiden:
            prefersBank = true
            parts.append(.pyramid(x: 2.1, z: -0.2, width: 0.5, height: 0.22))
            parts.append(.pyramid(x: 3.0, z: 0.2, width: 0.5, height: 0.22))

        case .salto:
            let s = Salto(x: 2.6, centerY: 0.25, radius: 0.22, halfGap: 0.047, shift: 0.04)
            salto = s
            for z: Float in [-0.09, 0.09] {
                parts.append(.ring(x: s.x, z: z, radius: 0.25, pipe: 0.013))
            }

        case .niere:
            for side: Float in [-1, 1] {
                parts.append(.box(x0: 1.4, x1: 2.4, z0: side < 0 ? -0.32 : 0.09, z1: side < 0 ? -0.09 : 0.32,
                                  y0: 0, y1: 0.12, .obstacle, chamfer: 0.06))
            }
            // Tunneldach: liegt höher als der Ball, also keine Kollision.
            parts.append(.box(x0: 1.45, x1: 2.35, z0: -0.1, z1: 0.1, y0: 0.08, y1: 0.12, .obstacle, chamfer: 0))

        case .doppelwellen:
            let waves: [(Float, Float, Float)] = [(2.1, 0.5, 0.05), (3.0, 0.5, 0.05)]
            laneTerrain = { x, _ in waves.reduce(0) { $0 + Self.bump(x, $1.0, $1.1, $1.2) } }
            for w in waves { bumpBody(center: w.0, width: w.1, height: w.2, z0: -h, z1: h) }

        case .liegendeSchleife:
            let c = SIMD2<Float>(2.6, 0)
            parts.append(.arcWall(center: c, radiusIn: 0.38, radiusOut: 0.41,
                                  from: 145 * .pi / 180, to: (360 + 35) * .pi / 180, y0: 0, height: 0.08))
            parts.append(.cylinder(x: c.x, z: c.y, radius: 0.18, height: 0.08))
            rinne = Rinne(center: c, radius: 0.35, entryZ: 0.21...0.35, maxSpeed: 3.0)

        case .bruecke, .mittelhuegel:
            let (w, ht): (Float, Float) = lane.glyph == .bruecke ? (0.9, 0.12) : (1.0, 0.08)
            laneTerrain = { x, _ in Self.bump(x, 2.6, w, ht) }
            bumpBody(center: 2.6, width: w, height: ht, z0: -h, z1: h)

        case .sprungschanze:
            // Steile Schanze (Absprung gut 55°), danach fliegt der Ball frei.
            laneTerrain = { x, _ in x > 1.7 ? 0.25 * pow(min(1, (x - 1.7) / 0.8), 4.6) : 0 }
            var ramp: [SIMD2<Float>] = [SIMD2(1.7, 0)]
            for i in 1...24 {
                let x = 1.7 + 0.8 * Float(i) / 24
                ramp.append(SIMD2(x, laneTerrain(x, 0)))
            }
            ramp.append(SIMD2(2.5, 0))
            parts.append(.profile(ramp, z0: -h, z1: h, .obstacle))
            // Ringunterkante knapp 77 cm über dem Abschlag (Regel: 70–80 cm).
            goal = .net(center: SIMD3(3.75, 0.78, 0), radius: 0.25)
            holeInCircle = false

        case .zielkreisfenster:
            window(at: 4.75, from: 0, gap: 0.065)

        case .auflaufkeil:
            laneTerrain = { x, _ in
                if x < 3.7 || x > 5.0 { return 0 }
                if x < 4.5 { return 0.08 * (x - 3.7) / 0.8 }
                if x < 4.9 { return 0.08 }
                return 0.08 * (5.0 - x) / 0.1
            }
            parts.append(.profile([SIMD2(3.7, 0), SIMD2(4.5, 0.08), SIMD2(4.9, 0.08), SIMD2(5.0, 0)],
                                  z0: -h, z1: h, .obstacle))
            window(at: 4.6, from: 0.08, gap: 0.065)

        case .rohr:
            let p = Pipe(x0: 3.7, x1: 4.8, inner: 0.036)
            pipe = p
            parts.append(.pipe(x0: p.x0, x1: p.x1, axisY: 0.038, inner: p.inner, outer: 0.05))
            parts.append(.box(x0: 4.22, x1: 4.28, z0: -h, z1: -0.05, y0: 0, y1: 0.12, .obstacle, chamfer: 0))
            parts.append(.box(x0: 4.22, x1: 4.28, z0: 0.05, z1: h, y0: 0, y1: 0.12, .obstacle, chamfer: 0))

        case .staebe:
            prefersBank = true
            for (x, side) in [(Float(1.7), Float(-1)), (2.6, 1), (3.5, -1)] {
                let z0 = side < 0 ? -h : -0.16
                let z1 = side < 0 ? 0.16 : h
                parts.append(.box(x0: x - 0.015, x1: x + 0.015, z0: z0, z1: z1, y0: 0.01, y1: 0.06,
                                  .obstacle, chamfer: 0))
            }

        case .labyrinth:
            let t: Float = 0.03, ht: Float = 0.08
            func wallBox(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float) {
                parts.append(.box(x0: x0, x1: x1, z0: z0, z1: z1, y0: 0, y1: ht, .obstacle, chamfer: 0))
            }
            // Kasten mit vier Eingängen auf der Abschlagseite.
            wallBox(2.96 - t, 2.96, -0.36, 0.36)
            wallBox(2.24, 2.96, -0.36, -0.36 + t)
            wallBox(2.24, 2.96, 0.36 - t, 0.36)
            for (z0, z1) in [(Float(-0.36), Float(-0.29)), (-0.19, -0.13), (-0.03, 0.03),
                             (0.13, 0.19), (0.29, 0.36)] {
                wallBox(2.24, 2.24 + t, z0, z1)
            }
            // Hinter den falschen Eingängen ist zu.
            wallBox(2.34, 2.34 + t, -0.30, -0.02)
            wallBox(2.34, 2.34 + t, 0.18, 0.30)
            // Zielkammer in der Mitte, offen zum zweiten Eingang von rechts.
            wallBox(2.48, 2.48 + t, -0.14, 0.03)
            wallBox(2.48, 2.72, -0.14, -0.14 + t)
            wallBox(2.48, 2.72, 0.14 - t, 0.14)
            wallBox(2.72 - t, 2.72, -0.14, 0.14)
            let r = Self.ballRadius
            goal = .chamber(hole: SIMD3(2.61, 0, 0), x: (2.48 + t + r)...(2.72 - t - r),
                            z: (-0.14 + t + r)...(0.14 - t - r))
            holeInCircle = false

        case .kegel:
            prefersBank = true
            for (x, z) in [(Float(2.1), Float(-0.18)), (3.1, 0.18)] {
                parts.append(.cone(x: x, z: z, bottomRadius: 0.24, topRadius: 0.08, height: 0.12, solid: true))
            }

        case .doppelkeile:
            for side: Float in [-1, 1] {
                parts.append(.plate([SIMD2(2.0, side * h), SIMD2(3.3, side * h), SIMD2(3.3, side * 0.09)],
                                    y0: 0, height: 0.08))
            }
            // Schüssel: Rand um das Ziel.
            circleTerrain = { x, z in Self.bump((x * x + z * z).squareRoot(), 0.15, 0.09, 0.04) }

        case .passagen:
            parts.append(.box(x0: 1.9, x1: 3.6, z0: -0.015, z1: 0.015, y0: 0, y1: 0.08, .obstacle, chamfer: 0))
            laneTerrain = { x, _ in Self.bump(x, 2.75, 0.5, 0.07) }
            bumpBody(center: 2.75, width: 0.5, height: 0.07, z0: -h, z1: -0.015)
            bumpBody(center: 2.75, width: 0.5, height: 0.07, z0: 0.015, z1: h)

        case .vulkan:
            let c = SIMD2<Float>(3.2, 0)
            laneTerrain = { x, z in
                let d = simd_distance(SIMD2(x, z), c)
                return 0.18 * min(1, max(0, (0.42 - d) / 0.27))
            }
            parts.append(.cone(x: c.x, z: c.y, bottomRadius: 0.42, topRadius: 0.15, height: 0.18, solid: false))
            goal = .hole(SIMD3(c.x, 0.18, c.y))
            holeInCircle = false

        case .vHindernis:
            let x0: Float = lane.shape == .tiltedCircle ? 1.2 : 1.9
            let x1: Float = lane.shape == .tiltedCircle ? 2.6 : 3.7
            for side: Float in [-1, 1] {
                parts.append(.wall(from: SIMD2(x0, side * h), to: SIMD2(x1, side * 0.08),
                                   height: 0.07, thickness: 0.03))
            }

        case .winkel:
            prefersBank = true
            parts.append(.wall(from: SIMD2(1.77, -h), to: SIMD2(3.22, 0.16), height: 0.1, thickness: 0.04))

        case .blitz:
            prefersBank = true
            parts.append(.wall(from: SIMD2(1.3, -h), to: SIMD2(2.6, 0.11), height: 0.1, thickness: 0.04))
            parts.append(.wall(from: SIMD2(2.7, h), to: SIMD2(3.95, -0.11), height: 0.1, thickness: 0.04))

        case .plateau:
            let top: Float = 0.15
            laneTerrain = { x, z in
                if x >= 3.6 && x <= 5.0 && abs(z) <= 0.35 { return top }
                if x >= 2.8 && x < 3.6 && abs(z) <= 0.13 { return top * (x - 2.8) / 0.8 }
                return 0
            }
            parts.append(.profile([SIMD2(2.8, 0), SIMD2(3.6, top), SIMD2(3.6, 0)], z0: -0.13, z1: 0.13, .obstacle))
            parts.append(.box(x0: 2.8, x1: 3.6, z0: -0.16, z1: -0.13, y0: 0, y1: top + 0.04, .obstacle, chamfer: 0))
            parts.append(.box(x0: 2.8, x1: 3.6, z0: 0.13, z1: 0.16, y0: 0, y1: top + 0.04, .obstacle, chamfer: 0))
            parts.append(.box(x0: 3.6, x1: 5.0, z0: -0.35, z1: 0.35, y0: 0, y1: top, .obstacle, chamfer: 0.02))
            goal = .hole(SIMD3(4.3, top, 0))
            holeInCircle = false

        case .steilschraege:
            let top: Float = 0.3
            targetY = top
            laneTerrain = { x, _ in
                if x < 1.8 { return 0 }
                if x < 3.8 { return top * (x - 1.8) / 2.0 }
                return top
            }
            parts.append(.profile([SIMD2(1.8, 0), SIMD2(3.8, top), SIMD2(wallEnd + 0.02, top),
                                   SIMD2(wallEnd + 0.02, 0)], z0: -h, z1: h, .felt))

        case .rampe:
            laneTerrain = { x, _ in
                if x >= 2.4 && x < 3.0 { return 0.12 * (x - 2.4) / 0.6 }
                if x >= 3.0 && x <= 3.25 { return 0.12 }
                return 0
            }
            parts.append(.profile([SIMD2(2.4, 0), SIMD2(3.0, 0.12), SIMD2(3.25, 0.12), SIMD2(3.25, 0)],
                                  z0: -h, z1: h, .obstacle))

        case .raute:
            prefersBank = true
            parts.append(.plate([SIMD2(2.08, 0), SIMD2(2.81, -0.36), SIMD2(3.54, 0), SIMD2(2.81, 0.36)],
                                y0: 0, height: 0.08))

        case .zielhuegel:
            circleTerrain = { x, z in
                let d = (x * x + z * z).squareRoot()
                return 0.14 * min(1, max(0, (0.30 - d) / 0.24))
            }
        }
    }

    /// Halbe Kosinuswelle der Breite `width` um `center`.
    static func bump(_ x: Float, _ center: Float, _ width: Float, _ height: Float) -> Float {
        let u = (x - center) / (width / 2)
        guard abs(u) < 1 else { return 0 }
        return height * (1 + cos(.pi * u)) / 2
    }

    private mutating func bumpBody(center: Float, width: Float, height: Float, z0: Float, z1: Float) {
        var outline: [SIMD2<Float>] = []
        for i in 0...20 {
            let x = center - width / 2 + width * Float(i) / 20
            outline.append(SIMD2(x, Self.bump(x, center, width, height)))
        }
        parts.append(.profile(outline, z0: z0, z1: z1, .obstacle))
    }

    /// Quermauer mit schmalem Fenster in der Mitte.
    private mutating func window(at x: Float, from y0: Float, gap: Float) {
        parts.append(.box(x0: x, x1: x + 0.06, z0: -Self.half, z1: -gap, y0: 0, y1: y0 + 0.13, .obstacle, chamfer: 0))
        parts.append(.box(x0: x, x1: x + 0.06, z0: gap, z1: Self.half, y0: 0, y1: y0 + 0.13, .obstacle, chamfer: 0))
    }

    // MARK: Kollisionskörper

    private mutating func buildColliders() {
        let h = Self.half, t = Self.bandeThickness, r = Self.ballRadius
        var list: [MinigolfCollider] = []
        func rect(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float) -> [SIMD2<Float>] {
            [SIMD2(x0, z0), SIMD2(x1, z0), SIMD2(x1, z1), SIMD2(x0, z1)]
        }
        // Banden: seitlich und hinter dem Abschlag, immer höher als der Ball.
        list.append(MinigolfCollider(.polygon(rect(-t, wallEnd, -h - t, -h), rounding: 0), bande: true))
        list.append(MinigolfCollider(.polygon(rect(-t, wallEnd, h, h + t), rounding: 0), bande: true))
        list.append(MinigolfCollider(.polygon(rect(-t, 0, -h - t, h + t), rounding: 0), bande: true))
        if let cx = circleCenter {
            let open = Float.pi - asin(h / circleRadius)
            list.append(MinigolfCollider(.sector(center: SIMD2(cx, 0), radiusIn: circleRadius,
                                                 radiusOut: circleRadius + t, from: -open, to: open), bande: true))
        }

        for part in parts {
            switch part {
            case let .box(x0, x1, z0, z1, y0, y1, _, chamfer):
                let c = min(chamfer, (x1 - x0) / 2, (z1 - z0) / 2)
                list.append(MinigolfCollider(.polygon(rect(x0 + c, x1 - c, z0 + c, z1 - c), rounding: c),
                                             y0: y0, y1: y1))
            case let .wall(a, b, height, thickness):
                let d = simd_normalize(b - a)
                let n = SIMD2(-d.y, d.x) * thickness / 2
                list.append(MinigolfCollider(.polygon([a - n, b - n, b + n, a + n], rounding: 0),
                                             y0: 0, y1: height))
            case let .plate(outline, y0, height):
                list.append(MinigolfCollider(.polygon(outline, rounding: 0), y0: y0, y1: y0 + height))
            case let .arcWall(center, rIn, rOut, from, to, y0, height):
                list.append(MinigolfCollider(.sector(center: center, radiusIn: rIn, radiusOut: rOut,
                                                     from: from, to: to), y0: y0, y1: y0 + height))
            case let .pyramid(x, z, width, height):
                // Querschnitt auf Höhe der Ballmitte – dort berührt der Ball die Flanke.
                let w = width / 2 * (1 - r / height)
                list.append(MinigolfCollider(.polygon(rect(x - w, x + w, z - w, z + w), rounding: 0),
                                             y0: 0, y1: height))
            case let .cone(x, z, bottom, top, height, solid):
                guard solid else { continue }
                let radius = bottom + (top - bottom) * r / height
                list.append(MinigolfCollider(.circle(center: SIMD2(x, z), radius: radius), y0: 0, y1: height))
            case let .cylinder(x, z, radius, height):
                list.append(MinigolfCollider(.circle(center: SIMD2(x, z), radius: radius), y0: 0, y1: height))
            case let .ring(x, z, radius, pipe):
                // Nur der untere Teil des Rings liegt in Ballhöhe.
                let foot = (radius * radius - (radius - 2 * r) * (radius - 2 * r)).squareRoot()
                list.append(MinigolfCollider(.polygon(rect(x - foot, x + foot, z - pipe, z + pipe), rounding: 0),
                                             y0: 0, y1: 2 * radius))
            case let .pipe(x0, x1, axisY, _, outer):
                list.append(MinigolfCollider(.polygon(rect(x0, x1, -outer, outer), rounding: 0),
                                             y0: 0, y1: axisY + outer))
            case .profile:
                continue
            }
        }
        colliders = list
    }
}

/// Kollisionskörper in der Draufsicht (x, z) mit Höhenbereich.
struct MinigolfCollider {
    enum Shape {
        /// Einfaches Polygon, um `rounding` aufgeweitet (abgerundete Kanten).
        case polygon([SIMD2<Float>], rounding: Float)
        case circle(center: SIMD2<Float>, radius: Float)
        /// Kreisringausschnitt von Winkel `from` bis `to`.
        case sector(center: SIMD2<Float>, radiusIn: Float, radiusOut: Float, from: Float, to: Float)
    }

    let shape: Shape
    let y0: Float
    let y1: Float
    let isBande: Bool

    init(_ shape: Shape, y0: Float = -10, y1: Float = 10, bande: Bool = false) {
        self.shape = shape
        self.y0 = y0
        self.y1 = y1
        self.isBande = bande
    }

    /// Versperrt der Körper einen Ball, dessen Unterkante auf Höhe `bottom` liegt?
    /// Kanten unter gut 1 cm (Rampe → Plateau) rollt der Ball hinauf.
    func blocks(ballBottom bottom: Float) -> Bool {
        y0 < bottom + 2 * MinigolfLaneCourse.ballRadius - 0.004 && y1 > bottom + 0.012
    }

    /// Vorzeichenbehafteter Abstand von `p` zur Oberfläche und Normale nach außen.
    func distance(_ p: SIMD2<Float>) -> (Float, SIMD2<Float>) {
        switch shape {
        case let .circle(c, radius):
            let d = p - c
            let len = simd_length(d)
            return (len - radius, len > 1e-6 ? d / len : SIMD2(1, 0))

        case let .polygon(points, rounding):
            var best = Float.greatestFiniteMagnitude
            var closest = p
            var inside = false
            var j = points.count - 1
            for i in 0..<points.count {
                let a = points[j], b = points[i]
                let q = Self.closestOnSegment(p, a, b)
                let d = simd_distance_squared(p, q)
                if d < best { best = d; closest = q }
                if (b.y > p.y) != (a.y > p.y), p.x < (a.x - b.x) * (p.y - b.y) / (a.y - b.y) + b.x {
                    inside.toggle()
                }
                j = i
            }
            let dist = best.squareRoot()
            guard dist > 1e-7 else { return (-rounding, SIMD2(1, 0)) }
            let n = (p - closest) / dist
            return inside ? (-dist - rounding, -n) : (dist - rounding, n)

        case let .sector(c, rIn, rOut, from, to):
            let d = p - c
            let rho = simd_length(d)
            let u = rho > 1e-6 ? d / rho : SIMD2<Float>(1, 0)
            var rel = atan2(d.y, d.x) - from
            rel -= 2 * .pi * floor(rel / (2 * .pi))
            if rel <= to - from {
                if rho < rIn { return (rIn - rho, -u) }
                if rho > rOut { return (rho - rOut, u) }
                return rho - rIn < rOut - rho ? (-(rho - rIn), -u) : (-(rOut - rho), u)
            }
            // Außerhalb des Winkelbereichs: nächste Stirnseite.
            var best: (Float, SIMD2<Float>) = (.greatestFiniteMagnitude, u)
            for a in [from, to] {
                let dir = SIMD2(cos(a), sin(a))
                let q = Self.closestOnSegment(p, c + rIn * dir, c + rOut * dir)
                let dist = simd_distance(p, q)
                if dist < best.0 { best = (dist, dist > 1e-7 ? (p - q) / dist : u) }
            }
            return best
        }
    }

    private static func closestOnSegment(_ p: SIMD2<Float>, _ a: SIMD2<Float>, _ b: SIMD2<Float>) -> SIMD2<Float> {
        let ab = b - a
        let len2 = simd_length_squared(ab)
        guard len2 > 1e-12 else { return a }
        let t = min(1, max(0, simd_dot(p - a, ab) / len2))
        return a + t * ab
    }
}

// MARK: - Simulation

/// Schlag vom Abschlag: Querposition, Richtung (Grad, positiv zur rechten Bande) und Tempo.
struct MinigolfShot: Hashable {
    var z: Float
    var angle: Float
    var speed: Float
}

/// Ergebnis eines simulierten Schlags.
struct MinigolfBallRun {
    enum Outcome: Equatable {
        case holed          // im Loch bzw. im Netz
        case resting        // in der Zielkammer liegen geblieben
        case missed
    }

    var outcome: Outcome = .missed
    /// Ballmitte je Zeitschritt (`MinigolfBallSimulation.dt`), leer ohne Aufzeichnung.
    var positions: [SIMD3<Float>] = []
    /// Anschläge an Banden bzw. Hindernissen.
    var bandeHits = 0
    var obstacleHits = 0
    /// Sonderweg (Salto, Schleife, Rohr) durchlaufen.
    var passedFeature = false
    var duration: Float = 0
    /// Index in `positions`, ab dem der Ball ins Loch bzw. Netz fällt.
    var sinkIndex: Int?

    var success: Bool { outcome != .missed }
}

/// Rollender Ball auf der Bahnoberfläche, feste Zeitschritte.
///
/// Modell: Rollen ohne Gleiten (Hangabtrieb 5/7 g sin α), Rollreibung als
/// konstante Verzögerung, Abpraller mit Restitution an allen Kollisionskörpern,
/// freier Flug mit g, wo das Gelände schneller abfällt, als der Ball fällt.
/// Salto, liegende Schleife und Rohr laufen geführt, aber mit derselben Reibung.
enum MinigolfBallSimulation {
    static let dt: Float = 0.001
    static let g: Float = 9.81
    /// Rollreibung auf Eternit/Filz in m/s².
    static let rollingDecel: Float = 0.45
    static let restitution: Float = 0.7
    /// Anteil der Tangentialgeschwindigkeit, der einen Anschlag übersteht.
    static let tangentialKeep: Float = 0.96
    static let startX: Float = 0.25
    static let maxTime: Float = 25

    private enum Mode {
        case ground, air
        case salto(phi: Float, speed: Float, z0: Float)
        case rinne(phi: Float, speed: Float, radius0: Float)
        case pipe(speed: Float, z0: Float, x0: Float)
        case sinking(t: Float, from: SIMD3<Float>, to: SIMD3<Float>, speed: Float)
    }

    static func run(_ course: MinigolfLaneCourse, shot: MinigolfShot, record: Bool = true) -> MinigolfBallRun {
        let r = MinigolfLaneCourse.ballRadius
        let gravity = SIMD3<Float>(0, -g, 0)
        var run = MinigolfBallRun()
        var c = SIMD3<Float>(startX, course.ground(startX, shot.z) + r, shot.z)
        let a0 = shot.angle * .pi / 180
        var v = SIMD3<Float>(cos(a0), 0, sin(a0)) * shot.speed
        var mode = Mode.ground
        var t: Float = 0
        var slowFor: Float = 0
        var overHole = false
        let goalPoint = course.goal.point
        if record { run.positions.reserveCapacity(8000); run.positions.append(c) }

        func normal(_ x: Float, _ z: Float) -> SIMD3<Float> {
            let e: Float = 0.002
            let hx = (course.ground(x + e, z) - course.ground(x - e, z)) / (2 * e)
            let hz = (course.ground(x, z + e) - course.ground(x, z - e)) / (2 * e)
            return simd_normalize(SIMD3(-hx, 1, -hz))
        }

        // Salto, Schleife und Rohr sind vorgeschriebene Wege, das Netz sowieso.
        var needsFeature = course.salto != nil || course.rinne != nil || course.pipe != nil
        if case .net = course.goal { needsFeature = true }

        func finish(_ outcome: MinigolfBallRun.Outcome) -> MinigolfBallRun {
            run.outcome = needsFeature && !run.passedFeature ? .missed : outcome
            run.duration = t
            return run
        }

        while t < maxTime {
            t += dt
            switch mode {
            case .sinking(let s, let from, let to, let speed):
                // Ball rollt zur Lochmitte bzw. ins Netz und fällt.
                let len = max(simd_distance(from, to), 1e-4)
                let s2 = s + dt * max(speed, 0.3) / len
                c = from + (to - from) * min(1, s2)
                if record { run.positions.append(c) }
                if s2 >= 1 { return finish(.holed) }
                mode = .sinking(t: s2, from: from, to: to, speed: speed)
                continue

            case .salto(var phi, var speed, let z0):
                guard let s = course.salto else { return finish(.missed) }
                let normalAcc = speed * speed / s.radius + g * cos(phi)
                if normalAcc < 0 || speed <= 0 { return finish(.missed) }   // fällt aus dem Looping
                speed -= dt * ((5.0 / 7.0) * g * sin(phi) + rollingDecel / g * normalAcc)
                phi += dt * speed / s.radius
                let z = z0 + s.shift * min(1, phi / (2 * .pi))
                if phi >= 2 * .pi {
                    run.passedFeature = true
                    c = SIMD3(s.x, course.ground(s.x, z) + r, z)
                    v = SIMD3(speed, 0, 0)
                    mode = .ground
                } else {
                    c = SIMD3(s.x + s.radius * sin(phi), s.centerY - s.radius * cos(phi), z)
                    mode = .salto(phi: phi, speed: speed, z0: z0)
                }
                if record { run.positions.append(c) }
                continue

            case .rinne(var phi, var speed, let radius0):
                guard let rn = course.rinne else { return finish(.missed) }
                let radius = radius0 + (rn.radius - radius0) * min(1, phi / (.pi / 2))
                // Reibung am Boden und an der Außenwand (Fliehkraft drückt dagegen).
                speed -= dt * (rollingDecel + 0.012 * speed * speed / radius)
                if speed <= 0 { return finish(.missed) }
                phi += dt * speed / radius
                let a = Float.pi / 2 - phi
                if phi >= 2 * .pi + rn.exitExtra {
                    run.passedFeature = true
                    c = SIMD3(rn.center.x + radius * cos(a), r, rn.center.y + radius * sin(a))
                    v = speed * SIMD3(sin(a), 0, -cos(a))
                    mode = .ground
                } else {
                    c = SIMD3(rn.center.x + radius * cos(a), r, rn.center.y + radius * sin(a))
                    mode = .rinne(phi: phi, speed: speed, radius0: radius0)
                }
                if record { run.positions.append(c) }
                continue

            case .pipe(var speed, let z0, let x0):
                guard let p = course.pipe else { return finish(.missed) }
                // Im Rohr etwas mehr Reibung, die Rohrwand zentriert den Ball.
                speed -= dt * rollingDecel * 1.3
                if speed <= 0 { return finish(.missed) }    // bleibt im Rohr liegen
                let x = c.x + speed * dt
                let k = min(1, (x - x0) / 0.12)
                c = SIMD3(x, r + 0.002, z0 * (1 - k))
                if x >= p.x1 {
                    run.passedFeature = true
                    v = SIMD3(speed, 0, 0)
                    c.y = course.ground(x, 0) + r
                    mode = .ground
                } else {
                    mode = .pipe(speed: speed, z0: z0, x0: x0)
                }
                if record { run.positions.append(c) }
                continue

            case .ground, .air:
                break
            }

            let grounded: Bool
            if case .ground = mode { grounded = true } else { grounded = false }
            let prev = c

            // Beschleunigung: Hangabtrieb (rollend 5/7) und Rollreibung bzw. freier Fall.
            var acc = gravity
            if grounded {
                let n = normal(c.x, c.z)
                let gN = simd_dot(gravity, n) * n
                let gT = gravity - gN
                acc = gN + (5.0 / 7.0) * gT
                let vt = v - simd_dot(v, n) * n
                let speedT = simd_length(vt)
                let friction = rollingDecel * n.y
                if speedT <= friction * dt {
                    v -= vt
                    if simd_length((5.0 / 7.0) * gT) <= friction { v = .zero; acc = .zero }
                } else {
                    acc -= friction * vt / speedT
                }
            }
            c += v * dt + 0.5 * acc * dt * dt
            v += acc * dt

            // Bodenkontakt: unter das Gelände → zurück auf die Oberfläche, Normalanteil weg;
            // fällt das Gelände schneller ab als der Ball → Flug.
            let hNew = course.ground(c.x, c.z)
            if c.y - r <= hNew {
                let n = normal(c.x, c.z)
                c.y = hNew + r
                let vn = simd_dot(v, n)
                if vn < 0 { v -= vn * n }
                mode = .ground
            } else if grounded && c.y - r < hNew + 1e-6 {
                c.y = hNew + r
            } else {
                mode = .air
            }

            // Sonderwege.
            // Salto: Durchgang zwischen den Ringen, Ausgang um `shift` versetzt.
            if let s = course.salto, prev.x < s.x, c.x >= s.x, v.x > 0,
               c.z >= -s.halfGap, c.z <= s.halfGap - s.shift, case .ground = mode {
                mode = .salto(phi: 0, speed: v.x, z0: c.z)
                c = SIMD3(s.x, s.centerY - s.radius, c.z)
                if record { run.positions.append(c) }
                continue
            }
            if let rn = course.rinne, prev.x < rn.center.x, c.x >= rn.center.x, v.x > 0,
               rn.entryZ.contains(c.z - rn.center.y), case .ground = mode {
                let speed = simd_length(SIMD2(v.x, v.z))
                guard speed <= rn.maxSpeed else { return finish(.missed) }   // hebt aus der Rinne
                mode = .rinne(phi: 0, speed: speed, radius0: c.z - rn.center.y)
                c = SIMD3(rn.center.x, r, c.z)
                if record { run.positions.append(c) }
                continue
            }
            if let p = course.pipe, c.x + r >= p.x0, prev.x + r < p.x0, abs(c.z) <= p.inner, v.x > 0 {
                mode = .pipe(speed: v.x, z0: c.z, x0: c.x)
                if record { run.positions.append(c) }
                continue
            }

            // Kollisionen in der Draufsicht, zweimal für Ecken.
            for _ in 0..<2 {
                for col in course.colliders where col.blocks(ballBottom: c.y - r) {
                    let p = SIMD2(c.x, c.z)
                    let (d, n) = col.distance(p)
                    guard d < r else { continue }
                    let q = p + (r - d) * n
                    c.x = q.x; c.z = q.y
                    var vh = SIMD2(v.x, v.z)
                    let vn = simd_dot(vh, n)
                    if vn < 0 {
                        let tangential = vh - vn * n
                        vh = tangential * tangentialKeep - restitution * vn * n
                        v.x = vh.x; v.z = vh.y
                        if -vn > 0.05 {
                            if col.isBande { run.bandeHits += 1 } else { run.obstacleHits += 1 }
                        }
                    }
                }
            }
            if record { run.positions.append(c) }

            // Bahn verlassen: darf nicht passieren, gilt als Fehlschlag.
            if abs(c.z) > 1.5 || c.x < -0.2 || c.x > course.extent + 1.5 || c.y < MinigolfLaneCourse.base - 0.5 {
                return finish(.missed)
            }

            // Ziel.
            switch course.goal {
            case .net(let center, let radius):
                if case .air = mode, prev.y >= center.y, c.y < center.y, v.y < 0,
                   simd_distance(SIMD2(c.x, c.z), SIMD2(center.x, center.z)) <= radius - 0.014 - r {
                    run.passedFeature = true
                    let bottom = SIMD3(center.x, center.y - 0.22, center.z)
                    run.sinkIndex = run.positions.count
                    mode = .sinking(t: 0, from: c, to: bottom, speed: simd_length(v))
                    continue
                }
            case .hole, .chamber:
                guard case .ground = mode else { break }
                let horiz = SIMD2(c.x - goalPoint.x, c.z - goalPoint.z)
                let d = simd_length(horiz)
                if d < MinigolfLaneCourse.holeRadius && abs(c.y - r - goalPoint.y) < 0.02 {
                    let vh = SIMD2(v.x, v.z)
                    let speed = simd_length(vh)
                    if !overHole {
                        overHole = true
                        // Fällt, wenn die Zeit über dem Loch für einen Fall um den Ballradius reicht.
                        let dir = speed > 1e-4 ? vh / speed : SIMD2<Float>(1, 0)
                        let off = -horiz
                        let perp = abs(dir.x * off.y - dir.y * off.x)
                        let rh = MinigolfLaneCourse.holeRadius
                        let chord = 2 * max(0, rh * rh - perp * perp).squareRoot()
                        let capture = chord / (2 * r / g).squareRoot()
                        if speed <= capture {
                            let bottom = SIMD3(goalPoint.x, goalPoint.y + r - 2.2 * r, goalPoint.z)
                            run.sinkIndex = run.positions.count
                            mode = .sinking(t: 0, from: c, to: bottom, speed: speed)
                            continue
                        }
                    } else if speed < 0.02 {
                        let bottom = SIMD3(goalPoint.x, goalPoint.y + r - 2.2 * r, goalPoint.z)
                        run.sinkIndex = run.positions.count
                        mode = .sinking(t: 0, from: c, to: bottom, speed: 0.3)
                        continue
                    }
                } else {
                    overHole = false
                }
            }

            // Liegen geblieben?
            if case .ground = mode, simd_length(v) < 0.003 {
                slowFor += dt
                if slowFor > 0.3 {
                    if case let .chamber(_, xr, zr) = course.goal, xr.contains(c.x), zr.contains(c.z) {
                        return finish(.resting)
                    }
                    return finish(.missed)
                }
            } else {
                slowFor = 0
            }
        }
        return finish(.missed)
    }
}

// MARK: - Schlagwerte

/// Vorab gesuchte Schläge je Normbahn (Raster über Abschlagposition, Richtung und
/// Tempo, danach verfeinert; bevorzugt robuste Schläge und – wo der Tipp es
/// empfiehlt – Bandenspiel). Zur Laufzeit wird nur noch einmal simuliert.
enum MinigolfLaneShots {
    static func shot(for lane: MinigolfStandardLane) -> MinigolfShot {
        shots[lane.normNumber] ?? MinigolfShot(z: 0, angle: 0, speed: 2)
    }

    static let shots: [Int: MinigolfShot] = [
        1: MinigolfShot(z: -0.03, angle: 24.2, speed: 2.54), // Pyramiden
        2: MinigolfShot(z: 0.25, angle: 19, speed: 3.98), // Salto
        3: MinigolfShot(z: -0.15, angle: 5.2, speed: 2.86), // Schräger Kreis mit Niere
        4: MinigolfShot(z: -0.12, angle: 1.3, speed: 2.28), // Doppelwellen
        5: MinigolfShot(z: 0, angle: 7.9, speed: 2.84), // Liegende Schleife
        6: MinigolfShot(z: 0, angle: 0, speed: 2.28), // Brücke
        7: MinigolfShot(z: 0, angle: 0, speed: 4.8), // Sprungschanze mit Netz
        8: MinigolfShot(z: 0, angle: 0, speed: 2.28), // Gerade Bahn mit Zielkreisfenster
        9: MinigolfShot(z: 0, angle: -0.2, speed: 2.34), // Rohr
        10: MinigolfShot(z: -0.32, angle: 34.6, speed: 5.74), // Stäbe
        11: MinigolfShot(z: 0.22, angle: -3.8, speed: 1.5), // Labyrinth
        12: MinigolfShot(z: 0, angle: 23.7, speed: 2.54), // Stumpfe Kegel
        13: MinigolfShot(z: -0.1, angle: 1, speed: 2.5), // Doppelkeile
        14: MinigolfShot(z: -0.2, angle: 2.1, speed: 2.24), // Passagen
        15: MinigolfShot(z: 0, angle: 0, speed: 2.28), // Mittelhügel
        16: MinigolfShot(z: -0.1, angle: 2, speed: 2.5), // Vulkan
        17: MinigolfShot(z: 0, angle: 0, speed: 2.28), // V-Hindernis
        18: MinigolfShot(z: 0, angle: 0.1, speed: 2.74), // Winkel
        19: MinigolfShot(z: 0, angle: 4.7, speed: 2.84), // Blitz
        20: MinigolfShot(z: 0, angle: 0, speed: 2.28), // Gerade Bahn ohne Hindernisse
        21: MinigolfShot(z: -0.15, angle: 20, speed: 2.3), // Schräger Kreis ohne Hindernisse
        22: MinigolfShot(z: 0, angle: 0, speed: 2.5), // Plateau
        23: MinigolfShot(z: 0.02, angle: -0.3, speed: 2.44), // Auflaufkeil mit Zielfenster
        24: MinigolfShot(z: -0.03, angle: 0.2, speed: 3.08), // Steilschräge ohne Hindernisse
        25: MinigolfShot(z: -0.28, angle: 6.8, speed: 2.88), // Schräger Kreis mit V-Hindernis
        26: MinigolfShot(z: -0.03, angle: 0.3, speed: 2.56), // Gerade Bahn mit Rampe
        27: MinigolfShot(z: -0.08, angle: 11.3, speed: 2.36), // Raute
        28: MinigolfShot(z: 0, angle: 0, speed: 2.74) // Gerade Bahn mit Zielhügel
    ]
}
