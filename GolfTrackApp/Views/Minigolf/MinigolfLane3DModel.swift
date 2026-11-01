import SceneKit
import SwiftUI

/// Dreidimensionales Modell einer genormten Miniaturgolfbahn mit Idealspur.
///
/// Wie die Skizze schematisch, aber in Metern gebaut, damit Proportionen und
/// Höhen stimmen: Bahn 0,90 m breit, Zielkreis 1,40 m, Gesamtlänge um 6,25 m.
/// Koordinaten: x längs der Bahn (0 = Abschlag), y nach oben, z quer
/// (+z = rechte Bande in Spielrichtung, entspricht unten in der Skizze).
///
/// Die Idealspur ist – wie der Tipp – eine Empfehlung der App, keine Regel.
final class MinigolfLaneModel {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    private let idealNode = SCNNode()
    private let ballNode = SCNNode()
    private let homeTransform: simd_float4x4

    init(lane: MinigolfStandardLane) {
        let builder = Builder(lane: lane)
        builder.build()

        let content = builder.content
        // Bahnmitte in den Ursprung, damit die Kamera um die Bahn kreist.
        content.simdPosition = SIMD3(-builder.extent / 2, 0, 0)
        scene.rootNode.addChildNode(content)

        idealNode.addChildNode(builder.idealLine)
        idealNode.addChildNode(ballNode)
        content.addChildNode(idealNode)
        Self.animateBall(ballNode, along: builder.idealSamples)

        scene.background.contents = UIColor(AppTheme.cardDark)
        Self.addFloor(to: scene.rootNode)
        Self.addLights(to: scene.rootNode)

        let camera = SCNCamera()
        camera.fieldOfView = 38
        camera.zNear = 0.05
        camera.zFar = 60
        cameraNode.camera = camera
        cameraNode.simdPosition = SIMD3(-4.3, 3.3, 4.4)
        cameraNode.simdLook(at: SIMD3(0.2, 0, 0))
        homeTransform = cameraNode.simdTransform
        scene.rootNode.addChildNode(cameraNode)
    }

    func setIdealLineVisible(_ visible: Bool) {
        idealNode.isHidden = !visible
    }

    /// Kamera zurück in die Ausgangsposition schräg hinter dem Abschlag.
    func resetCamera() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cameraNode.simdTransform = homeTransform
        SCNTransaction.commit()
    }

    // MARK: - Umgebung

    private static func addFloor(to root: SCNNode) {
        let plane = SCNPlane(width: 40, height: 40)
        plane.materials = [material(UIColor(AppTheme.bg))]
        let floor = SCNNode(geometry: plane)
        floor.eulerAngles.x = -.pi / 2
        floor.position.y = Builder.base - 0.001
        root.addChildNode(floor)
    }

    private static func addLights(to root: SCNNode) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 420
        root.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 900
        sun.light?.castsShadow = true
        sun.light?.shadowMode = .deferred
        sun.light?.shadowColor = UIColor.black.withAlphaComponent(0.45)
        sun.light?.shadowRadius = 3
        sun.light?.shadowSampleCount = 8
        sun.light?.orthographicScale = 5
        sun.simdPosition = SIMD3(-2, 6, 3)
        sun.simdLook(at: .zero)
        root.addChildNode(sun)
    }

    // MARK: - Ball auf der Idealspur

    /// Der Ball läuft die Spur ab und wird dabei langsamer – wie ein ausrollender Putt.
    private static func animateBall(_ ball: SCNNode, along samples: [SIMD3<Float>]) {
        guard let start = samples.first, samples.count > 1 else { return }
        let sphere = SCNSphere(radius: CGFloat(Builder.ballRadius))
        sphere.materials = [material(.white, emission: UIColor(white: 0.25, alpha: 1))]
        ball.geometry = sphere
        ball.simdPosition = start
        ball.castsShadow = true

        var total: Float = 0
        for i in 1..<samples.count { total += simd_distance(samples[i - 1], samples[i]) }

        var moves: [SCNAction] = []
        var travelled: Float = 0
        for i in 1..<samples.count {
            let len = simd_distance(samples[i - 1], samples[i])
            travelled += len
            let speed = 0.35 + 1.7 * max(0, 1 - travelled / total)
            moves.append(.move(to: SCNVector3(samples[i]), duration: TimeInterval(len / speed)))
        }

        ball.runAction(.repeatForever(.sequence([
            .move(to: SCNVector3(start), duration: 0),
            .fadeIn(duration: 0.2),
            .wait(duration: 0.4),
            .sequence(moves),
            .wait(duration: 1.0),
            .fadeOut(duration: 0.3)
        ])))
    }

    fileprivate static func material(_ color: UIColor, emission: UIColor? = nil) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .blinn
        m.diffuse.contents = color
        m.specular.contents = UIColor(white: 0.15, alpha: 1)
        if let emission { m.emission.contents = emission }
        return m
    }
}

