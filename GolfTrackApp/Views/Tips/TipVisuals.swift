import SwiftUI

// MARK: - TipVisual

/// Animierte Grafik, die einen Tipp in der Detailansicht veranschaulicht.
enum TipVisual {
    // Anfänger
    case grip, stance, eyeOnBall, tempo, chip
    // Technik
    case spineAxis, hipRotation, weightShift, swingPath, impact
    // Mental Game
    case preShotRoutine, oneShot, acceptBogey, visualization, pressure
    // Strategie
    case courseManagement, handicapStrokes, wind, puttStrategy, riskReward

    @ViewBuilder
    func view(color: Color) -> some View {
        switch self {
        case .grip:             GripVisual(color: color)
        case .stance:           StanceVisual(color: color)
        case .eyeOnBall:        EyeOnBallVisual(color: color)
        case .tempo:            TempoVisual(color: color)
        case .chip:             ChipVisual(color: color)
        case .spineAxis:        SpineAxisVisual(color: color)
        case .hipRotation:      HipRotationVisual(color: color)
        case .weightShift:      WeightShiftVisual(color: color)
        case .swingPath:        SwingPathVisual(color: color)
        case .impact:           ImpactVisual(color: color)
        case .preShotRoutine:   PreShotRoutineVisual(color: color)
        case .oneShot:          OneShotVisual(color: color)
        case .acceptBogey:      AcceptBogeyVisual(color: color)
        case .visualization:    VisualizationVisual(color: color)
        case .pressure:         PressureVisual(color: color)
        case .courseManagement: CourseManagementVisual(color: color)
        case .handicapStrokes:  HandicapStrokesVisual(color: color)
        case .wind:             WindVisual(color: color)
        case .puttStrategy:     PuttStrategyVisual(color: color)
        case .riskReward:       RiskRewardVisual(color: color)
        }
    }
}

// MARK: - Gewichtsverlagerung

/// Golfer frontal gesehen (Rechtshänder, Ziel rechts im Bild). Drei Phasen laufen
/// automatisch durch; Antippen einer Phase hält die Animation dort an.
private struct WeightShiftVisual: View {
    let color: Color

    private struct Phase {
        let name: LocalizedStringKey
        let hint: LocalizedStringKey
        let lead: Int          // Prozent Gewicht auf dem vorderen Fuß
        let pose: GolferPose
    }

    private let phases: [Phase] = [
        Phase(name: "Ansprechen", hint: "Gewicht gleich verteilt",
              lead: 50, pose: .address),
        Phase(name: "Rückschwung", hint: "Aufs hintere Bein laden",
              lead: 30, pose: .top),
        Phase(name: "Finish", hint: "Alles aufs vordere Bein",
              lead: 90, pose: .finished),
    ]

    @State private var index = 0
    @State private var autoPlay = true

    private var phase: Phase { phases[index] }

    var body: some View {
        VStack(spacing: 16) {
            stage
                .frame(height: 250)

            pressureBar

            HStack(spacing: 8) {
                ForEach(phases.indices, id: \.self) { i in
                    Button {
                        Haptics.selection()
                        autoPlay = false
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { index = i }
                    } label: {
                        Text(phases[i].name)
                            .font(.caption.bold())
                            .foregroundStyle(i == index ? AppTheme.bg : AppTheme.textSec)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(i == index ? color : Color.white.opacity(0.07),
                                        in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .task(id: autoPlay) {
            while autoPlay && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.2))
                guard autoPlay, !Task.isCancelled else { break }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.82)) {
                    index = (index + 1) % phases.count
                }
            }
        }
    }

    // Bühne mit Golfer, Boden, Druckpunkten unter den Füßen

    private var stage: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let ground = geo.size.height - 38
            let center = w / 2
            let trailX = center - 46, leadX = center + 46
            let trail = Double(100 - phase.lead) / 100, lead = Double(phase.lead) / 100

