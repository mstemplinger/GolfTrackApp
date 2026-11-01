import Testing
import simd
@testable import GolfTrackApp

/// Simulierte Idealspur der 28 Normbahnen: Ziel erreicht, keine Wand
/// durchdrungen, Bahn nie verlassen.
struct MinigolfLanePhysicsTests {

    private let r = MinigolfLaneCourse.ballRadius
    private let tolerance: Float = 0.002

    @Test(arguments: 1...28)
    func idealspurEndetImZiel(norm: Int) {
        let lane = MinigolfStandardLanes.all[norm - 1]
        let course = MinigolfLaneCourse(lane: lane)
        let run = MinigolfBallSimulation.run(course, shot: MinigolfLaneShots.shot(for: lane))
        #expect(run.success, "Bahn \(lane.normNumber) \(lane.name): Ball nicht im Ziel")
        if course.salto != nil || course.rinne != nil || course.pipe != nil {
            #expect(run.passedFeature, "Bahn \(lane.normNumber): vorgesehener Weg nicht genommen")
        }
        if case .net = course.goal {
            #expect(run.passedFeature, "Bahn \(lane.normNumber): nicht durch den Netzring")
        }
    }

    @Test(arguments: 1...28)
    func ballDurchdringtKeineWand(norm: Int) {
        let lane = MinigolfStandardLanes.all[norm - 1]
        let course = MinigolfLaneCourse(lane: lane)
        let run = MinigolfBallSimulation.run(course, shot: MinigolfLaneShots.shot(for: lane))
        var worst: Float = .greatestFiniteMagnitude
        var worstAt = SIMD3<Float>.zero
        // Nur das Rollen prüfen, nicht das Hineinfallen ins Loch.
        for p in run.positions.prefix(run.sinkIndex ?? run.positions.count) {
            // Im Rohr läuft der Ball geführt durch den Rohrkörper.
            if let pipe = course.pipe, p.x >= pipe.x0 - r, p.x <= pipe.x1 + r, abs(p.z) <= pipe.inner { continue }
            for col in course.colliders where col.blocks(ballBottom: p.y - r) {
                let d = col.distance(SIMD2(p.x, p.z)).0
                if d < worst { worst = d; worstAt = p }
            }
        }
        #expect(worst >= r - tolerance,
                "Bahn \(lane.normNumber): Abstand Ballmitte–Wand \(worst) m bei \(worstAt)")
    }

    @Test(arguments: 1...28)
    func ballBleibtAufDerBahn(norm: Int) {
        let lane = MinigolfStandardLanes.all[norm - 1]
        let course = MinigolfLaneCourse(lane: lane)
        let run = MinigolfBallSimulation.run(course, shot: MinigolfLaneShots.shot(for: lane))
        let inner = MinigolfLaneCourse.half - r + tolerance
        for p in run.positions {
            var inside = p.x >= r - tolerance && abs(p.z) <= inner
            if let cx = course.circleCenter, p.x > course.wallEnd {
                inside = inside || simd_distance(SIMD2(p.x, p.z), SIMD2(cx, 0)) <= course.circleRadius - r + tolerance
            }
            if !inside {
                Issue.record("Bahn \(lane.normNumber): Ball verlässt die Bahn bei \(p)")
                return
            }
        }
    }
}