// MARK: - Aufbau

private extension MinigolfLaneModel {

    /// Kontrollpunkt der Idealspur. `ground` = liegt auf der Bahn, die Höhe
    /// kommt aus dem Gelände; sonst ist `p.y` die Höhe der Ballmitte (Salto, Flug).
    struct Control {
        var p: SIMD3<Float>
        var ground: Bool
    }

    final class Builder {
        static let ballRadius: Float = 0.03
        static let half: Float = 0.45            // halbe Bahnbreite
        static let bandeHeight: Float = 0.08
        static let bandeThickness: Float = 0.04
        /// Unterkante des Sockels, auf dem Bahn und Zielkreis stehen.
        static let base: Float = -0.2

        let lane: MinigolfStandardLane
        let content = SCNNode()
        var idealLine = SCNNode()
        var idealSamples: [SIMD3<Float>] = []

        /// Ende der Banden des geraden Teils.
        private(set) var wallEnd: Float = 0
        /// Mitte und Radius des Zielkreises (bei der Sprungschanze nil).
        private(set) var circleCenter: Float?
        private(set) var circleRadius: Float = 0.7
        private(set) var tilt: Float = 0
        private(set) var targetY: Float = 0
        private(set) var extent: Float = 6.25

        /// Höhe der Bahnoberfläche im geraden Teil.
        private var laneTerrain: (Float, Float) -> Float = { _, _ in 0 }
        /// Zusätzliche Höhe im Zielkreis (Zielhügel).
        private var circleTerrain: (Float, Float) -> Float = { _, _ in 0 }

        private let felt     = MinigolfLaneModel.material(UIColor(red: 0.21, green: 0.55, blue: 0.33, alpha: 1))
        private let feltDark = MinigolfLaneModel.material(UIColor(red: 0.17, green: 0.47, blue: 0.28, alpha: 1))
        private let tee      = MinigolfLaneModel.material(UIColor(red: 0.62, green: 0.74, blue: 0.64, alpha: 1))
        private let bande    = MinigolfLaneModel.material(UIColor(white: 0.90, alpha: 1))
        private let obstacle = MinigolfLaneModel.material(UIColor(AppTheme.gold))
        private let holeMat  = MinigolfLaneModel.material(UIColor(white: 0.04, alpha: 1))

        static var idealColor: UIColor { MinigolfLaneModel.idealColor }

        init(lane: MinigolfStandardLane) {
            self.lane = lane
        }

        // MARK: Ablauf

        func build() {
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
                extent = 5.1
            }
            if let cx = circleCenter {
                wallEnd = cx - (circleRadius * circleRadius - Self.half * Self.half).squareRoot()
            }

            let (controls, hole) = buildObstacles()
            buildLane()
            buildTarget(hole: hole)
            buildIdealLine(controls)
        }

        /// Höhe der Oberfläche an (x, z) – Bahn oder Zielkreis.
        func ground(_ x: Float, _ z: Float) -> Float {
            if let cx = circleCenter, x > wallEnd - 0.01 {
                let dx = x - cx
                if (dx * dx + z * z).squareRoot() <= circleRadius + 0.01 {
                    return targetY - z * sin(tilt) + circleTerrain(dx, z)
                }
            }
            return laneTerrain(x, z)
        }

        // MARK: Bahn

        private func buildLane() {
            let surfaceEnd = circleCenter == nil ? wallEnd : wallEnd + 0.02
            box(x0: 0, x1: surfaceEnd, z0: -Self.half, z1: Self.half, y0: Self.base, y1: 0, felt)
            box(x0: 0, x1: 0.35, z0: -Self.half, z1: Self.half, y0: 0, y1: 0.003, tee)

            // Banden folgen dem Gelände, damit sie bei Steilschräge & Co. nicht im Boden stecken.
            for side: Float in [-1, 1] {
                let z = side * (Self.half + Self.bandeThickness / 2)
                var top: [SIMD2<Float>] = []
                var x: Float = -Self.bandeThickness
                while x < wallEnd {
                    top.append(SIMD2(x, max(0, laneTerrain(max(0, x), side * Self.half)) + Self.bandeHeight))
                    x += 0.05
                }
                top.append(SIMD2(wallEnd, laneTerrain(wallEnd, side * Self.half) + Self.bandeHeight))
                let outline = [SIMD2<Float>(-Self.bandeThickness, Self.base)] + top + [SIMD2(wallEnd, Self.base)]
                profileBody(outline, z0: z - Self.bandeThickness / 2, z1: z + Self.bandeThickness / 2, bande)
            }
            box(x0: -Self.bandeThickness, x1: 0, z0: -Self.half, z1: Self.half,
                y0: Self.base, y1: Self.bandeHeight, bande)
        }