            ZStack {
                // Rasen
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [AppTheme.green.opacity(0.0), AppTheme.green.opacity(0.35)],
                                         startPoint: .top, endPoint: .bottom))

                Path { p in
                    p.move(to: CGPoint(x: 12, y: ground))
                    p.addLine(to: CGPoint(x: w - 12, y: ground))
                }
                .stroke(Color.white.opacity(0.25), lineWidth: 1)

                // Druck-Glühen unter den Füßen
                pressureGlow(amount: trail).position(x: trailX, y: ground)
                pressureGlow(amount: lead).position(x: leadX, y: ground)

                // Ball (verschwindet nach dem Treffer)
                Circle()
                    .fill(.white)
                    .frame(width: 9, height: 9)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    .position(x: center, y: ground - 4.5)
                    .opacity(phase.pose.finish > 0.5 ? 0 : 1)

                GolferFigure(pose: phase.pose, center: center, ground: ground, accent: color)

                // Zielrichtung
                HStack(spacing: 4) {
                    Text("Ziel")
                    Image(systemName: "arrow.right")
                }
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.textTer)
                .position(x: w - 36, y: 16)

                // Prozentwerte unter den Füßen
                percentLabel(Int((trail * 100).rounded()), caption: "hinten")
                    .position(x: trailX, y: ground + 22)
                percentLabel(phase.lead, caption: "vorne")
                    .position(x: leadX, y: ground + 22)
            }
        }
    }

    private func pressureGlow(amount: Double) -> some View {
        Ellipse()
            .fill(RadialGradient(colors: [color.opacity(0.9), color.opacity(0)],
                                 center: .center, startRadius: 0, endRadius: 40))
            .frame(width: 30 + 60 * amount, height: 10 + 14 * amount)
            .opacity(0.25 + 0.75 * amount)
    }

    private func percentLabel(_ value: Int, caption: LocalizedStringKey) -> some View {
        VStack(spacing: 0) {
            Text("\(value) %")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(AppTheme.text)
                .contentTransition(.numericText(value: Double(value)))
            Text(caption)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTer)
        }
        .fixedSize()
    }

    // Balken: hinten | vorne

    private var pressureBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let trailWidth = geo.size.width * CGFloat(100 - phase.lead) / 100
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.22))
                        .frame(width: max(trailWidth - 1, 0))
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color)
                }
            }
            .frame(height: 10)

            HStack {
                Text("Hinteres Bein")
                Spacer()
                Text(phase.hint)
                    .foregroundStyle(color)
                    .id(index)
                    .transition(.opacity)
                Spacer()
                Text("Vorderes Bein")
            }
            .font(.caption2)
            .foregroundStyle(AppTheme.textTer)
        }
    }
}

// MARK: - Golfer-Figur

/// Pose als animierbare Werte: Hüftversatz in pt, Arm- und Schlägerwinkel in Grad
/// (90° = senkrecht nach unten), `finish` 0…1 hebt die hintere Ferse.
struct GolferPose: Equatable {
    var hipShift: Double
    var arm: Double
    var club: Double
    var finish: Double
}

/// Gelenkpunkte der Figur, aus der Pose berechnet.
struct GolferJoints {
    let trailAnkle, leadAnkle, trailKnee, leadKnee, trailHip, leadHip: CGPoint
    let trailShoulder, leadShoulder, neck, head, trailElbow, leadElbow, hands, clubHead: CGPoint

