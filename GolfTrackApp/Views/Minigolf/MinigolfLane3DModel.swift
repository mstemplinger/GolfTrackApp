import SceneKit
import SwiftUI

/// Dreidimensionales Modell einer genormten Miniaturgolfbahn mit Idealspur.
///
/// Wie die Skizze schematisch, aber in Metern gebaut, damit Proportionen und
/// Höhen stimmen: Bahn 0,90 m breit, Zielkreis 1,40 m, Gesamtlänge um 6,25 m.
/// Koordinaten: x längs der Bahn (0 = Abschlag), y nach oben, z quer
/// (+z = rechte Bande in Spielrichtung, entspricht unten in der Skizze).
///
/// Geometrie und Kollisionskörper kommen aus `MinigolfLaneCourse`, die Idealspur
/// ist ein simulierter Schlag (`MinigolfBallSimulation`) mit den Schlagwerten aus
/// `MinigolfLaneShots`. Sie ist – wie der Tipp – eine Empfehlung der App, keine Regel.
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
        content.simdPosition = SIMD3(-builder.course.extent / 2, 0, 0)
        scene.rootNode.addChildNode(content)

        idealNode.addChildNode(builder.idealLine)
        idealNode.addChildNode(ballNode)
        content.addChildNode(idealNode)
        Self.animateBall(ballNode, along: builder.run.positions)

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
        floor.position.y = MinigolfLaneCourse.base - 0.001
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

    /// Spielt die simulierten Positionen in echter Zeit ab: der Ball wird
    /// langsamer, Abpraller und Flug sind so zu sehen, wie sie gerechnet wurden.
    private static func animateBall(_ ball: SCNNode, along positions: [SIMD3<Float>]) {
        guard let start = positions.first, positions.count > 1 else { return }
        let sphere = SCNSphere(radius: CGFloat(MinigolfLaneCourse.ballRadius))
        sphere.materials = [material(.white, emission: UIColor(white: 0.25, alpha: 1))]
        ball.geometry = sphere
        ball.simdPosition = start
        ball.castsShadow = true

        let dt = Double(MinigolfBallSimulation.dt)
        let duration = Double(positions.count - 1) * dt
        let roll = SCNAction.customAction(duration: duration) { node, elapsed in
            let i = min(positions.count - 1, Int(Double(elapsed) / dt))
            node.simdPosition = positions[i]
        }

        ball.runAction(.repeatForever(.sequence([
            .move(to: SCNVector3(start), duration: 0),
            .fadeIn(duration: 0.2),
            .wait(duration: 0.4),
            roll,
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

    final class Builder {
        let course: MinigolfLaneCourse
        let run: MinigolfBallRun
        let content = SCNNode()
        var idealLine = SCNNode()

        private var lane: MinigolfStandardLane { course.lane }
        private var half: Float { MinigolfLaneCourse.half }
        private var base: Float { MinigolfLaneCourse.base }
        private var bandeHeight: Float { MinigolfLaneCourse.bandeHeight }
        private var bandeThickness: Float { MinigolfLaneCourse.bandeThickness }

        private let felt     = MinigolfLaneModel.material(UIColor(red: 0.21, green: 0.55, blue: 0.33, alpha: 1))
        private let feltDark = MinigolfLaneModel.material(UIColor(red: 0.17, green: 0.47, blue: 0.28, alpha: 1))
        private let tee      = MinigolfLaneModel.material(UIColor(red: 0.62, green: 0.74, blue: 0.64, alpha: 1))
        private let bande    = MinigolfLaneModel.material(UIColor(white: 0.90, alpha: 1))
        private let obstacle = MinigolfLaneModel.material(UIColor(AppTheme.gold))
        private let holeMat  = MinigolfLaneModel.material(UIColor(white: 0.04, alpha: 1))

        static var idealColor: UIColor { MinigolfLaneModel.idealColor }

        init(lane: MinigolfStandardLane) {
            course = MinigolfLaneCourse(lane: lane)
            run = MinigolfBallSimulation.run(course, shot: MinigolfLaneShots.shot(for: lane))
        }

        // MARK: Ablauf

        func build() {
            buildLane()
            buildTarget()
            for part in course.parts { render(part) }
            buildDecorations()
            buildIdealLine(run.positions)
        }

        // MARK: Bahn

        private func buildLane() {
            let wallEnd = course.wallEnd
            let surfaceEnd = course.circleCenter == nil ? wallEnd : wallEnd + 0.02
            box(x0: 0, x1: surfaceEnd, z0: -half, z1: half, y0: base, y1: 0, felt)
            box(x0: 0, x1: 0.35, z0: -half, z1: half, y0: 0, y1: 0.003, tee)

            // Banden folgen dem Gelände, damit sie bei Steilschräge & Co. nicht im Boden stecken.
            for side: Float in [-1, 1] {
                let z = side * (half + bandeThickness / 2)
                var top: [SIMD2<Float>] = []
                var x: Float = -bandeThickness
                while x < wallEnd {
                    top.append(SIMD2(x, max(0, course.laneTerrain(max(0, x), side * half)) + bandeHeight))
                    x += 0.05
                }
                top.append(SIMD2(wallEnd, course.laneTerrain(wallEnd, side * half) + bandeHeight))
                let outline = [SIMD2<Float>(-bandeThickness, base)] + top + [SIMD2(wallEnd, base)]
                profileBody(outline, z0: z - bandeThickness / 2, z1: z + bandeThickness / 2, bande)
            }
            box(x0: -bandeThickness, x1: 0, z0: -half, z1: half, y0: base, y1: bandeHeight, bande)
        }

        private func buildTarget() {
            guard let cx = course.circleCenter else { return }
            let radius = course.circleRadius, tilt = course.tilt
            let group = SCNNode()
            group.simdPosition = SIMD3(cx, course.targetY, 0)
            group.eulerAngles.x = tilt
            content.addChildNode(group)

            // Zielkreis samt Sockel bis zum Boden. Beim geneigten Kreis reicht der
            // Sockel nur bis knapp unter die tiefste Stelle, die Bande verdeckt den Rest.
            let top: Float = 0.004
            let bottom = tilt > 0 ? -0.03 : base - course.targetY
            let disk = SCNCylinder(radius: CGFloat(radius), height: CGFloat(top - bottom))
            disk.materials = [feltDark]
            let diskNode = SCNNode(geometry: disk)
            diskNode.simdPosition = SIMD3(0, (top + bottom) / 2, 0)
            group.addChildNode(diskNode)
            if tilt > 0 {
                let socket = SCNCylinder(radius: CGFloat(radius), height: CGFloat(-base))
                socket.materials = [feltDark]
                let n = SCNNode(geometry: socket)
                n.simdPosition = SIMD3(cx, base / 2 - radius * sin(tilt), 0)
                content.addChildNode(n)
            }

            // Bande um den Kreis, offen dort, wo die Bahn einmündet.
            let open = Float.pi - asin(half / radius)
            arcWall(center: .zero, radiusIn: radius, radiusOut: radius + bandeThickness,
                    from: -open, to: open, y0: bottom - (tilt > 0 ? 0.3 : 0),
                    height: bandeHeight - bottom + (tilt > 0 ? 0.3 : 0), bande, parent: group)

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
                group.addChildNode(SCNNode(geometry: rim))
            }

            if course.holeInCircle {
                addHole(at: SIMD3(0, course.circleTerrain(0, 0) + 0.004, 0), parent: group)
            }
        }

        private func addHole(at p: SIMD3<Float>, parent: SCNNode) {
            let hole = SCNCylinder(radius: CGFloat(MinigolfLaneCourse.holeRadius), height: 0.004)
            hole.materials = [holeMat]
            let n = SCNNode(geometry: hole)
            n.simdPosition = p
            parent.addChildNode(n)
        }

        // MARK: Hindernisse

        private func material(_ surface: MinigolfLaneCourse.Surface) -> SCNMaterial {
            switch surface {
            case .felt: return felt
            case .obstacle: return obstacle
            case .bande: return bande
            }
        }

        private func render(_ part: MinigolfLaneCourse.Part) {
            switch part {
            case let .box(x0, x1, z0, z1, y0, y1, surface, chamfer):
                box(x0: x0, x1: x1, z0: z0, z1: z1, y0: y0, y1: y1, material(surface), chamfer: CGFloat(chamfer))
            case let .wall(a, b, height, thickness):
                wall(from: a, to: b, height: height, thickness: thickness)
            case let .plate(outline, y0, height):
                plate(outline, y0: y0, height: height, obstacle)
            case let .arcWall(center, rIn, rOut, from, to, y0, height):
                arcWall(center: center, radiusIn: rIn, radiusOut: rOut, from: from, to: to,
                        y0: y0, height: height, obstacle, parent: content)
            case let .pyramid(x, z, width, height):
                let p = SCNPyramid(width: CGFloat(width), height: CGFloat(height), length: CGFloat(width))
                p.materials = [obstacle]
                let n = SCNNode(geometry: p)
                n.simdPosition = SIMD3(x, 0, z)
                content.addChildNode(n)
            case let .cone(x, z, bottomRadius, topRadius, height, _):
                let cone = SCNCone(topRadius: CGFloat(topRadius), bottomRadius: CGFloat(bottomRadius),
                                   height: CGFloat(height))
                cone.materials = [obstacle]
                let n = SCNNode(geometry: cone)
                n.simdPosition = SIMD3(x, height / 2, z)
                content.addChildNode(n)
            case let .cylinder(x, z, radius, height):
                let cyl = SCNCylinder(radius: CGFloat(radius), height: CGFloat(height))
                cyl.materials = [obstacle]
                let n = SCNNode(geometry: cyl)
                n.simdPosition = SIMD3(x, height / 2, z)
                content.addChildNode(n)
            case let .ring(x, z, radius, pipe):
                let ring = SCNTorus(ringRadius: CGFloat(radius), pipeRadius: CGFloat(pipe))
                ring.materials = [obstacle]
                let n = SCNNode(geometry: ring)
                n.simdPosition = SIMD3(x, radius, z)
                n.eulerAngles.x = .pi / 2
                content.addChildNode(n)
            case let .pipe(x0, x1, axisY, inner, outer):
                let tube = SCNTube(innerRadius: CGFloat(inner), outerRadius: CGFloat(outer), height: CGFloat(x1 - x0))
                tube.materials = [obstacle]
                let n = SCNNode(geometry: tube)
                n.simdPosition = SIMD3((x0 + x1) / 2, axisY, 0)
                n.eulerAngles.z = .pi / 2
                content.addChildNode(n)
            case let .profile(outline, z0, z1, surface):
                profileBody(outline, z0: z0, z1: z1, material(surface))
            }
        }

        /// Teile ohne Einfluss auf den Ball: Netz der Sprungschanze, Löcher außerhalb des Zielkreises.
        private func buildDecorations() {
            switch course.goal {
            case .net(let netCenter, let radius):
                // Netz: Ring, darunter hängendes Netz, Mast.
                let ring = SCNTorus(ringRadius: CGFloat(radius), pipeRadius: 0.014)
                ring.materials = [obstacle]
                let ringNode = SCNNode(geometry: ring)
                ringNode.simdPosition = netCenter
                content.addChildNode(ringNode)

                let net = SCNCone(topRadius: CGFloat(radius), bottomRadius: 0.05, height: 0.3)
                let netMat = MinigolfLaneModel.material(UIColor(white: 0.95, alpha: 1))
                netMat.transparency = 0.35
                netMat.isDoubleSided = true
                net.materials = [netMat]
                let netNode = SCNNode(geometry: net)
                netNode.simdPosition = netCenter - SIMD3(0, 0.15, 0)
                content.addChildNode(netNode)

                let poleTop = netCenter.y + 0.06
                let pole = SCNCylinder(radius: 0.02, height: CGFloat(poleTop - base))
                pole.materials = [bande]
                let poleNode = SCNNode(geometry: pole)
                poleNode.simdPosition = SIMD3(netCenter.x + radius + 0.05, (poleTop + base) / 2, 0)
                content.addChildNode(poleNode)
                box(x0: netCenter.x + radius - 0.02, x1: netCenter.x + radius + 0.07, z0: -0.015, z1: 0.015,
                    y0: netCenter.y - 0.01, y1: netCenter.y + 0.02, bande)
            case .hole(let p), .chamber(let p, _, _):
                if !course.holeInCircle { addHole(at: p + SIMD3(0, 0.004, 0), parent: content) }
            }
        }

        // MARK: Idealspur

        /// Zeichnet die simulierte Bahnkurve ungeglättet nach. Punkte werden nur
        /// ausgedünnt, Knicke (Abpraller) bleiben erhalten.
        private func buildIdealLine(_ positions: [SIMD3<Float>]) {
            guard positions.count > 1 else { return }
            var samples = [positions[0]]
            let kink = cos(Float(6) * .pi / 180)
            for i in 1..<(positions.count - 1) {
                let d1 = positions[i] - positions[i - 1]
                let d2 = positions[i + 1] - positions[i]
                let l1 = simd_length(d1), l2 = simd_length(d2)
                let bent = l1 > 1e-6 && l2 > 1e-6 && simd_dot(d1, d2) / (l1 * l2) < kink
                if bent || simd_distance(samples[samples.count - 1], positions[i]) >= 0.03 {
                    samples.append(positions[i])
                }
            }
            samples.append(positions[positions.count - 1])

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

        // MARK: Bausteine

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