        private func buildTarget(hole: SIMD3<Float>?) {
            guard let cx = circleCenter else { return }
            let group = SCNNode()
            group.simdPosition = SIMD3(cx, targetY, 0)
            group.eulerAngles.x = tilt
            content.addChildNode(group)

            // Zielkreis samt Sockel bis zum Boden. Beim geneigten Kreis reicht der
            // Sockel nur bis knapp unter die tiefste Stelle, die Bande verdeckt den Rest.
            let top: Float = 0.004
            let bottom = tilt > 0 ? -0.03 : Self.base - targetY
            let disk = SCNCylinder(radius: CGFloat(circleRadius), height: CGFloat(top - bottom))
            disk.materials = [feltDark]
            let diskNode = SCNNode(geometry: disk)
            diskNode.simdPosition = SIMD3(0, (top + bottom) / 2, 0)
            group.addChildNode(diskNode)
            if tilt > 0 {
                let socket = SCNCylinder(radius: CGFloat(circleRadius), height: CGFloat(-Self.base))
                socket.materials = [feltDark]
                let n = SCNNode(geometry: socket)
                n.simdPosition = SIMD3(cx, Self.base / 2 - circleRadius * sin(tilt), 0)
                content.addChildNode(n)
            }

            // Bande um den Kreis, offen dort, wo die Bahn einmündet.
            let open = Float.pi - asin(Self.half / circleRadius)
            arcWall(center: .zero, radiusIn: circleRadius, radiusOut: circleRadius + Self.bandeThickness,
                    from: -open, to: open, y0: bottom - (tilt > 0 ? 0.3 : 0),
                    height: Self.bandeHeight - bottom + (tilt > 0 ? 0.3 : 0), bande, parent: group)

            if lane.glyph == .zielhuegel {
                let hill = SCNCone(topRadius: 0.06, bottomRadius: 0.30, height: 0.14)
                hill.materials = [obstacle]
                let n = SCNNode(geometry: hill)
                n.simdPosition = SIMD3(0, 0.07, 0)
                group.addChildNode(n)
            }
            if lane.glyph == .doppelkeile {
                // Schüssel: Rand um das Ziel.
                let rim = SCNTorus(ringRadius: 0.15, pipeRadius: 0.022)
                rim.materials = [obstacle]
                let n = SCNNode(geometry: rim)
                group.addChildNode(n)
            }

            if hole == nil {
                let local = SIMD3<Float>(0, circleTerrain(0, 0) + 0.004, 0)
                addHole(at: local, parent: group)
            }
        }

        private func addHole(at p: SIMD3<Float>, parent: SCNNode) {
            let hole = SCNCylinder(radius: 0.05, height: 0.004)
            hole.materials = [holeMat]
            let n = SCNNode(geometry: hole)
            n.simdPosition = p
            parent.addChildNode(n)
        }

        // MARK: Idealspur

        private func buildIdealLine(_ controls: [Control]) {
            let r = Self.ballRadius
            var samples: [SIMD3<Float>] = []
            // Bodenpunkte auf Ballhöhe heben, damit Übergänge zu Luftpunkten stimmen.
            let controls = controls.map { c -> Control in
                guard c.ground else { return c }
                return Control(p: SIMD3(c.p.x, ground(c.p.x, c.p.z) + r, c.p.z), ground: true)
            }
            let n = controls.count
            for i in 0..<(n - 1) {
                let p0 = controls[max(i - 1, 0)].p
                let p1 = controls[i].p
                let p2 = controls[i + 1].p
                let p3 = controls[min(i + 2, n - 1)].p
                let onGround = controls[i].ground && controls[i + 1].ground
                let steps = max(3, Int(simd_distance(p1, p2) / 0.04))
                for s in 0..<steps {
                    let t = Float(s) / Float(steps)
                    var p = catmullRom(p0, p1, p2, p3, t)
                    if onGround { p.y = ground(p.x, p.z) + r }
                    samples.append(p)
                }
            }
            var last = controls[n - 1].p
            if controls[n - 1].ground { last.y = ground(last.x, last.z) + r }
            samples.append(last)
            idealSamples = samples

            let tube = SCNNode()
            let mat = MinigolfLaneModel.material(Self.idealColor, emission: Self.idealColor.withAlphaComponent(0.6))
            for i in 1..<samples.count {
                let a = samples[i - 1], b = samples[i]
                let len = simd_distance(a, b)
                guard len > 0.0001 else { continue }
                let cyl = SCNCylinder(radius: 0.011, height: CGFloat(len))
                cyl.radialSegmentCount = 8
                cyl.materials = [mat]
                let seg = SCNNode(geometry: cyl)
                seg.simdPosition = (a + b) / 2
                seg.simdOrientation = simd_quatf(from: SIMD3(0, 1, 0), to: simd_normalize(b - a))
                tube.addChildNode(seg)
            }
            // Startmarke am Abschlag.
            let mark = SCNTorus(ringRadius: 0.05, pipeRadius: 0.008)
            mark.materials = [mat]
            let markNode = SCNNode(geometry: mark)
            markNode.simdPosition = SIMD3(samples[0].x, 0.006, samples[0].z)
            tube.addChildNode(markNode)

            idealLine = tube.flattenedClone()
            idealLine.castsShadow = false
        }