    init(pose: GolferPose, center: CGFloat, ground: CGFloat) {
        let heel = pose.finish * 9
        trailAnkle = CGPoint(x: center - 44 + pose.finish * 12, y: ground - 6 - heel)
        leadAnkle  = CGPoint(x: center + 44, y: ground - 6)

        let hip = CGPoint(x: center + pose.hipShift, y: ground - 86)
        trailHip = CGPoint(x: hip.x - 10, y: hip.y)
        leadHip  = CGPoint(x: hip.x + 10, y: hip.y)
        // Knie leicht gebeugt; im Finish knickt das hintere Knie zum Ziel ein
        trailKnee = CGPoint(x: (trailAnkle.x + trailHip.x) / 2 + 3 + pose.finish * 16, y: ground - 46)
        leadKnee  = CGPoint(x: (leadAnkle.x + leadHip.x) / 2 - 3, y: ground - 46)

        // Oberkörper folgt der Hüfte nur zum Teil, der Kopf bleibt fast ruhig
        let chest = CGPoint(x: center + pose.hipShift * 0.35, y: ground - 140)
        trailShoulder = CGPoint(x: chest.x - 17, y: chest.y)
        leadShoulder  = CGPoint(x: chest.x + 17, y: chest.y)
        neck = CGPoint(x: chest.x, y: chest.y - 6)
        head = CGPoint(x: chest.x - pose.hipShift * 0.1, y: chest.y - 20)

        func point(from p: CGPoint, angle: Double, length: CGFloat) -> CGPoint {
            let r = angle * .pi / 180
            return CGPoint(x: p.x + cos(r) * length, y: p.y + sin(r) * length)
        }
        hands = point(from: CGPoint(x: chest.x, y: chest.y + 4), angle: pose.arm, length: 62)
        clubHead = point(from: hands, angle: pose.club, length: 70)

        // Ellbogen: Mitte zwischen Schulter und Händen, leicht nach außen
        trailElbow = CGPoint(x: (trailShoulder.x + hands.x) / 2 - 3, y: (trailShoulder.y + hands.y) / 2)
        leadElbow  = CGPoint(x: (leadShoulder.x + hands.x) / 2 + 3, y: (leadShoulder.y + hands.y) / 2)
    }
}

/// Golfer mit Kleidung: Polo, Hose, Kappe, Handschuh, Schuhe. Als `Animatable`
/// zeichnet SwiftUI jede Zwischenpose neu.
struct GolferFigure: View, Animatable {
    var pose: GolferPose
    let center: CGFloat
    let ground: CGFloat
    let accent: Color

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>> {
        get { AnimatablePair(AnimatablePair(pose.hipShift, pose.arm), AnimatablePair(pose.club, pose.finish)) }
        set {
            pose.hipShift = newValue.first.first; pose.arm = newValue.first.second
            pose.club = newValue.second.first; pose.finish = newValue.second.second
        }
    }

    private let shirt     = Color(white: 0.96)
    private let shirtDark = Color(white: 0.80)
    private let pants     = Color(red: 0.24, green: 0.27, blue: 0.33)
    private let pantsDark = Color(red: 0.18, green: 0.20, blue: 0.25)
    private let skin      = Color(red: 0.92, green: 0.74, blue: 0.60)
    private let shoe      = Color(white: 0.98)

    var body: some View {
        Canvas { ctx, _ in
            let j = GolferJoints(pose: pose, center: center, ground: ground)

            func limb(_ pts: [CGPoint], _ width: CGFloat, _ color: Color) {
                var p = Path(); p.addLines(pts)
                ctx.stroke(p, with: .color(color),
                           style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }

            // Schatten am Boden
            let shadowW: CGFloat = 120
            ctx.fill(Path(ellipseIn: CGRect(x: center - shadowW / 2 + pose.hipShift * 0.5, y: ground - 3,
                                            width: shadowW, height: 7)),
                     with: .color(.black.opacity(0.25)))

            // Schläger hinter den Armen
            limb([j.hands, j.clubHead], 2.6, Color(white: 0.75))
            let r = atan2(j.clubHead.y - j.hands.y, j.clubHead.x - j.hands.x)
            var head = Path()
            head.addRoundedRect(in: CGRect(x: -5, y: -3.5, width: 12, height: 7), cornerSize: CGSize(width: 3, height: 3))
            ctx.fill(head.applying(CGAffineTransform(rotationAngle: r)
                .concatenating(CGAffineTransform(translationX: j.clubHead.x, y: j.clubHead.y))),
                     with: .color(accent))

            // Beine: hinteres etwas dunkler für Tiefe
            limb([j.trailHip, j.trailKnee, j.trailAnkle], 15, pantsDark)
            limb([j.leadHip, j.leadKnee, j.leadAnkle], 15, pants)

            // Schuhe
            for (ankle, dir, lift) in [(j.trailAnkle, -1.0, pose.finish), (j.leadAnkle, 1.0, 0.0)] {
                var shoePath = Path()
                shoePath.addRoundedRect(in: CGRect(x: ankle.x - 10 + dir * 3, y: ankle.y - 1, width: 20, height: 9),
                                        cornerSize: CGSize(width: 4.5, height: 4.5))
                let tilt = CGAffineTransform(translationX: ankle.x, y: ankle.y + 4)
                    .rotated(by: -dir * lift * 0.9)
                    .translatedBy(x: -ankle.x, y: -(ankle.y + 4))
                ctx.fill(shoePath.applying(tilt), with: .color(shoe))
            }

            // Oberkörper: Polo als Trapez von Schultern zur Hüfte
            var torso = Path()
            torso.move(to: CGPoint(x: j.trailShoulder.x - 2, y: j.trailShoulder.y - 2))
            torso.addLine(to: CGPoint(x: j.leadShoulder.x + 2, y: j.leadShoulder.y - 2))
            torso.addLine(to: CGPoint(x: j.leadHip.x + 4, y: j.leadHip.y + 2))
            torso.addLine(to: CGPoint(x: j.trailHip.x - 4, y: j.trailHip.y + 2))
            torso.closeSubpath()
            ctx.fill(torso, with: .color(shirt))
            ctx.stroke(torso, with: .color(shirt), style: StrokeStyle(lineWidth: 8, lineJoin: .round))
            // Gürtel
            limb([CGPoint(x: j.trailHip.x - 6, y: j.trailHip.y + 1), CGPoint(x: j.leadHip.x + 6, y: j.leadHip.y + 1)],
                 4, Color(white: 0.2))

            // Hals und Kopf mit Kappe
            limb([j.neck, CGPoint(x: j.head.x, y: j.head.y + 8)], 8, skin)
            ctx.fill(Path(ellipseIn: CGRect(x: j.head.x - 10, y: j.head.y - 11, width: 20, height: 22)),
                     with: .color(skin))
            var cap = Path()
            cap.addArc(center: CGPoint(x: j.head.x, y: j.head.y - 2), radius: 10.5,
                       startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            cap.closeSubpath()
            ctx.fill(cap, with: .color(accent))
            limb([CGPoint(x: j.head.x - 11, y: j.head.y - 2), CGPoint(x: j.head.x + 11, y: j.head.y - 2)], 3, accent)

            // Arme: Ärmel oben, Unterarm, Handschuh an den Händen
            for (shoulder, elbow, sleeve) in [(j.trailShoulder, j.trailElbow, shirtDark), (j.leadShoulder, j.leadElbow, shirt)] {
                limb([shoulder, elbow, j.hands], 8.5, skin)
                let sleeveEnd = CGPoint(x: shoulder.x + (elbow.x - shoulder.x) * 0.55,
                                        y: shoulder.y + (elbow.y - shoulder.y) * 0.55)
                limb([shoulder, sleeveEnd], 11, sleeve)
            }
            ctx.fill(Path(ellipseIn: CGRect(x: j.hands.x - 6, y: j.hands.y - 6, width: 12, height: 12)),
                     with: .color(.white))
        }
    }
}

#Preview {
    TipVisual.weightShift.view(color: AppTheme.gold)
        .padding()
        .background(AppTheme.bg)
}