        private func catmullRom(_ p0: SIMD3<Float>, _ p1: SIMD3<Float>, _ p2: SIMD3<Float>,
                                _ p3: SIMD3<Float>, _ t: Float) -> SIMD3<Float> {
            let t2 = t * t, t3 = t2 * t
            let a = 2 * p1
            let b = (p2 - p0) * t
            let c = (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
            let d = (3 * p1 - p0 - 3 * p2 + p3) * t3
            return 0.5 * (a + b + c + d)
        }

        // MARK: Hindernisse und Spur je Bahn

        private func g(_ x: Float, _ z: Float) -> Control { Control(p: SIMD3(x, 0, z), ground: true) }
        private func air(_ x: Float, _ y: Float, _ z: Float) -> Control { Control(p: SIMD3(x, y, z), ground: false) }

        /// Spur vom geraden Teil in den schrägen Kreis: hangaufwärts anspielen,
        /// der Ball fällt dann von oben ins Loch.
        private var tiltedFinish: [Control] {
            [g(3.1, 0), g(3.75, -0.24), g(4.25, -0.36), g(4.52, -0.22), g(4.48, -0.08), g(4.45, 0)]
        }

        private var hole: Float { circleCenter ?? 0 }

        /// Baut die Hindernisse und liefert die Kontrollpunkte der Idealspur
        /// sowie – falls das Ziel nicht im Zielkreis liegt – die Lochposition.
        private func buildObstacles() -> ([Control], SIMD3<Float>?) {
            let h = Self.half
            switch lane.glyph {
            case .keines:
                if lane.shape == .tiltedCircle {
                    return ([g(0.25, 0), g(1.5, 0)] + tiltedFinish, nil)
                }
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .pyramiden:
                pyramid(x: 2.1, z: -0.2)
                pyramid(x: 3.0, z: 0.2)
                return ([g(0.25, 0), g(1.3, 0.12), g(2.1, 0.30), g(2.55, 0), g(3.0, -0.30),
                         g(3.8, -0.15), g(4.7, -0.03), g(hole, 0)], nil)

            case .salto:
                for z: Float in [-0.08, 0.08] {
                    let ring = SCNTorus(ringRadius: 0.25, pipeRadius: 0.013)
                    ring.materials = [obstacle]
                    let n = SCNNode(geometry: ring)
                    n.simdPosition = SIMD3(2.6, 0.25, z)
                    n.eulerAngles.x = .pi / 2
                    content.addChildNode(n)
                }
                var loop: [Control] = []
                let steps = 24
                for k in 0...steps {
                    let phi = 2 * Float.pi * Float(k) / Float(steps)
                    loop.append(air(2.6 + 0.22 * sin(phi), 0.25 - 0.22 * cos(phi),
                                    -0.035 + 0.07 * Float(k) / Float(steps)))
                }
                return ([g(0.25, 0), g(1.4, 0), g(2.2, -0.02)] + loop
                        + [g(3.1, 0.03), g(4.3, 0.01), g(hole, 0)], nil)

            case .niere:
                for side: Float in [-1, 1] {
                    box(x0: 1.4, x1: 2.4, z0: side < 0 ? -0.32 : 0.09, z1: side < 0 ? -0.09 : 0.32,
                        y0: 0, y1: 0.12, obstacle, chamfer: 0.06)
                }
                box(x0: 1.45, x1: 2.35, z0: -0.1, z1: 0.1, y0: 0.08, y1: 0.12, obstacle)
                return ([g(0.25, 0), g(1.0, 0), g(2.6, 0)] + tiltedFinish, nil)

            case .doppelwellen:
                let waves: [(Float, Float, Float)] = [(2.1, 0.5, 0.05), (3.0, 0.5, 0.05)]
                laneTerrain = { x, _ in waves.reduce(0) { $0 + Self.bump(x, $1.0, $1.1, $1.2) } }
                for w in waves { bumpBody(center: w.0, width: w.1, height: w.2, z0: -h, z1: h) }
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .liegendeSchleife:
                let c = SIMD2<Float>(2.6, 0)
                arcWall(center: c, radiusIn: 0.38, radiusOut: 0.41,
                        from: 145 * .pi / 180, to: (360 + 35) * .pi / 180,
                        y0: 0, height: 0.08, obstacle, parent: content)
                let island = SCNCylinder(radius: 0.18, height: 0.08)
                island.materials = [obstacle]
                let n = SCNNode(geometry: island)
                n.simdPosition = SIMD3(c.x, 0.04, c.y)
                content.addChildNode(n)

                var loop: [Control] = []
                let steps = 20
                for k in 0...steps {
                    let a = Float.pi / 2 - 2 * Float.pi * Float(k) / Float(steps)
                    loop.append(g(c.x + 0.28 * cos(a), c.y + 0.28 * sin(a)))
                }
                return ([g(0.25, 0.08), g(1.5, 0.26)] + loop
                        + [g(3.4, 0.24), g(4.4, 0.07), g(hole, 0)], nil)

            case .bruecke, .mittelhuegel:
                let (w, ht): (Float, Float) = lane.glyph == .bruecke ? (0.9, 0.12) : (1.0, 0.08)
                laneTerrain = { x, _ in Self.bump(x, 2.6, w, ht) }
                bumpBody(center: 2.6, width: w, height: ht, z0: -h, z1: h)
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .sprungschanze:
                laneTerrain = { x, _ in x > 1.7 ? 0.25 * pow(min(1, (x - 1.7) / 0.8), 2) : 0 }
                var ramp: [SIMD2<Float>] = [SIMD2(1.7, 0)]
                for i in 1...16 {
                    let x = 1.7 + 0.8 * Float(i) / 16
                    ramp.append(SIMD2(x, laneTerrain(x, 0)))
                }
                ramp.append(SIMD2(2.5, 0))
                profileBody(ramp, z0: -h, z1: h, obstacle)

                // Netz: Ring, darunter hängendes Netz, Mast.
                let netCenter = SIMD3<Float>(4.75, 1.0, 0)
                let ring = SCNTorus(ringRadius: 0.25, pipeRadius: 0.014)
                ring.materials = [obstacle]
                let ringNode = SCNNode(geometry: ring)
                ringNode.simdPosition = netCenter
                content.addChildNode(ringNode)

                let net = SCNCone(topRadius: 0.25, bottomRadius: 0.05, height: 0.3)
                let netMat = MinigolfLaneModel.material(UIColor(white: 0.95, alpha: 1))
                netMat.transparency = 0.35
                netMat.isDoubleSided = true
                net.materials = [netMat]
                let netNode = SCNNode(geometry: net)
                netNode.simdPosition = netCenter - SIMD3(0, 0.15, 0)
                content.addChildNode(netNode)

                let pole = SCNCylinder(radius: 0.02, height: CGFloat(1.06 - Self.base))
                pole.materials = [bande]
                let poleNode = SCNNode(geometry: pole)
                poleNode.simdPosition = SIMD3(netCenter.x + 0.3, (1.06 + Self.base) / 2, 0)
                content.addChildNode(poleNode)
                box(x0: netCenter.x + 0.23, x1: netCenter.x + 0.32, z0: -0.015, z1: 0.015,
                    y0: 0.99, y1: 1.02, bande)

                // Flugbahn als quadratische Bézierkurve von der Schanze in den Ring.
                let p0 = SIMD3<Float>(2.5, 0.25 + Self.ballRadius, 0)
                let ctrl = SIMD3<Float>(3.7, 1.75, 0)
                let p2 = SIMD3<Float>(netCenter.x, netCenter.y - 0.05, 0)
                var flight: [Control] = []
                for i in 1...12 {
                    let t = Float(i) / 12
                    let p = (1 - t) * (1 - t) * p0 + 2 * t * (1 - t) * ctrl + t * t * p2
                    flight.append(Control(p: p, ground: false))
                }
                return ([g(0.25, 0), g(1.2, 0), g(2.1, 0), g(2.45, 0)] + flight, p2)

            case .zielkreisfenster:
                window(at: 4.75, from: 0, gap: 0.065)
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .auflaufkeil:
                laneTerrain = { x, _ in
                    if x < 3.7 || x > 5.0 { return 0 }
                    if x < 4.5 { return 0.08 * (x - 3.7) / 0.8 }
                    if x < 4.9 { return 0.08 }
                    return 0.08 * (5.0 - x) / 0.1
                }
                profileBody([SIMD2(3.7, 0), SIMD2(4.5, 0.08), SIMD2(4.9, 0.08), SIMD2(5.0, 0)],
                            z0: -h, z1: h, obstacle)
                window(at: 4.6, from: 0.08, gap: 0.065)
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .rohr:
                let pipe = SCNTube(innerRadius: 0.036, outerRadius: 0.05, height: 1.1)
                pipe.materials = [obstacle]
                let n = SCNNode(geometry: pipe)
                n.simdPosition = SIMD3(4.25, 0.038, 0)
                n.eulerAngles.z = .pi / 2
                content.addChildNode(n)
                box(x0: 4.22, x1: 4.28, z0: -h, z1: -0.05, y0: 0, y1: 0.12, obstacle)
                box(x0: 4.22, x1: 4.28, z0: 0.05, z1: h, y0: 0, y1: 0.12, obstacle)
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .staebe:
                for (x, side) in [(Float(1.7), Float(-1)), (2.6, 1), (3.5, -1)] {
                    let z0 = side < 0 ? -h : -0.16
                    let z1 = side < 0 ? 0.16 : h
                    box(x0: x - 0.015, x1: x + 0.015, z0: z0, z1: z1, y0: 0.01, y1: 0.06, obstacle)
                }
                return ([g(0.25, 0), g(1.0, 0.15), g(1.7, 0.30), g(2.15, 0), g(2.6, -0.30),
                         g(3.05, 0), g(3.5, 0.30), g(4.3, 0.14), g(hole, 0)], nil)

            case .labyrinth:
                let t: Float = 0.03, ht: Float = 0.08
                // Kasten mit vier Eingängen auf der Abschlagseite.
                box(x0: 2.96 - t, x1: 2.96, z0: -0.36, z1: 0.36, y0: 0, y1: ht, obstacle)
                box(x0: 2.24, x1: 2.96, z0: -0.36, z1: -0.36 + t, y0: 0, y1: ht, obstacle)
                box(x0: 2.24, x1: 2.96, z0: 0.36 - t, z1: 0.36, y0: 0, y1: ht, obstacle)
                for (z0, z1) in [(Float(-0.36), Float(-0.29)), (-0.19, -0.13), (-0.03, 0.03),
                                 (0.13, 0.19), (0.29, 0.36)] {
                    box(x0: 2.24, x1: 2.24 + t, z0: z0, z1: z1, y0: 0, y1: ht, obstacle)
                }
                // Hinter den falschen Eingängen ist zu.
                box(x0: 2.34, x1: 2.34 + t, z0: -0.30, z1: -0.02, y0: 0, y1: ht, obstacle)
                box(x0: 2.34, x1: 2.34 + t, z0: 0.18, z1: 0.30, y0: 0, y1: ht, obstacle)
                // Zielkammer in der Mitte, offen zum zweiten Eingang von rechts.
                box(x0: 2.48, x1: 2.48 + t, z0: -0.14, z1: 0.03, y0: 0, y1: ht, obstacle)
                box(x0: 2.48, x1: 2.72, z0: -0.14, z1: -0.14 + t, y0: 0, y1: ht, obstacle)
                box(x0: 2.48, x1: 2.72, z0: 0.14 - t, z1: 0.14, y0: 0, y1: ht, obstacle)
                box(x0: 2.72 - t, x1: 2.72, z0: -0.14, z1: 0.14, y0: 0, y1: ht, obstacle)
                let target = SIMD3<Float>(2.61, 0.004, 0.0)
                addHole(at: target, parent: content)
                return ([g(0.25, 0), g(1.2, 0.05), g(2.15, 0.08), g(2.5, 0.08), g(2.58, 0.03),
                         g(target.x, target.z)], target)

            case .kegel:
                for (x, z) in [(Float(2.1), Float(-0.18)), (3.1, 0.18)] {
                    let cone = SCNCone(topRadius: 0.08, bottomRadius: 0.24, height: 0.12)
                    cone.materials = [obstacle]
                    let n = SCNNode(geometry: cone)
                    n.simdPosition = SIMD3(x, 0.06, z)
                    content.addChildNode(n)
                }
                return ([g(0.25, 0), g(1.2, 0.12), g(2.1, 0.31), g(2.6, 0), g(3.1, -0.31),
                         g(4.0, -0.12), g(hole, 0)], nil)

            case .doppelkeile:
                for side: Float in [-1, 1] {
                    plate([SIMD2(2.0, side * h), SIMD2(3.3, side * h), SIMD2(3.3, side * 0.09)],
                          y0: 0, height: 0.08, obstacle)
                }
                circleTerrain = { x, z in Self.bump((x * x + z * z).squareRoot(), 0.15, 0.09, 0.04) }
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .passagen:
                box(x0: 1.9, x1: 3.6, z0: -0.015, z1: 0.015, y0: 0, y1: 0.08, obstacle)
                laneTerrain = { x, _ in Self.bump(x, 2.75, 0.5, 0.07) }
                bumpBody(center: 2.75, width: 0.5, height: 0.07, z0: -h, z1: -0.015)
                bumpBody(center: 2.75, width: 0.5, height: 0.07, z0: 0.015, z1: h)
                return ([g(0.25, 0), g(1.2, 0.12), g(1.9, 0.22), g(2.3, 0.23), g(3.2, 0.23),
                         g(3.6, 0.22), g(4.5, 0.08), g(hole, 0)], nil)

            case .vulkan:
                let c = SIMD2<Float>(3.2, 0)
                laneTerrain = { x, z in
                    let d = simd_distance(SIMD2(x, z), c)
                    return 0.18 * min(1, max(0, (0.42 - d) / 0.27))
                }
                let cone = SCNCone(topRadius: 0.15, bottomRadius: 0.42, height: 0.18)
                cone.materials = [obstacle]
                let n = SCNNode(geometry: cone)
                n.simdPosition = SIMD3(c.x, 0.09, c.y)
                content.addChildNode(n)
                let target = SIMD3<Float>(c.x, 0.184, c.y)
                addHole(at: target, parent: content)
                return ([g(0.25, 0), g(1.5, 0.15), g(2.5, 0.2), g(2.95, 0.12), g(c.x, c.y)], target)

            case .vHindernis:
                let x0: Float = lane.shape == .tiltedCircle ? 1.2 : 1.9
                let x1: Float = lane.shape == .tiltedCircle ? 2.6 : 3.7
                for side: Float in [-1, 1] {
                    wall(from: SIMD2(x0, side * h), to: SIMD2(x1, side * 0.08), height: 0.07, thickness: 0.03)
                }
                if lane.shape == .tiltedCircle {
                    return ([g(0.25, 0), g(1.5, 0)] + tiltedFinish, nil)
                }
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .winkel:
                wall(from: SIMD2(1.77, -h), to: SIMD2(3.22, 0.16), height: 0.1, thickness: 0.04)
                return ([g(0.25, -0.1), g(1.3, 0.15), g(2.3, 0.40), g(3.0, 0.33), g(3.7, 0.15),
                         g(4.6, 0.04), g(hole, 0)], nil)

            case .blitz:
                wall(from: SIMD2(1.3, -h), to: SIMD2(2.6, 0.11), height: 0.1, thickness: 0.04)
                wall(from: SIMD2(2.7, h), to: SIMD2(3.95, -0.11), height: 0.1, thickness: 0.04)
                return ([g(0.25, 0), g(1.3, 0.2), g(2.6, 0.32), g(3.3, 0), g(3.95, -0.30),
                         g(4.7, -0.12), g(hole, 0)], nil)

            case .plateau:
                let top: Float = 0.15
                laneTerrain = { x, z in
                    if x >= 3.6 && x <= 5.0 && abs(z) <= 0.35 { return top }
                    if x >= 2.8 && x < 3.6 && abs(z) <= 0.13 { return top * (x - 2.8) / 0.8 }
                    return 0
                }
                profileBody([SIMD2(2.8, 0), SIMD2(3.6, top), SIMD2(3.6, 0)], z0: -0.13, z1: 0.13, obstacle)
                box(x0: 2.8, x1: 3.6, z0: -0.16, z1: -0.13, y0: 0, y1: top + 0.04, obstacle)
                box(x0: 2.8, x1: 3.6, z0: 0.13, z1: 0.16, y0: 0, y1: top + 0.04, obstacle)
                box(x0: 3.6, x1: 5.0, z0: -0.35, z1: 0.35, y0: 0, y1: top, obstacle, chamfer: 0.02)
                let target = SIMD3<Float>(4.3, top + 0.004, 0)
                addHole(at: target, parent: content)
                return ([g(0.25, 0), g(2.0, 0), g(target.x, target.z)], target)

            case .steilschraege:
                let top: Float = 0.3
                targetY = top
                laneTerrain = { x, _ in
                    if x < 1.8 { return 0 }
                    if x < 3.8 { return top * (x - 1.8) / 2.0 }
                    return top
                }
                profileBody([SIMD2(1.8, 0), SIMD2(3.8, top), SIMD2(wallEnd + 0.02, top), SIMD2(wallEnd + 0.02, 0)],
                            z0: -h, z1: h, felt)
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .rampe:
                laneTerrain = { x, _ in
                    if x >= 2.4 && x < 3.0 { return 0.12 * (x - 2.4) / 0.6 }
                    if x >= 3.0 && x <= 3.25 { return 0.12 }
                    return 0
                }
                profileBody([SIMD2(2.4, 0), SIMD2(3.0, 0.12), SIMD2(3.25, 0.12), SIMD2(3.25, 0)],
                            z0: -h, z1: h, obstacle)
                return ([g(0.25, 0), g(hole, 0)], nil)

            case .raute:
                plate([SIMD2(2.08, 0), SIMD2(2.81, -0.36), SIMD2(3.54, 0), SIMD2(2.81, 0.36)],
                      y0: 0, height: 0.08, obstacle)
                return ([g(0.25, -0.05), g(1.3, 0.2), g(2.81, 0.41), g(3.9, 0.2), g(4.7, 0.05),
                         g(hole, 0)], nil)

            case .zielhuegel:
                circleTerrain = { x, z in
                    let d = (x * x + z * z).squareRoot()
                    return 0.14 * min(1, max(0, (0.30 - d) / 0.24))
                }
                return ([g(0.25, 0), g(hole, 0)], nil)
            }
        }

        // MARK: Bausteine

        /// Halbe Kosinuswelle der Breite `width` um `center`.
        static func bump(_ x: Float, _ center: Float, _ width: Float, _ height: Float) -> Float {
            let u = (x - center) / (width / 2)
            guard abs(u) < 1 else { return 0 }
            return height * (1 + cos(.pi * u)) / 2
        }

        private func bumpBody(center: Float, width: Float, height: Float, z0: Float, z1: Float) {
            var outline: [SIMD2<Float>] = []
            for i in 0...20 {
                let x = center - width / 2 + width * Float(i) / 20
                outline.append(SIMD2(x, Self.bump(x, center, width, height)))
            }
            profileBody(outline, z0: z0, z1: z1, obstacle)
        }

        private func pyramid(x: Float, z: Float) {
            let p = SCNPyramid(width: 0.5, height: 0.22, length: 0.5)
            p.materials = [obstacle]
            let n = SCNNode(geometry: p)
            n.simdPosition = SIMD3(x, 0, z)
            content.addChildNode(n)
        }

        /// Quermauer mit schmalem Fenster in der Mitte.
        private func window(at x: Float, from y0: Float, gap: Float) {
            box(x0: x, x1: x + 0.06, z0: -Self.half, z1: -gap, y0: 0, y1: y0 + 0.13, obstacle)
            box(x0: x, x1: x + 0.06, z0: gap, z1: Self.half, y0: 0, y1: y0 + 0.13, obstacle)
        }

        @discardableResult
        private func box(x0: Float, x1: Float, z0: Float, z1: Float, y0: Float, y1: Float,
                         _ material: SCNMaterial, chamfer: CGFloat = 0) -> SCNNode {
            let geo = SCNBox(width: CGFloat(x1 - x0), height: CGFloat(y1 - y0),
                             length: CGFloat(z1 - z0), chamferRadius: chamfer)
            geo.materials = [material]
            let n = SCNNode(geometry: geo)
            n.simdPosition = SIMD3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
            content.addChildNode(n)
            return n
        }

        /// Gerade Wand zwischen zwei Punkten der Draufsicht (x, z).
        private func wall(from a: SIMD2<Float>, to b: SIMD2<Float>, height: Float, thickness: Float) {
            let d = b - a
            let geo = SCNBox(width: CGFloat(simd_length(d)), height: CGFloat(height),
                             length: CGFloat(thickness), chamferRadius: 0)
            geo.materials = [obstacle]
            let n = SCNNode(geometry: geo)
            let mid = (a + b) / 2
            n.simdPosition = SIMD3(mid.x, height / 2, mid.y)
            n.eulerAngles.y = atan2(-d.y, d.x)
            content.addChildNode(n)
        }

        /// Körper mit Seitenprofil (x, y), quer über z0…z1 extrudiert.
        private func profileBody(_ outline: [SIMD2<Float>], z0: Float, z1: Float, _ material: SCNMaterial) {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: CGFloat(outline[0].x), y: CGFloat(outline[0].y)))
            for p in outline.dropFirst() { path.addLine(to: CGPoint(x: CGFloat(p.x), y: CGFloat(p.y))) }
            path.close()
            let shape = SCNShape(path: path, extrusionDepth: CGFloat(z1 - z0))
            shape.materials = [material]
            let n = SCNNode(geometry: shape)
            n.simdPosition = SIMD3(0, 0, (z0 + z1) / 2)
            content.addChildNode(n)
        }

        /// Flacher Körper mit Grundriss (x, z), von y0 aus `height` hoch.
        private func plate(_ outline: [SIMD2<Float>], y0: Float, height: Float, _ material: SCNMaterial,
                           parent: SCNNode? = nil) {
            let path = UIBezierPath()
            // Nach der Drehung um −90° um x wird Pfad-y zu −z.
            path.move(to: CGPoint(x: CGFloat(outline[0].x), y: CGFloat(-outline[0].y)))
            for p in outline.dropFirst() { path.addLine(to: CGPoint(x: CGFloat(p.x), y: CGFloat(-p.y))) }
            path.close()
            let shape = SCNShape(path: path, extrusionDepth: CGFloat(height))
            shape.materials = [material]
            let n = SCNNode(geometry: shape)
            n.eulerAngles.x = -.pi / 2
            n.simdPosition = SIMD3(0, y0 + height / 2, 0)
            (parent ?? content).addChildNode(n)
        }

        /// Ringförmige Wand von Winkel `from` bis `to` (0 = Spielrichtung, positiv zur rechten Bande).
        private func arcWall(center: SIMD2<Float>, radiusIn: Float, radiusOut: Float, from: Float, to: Float,
                             y0: Float, height: Float, _ material: SCNMaterial, parent: SCNNode) {
            let steps = 48
            var outer: [SIMD2<Float>] = []
            var inner: [SIMD2<Float>] = []
            for i in 0...steps {
                let a = from + (to - from) * Float(i) / Float(steps)
                outer.append(center + radiusOut * SIMD2(cos(a), sin(a)))
                inner.append(center + radiusIn * SIMD2(cos(a), sin(a)))
            }
            plate(outer + inner.reversed(), y0: y0, height: height, material, parent: parent)
        }
    }
}
