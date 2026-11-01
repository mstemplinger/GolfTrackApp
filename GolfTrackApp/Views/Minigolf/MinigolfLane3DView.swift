import SceneKit
import SwiftUI

/// Drehbares 3D-Modell einer Normbahn. Ein Finger dreht, zwei Finger zoomen
/// und verschieben, der Knopf oben rechts springt zurück.
struct MinigolfLane3DView: View {
    let lane: MinigolfStandardLane
    var showsIdealLine: Bool = true

    @State private var model: MinigolfLaneModel?
    @State private var resetToken = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let model {
                SceneView(scene: model.scene,
                          pointOfView: model.cameraNode,
                          options: [.allowsCameraControl],
                          antialiasingMode: .multisampling4X)
                    .id(resetToken)
            } else {
                Color(AppTheme.cardDark)
            }

            Button {
                resetCamera()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(.black.opacity(0.35), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(8)
            .accessibilityLabel("Ansicht zurücksetzen")
        }
        .task(id: lane.id) {
            let built = MinigolfLaneModel(lane: lane)
            built.setIdealLineVisible(showsIdealLine)
            model = built
        }
        .onChange(of: showsIdealLine) { _, visible in
            model?.setIdealLineVisible(visible)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("3D-Modell der Bahn \(lane.name)")
    }

    private func resetCamera() {
        Haptics.tap()
        model?.resetCamera()
        resetToken += 1
    }
}

/// Vollbild-Ansicht des 3D-Modells.
struct MinigolfLane3DFullscreen: View {
    let lane: MinigolfStandardLane
    @Binding var showsIdealLine: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            MinigolfLane3DView(lane: lane, showsIdealLine: showsIdealLine)
                .ignoresSafeArea()

            HStack(spacing: 10) {
                Text("\(lane.normNumber). \(lane.name)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.35), in: Capsule())
                Spacer(minLength: 0)
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.35), in: Circle())
                }
                .accessibilityLabel("Schließen")
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                MinigolfIdealLineToggle(isOn: $showsIdealLine)
                Text("Ein Finger dreht, zwei Finger zoomen und verschieben.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.bottom, 20)
        }
        .background(AppTheme.cardDark)
        .preferredColorScheme(.dark)
    }
}

/// Schalter für die Idealspur – als Kapsel, passend zum 3D-Modell.
struct MinigolfIdealLineToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            Haptics.selection()
            isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "eye.fill" : "eye.slash")
                Text("Idealspur")
            }
            .font(.caption.bold())
            .foregroundStyle(isOn ? Color.black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isOn ? Color(MinigolfLaneModel.idealColor) : Color.black.opacity(0.35),
                        in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? Text("an") : Text("aus"))
    }
}

extension MinigolfLaneModel {
    /// Farbe der Idealspur, auch für Legende und Schalter.
    static var idealColor: UIColor { UIColor(red: 0.42, green: 0.86, blue: 1.0, alpha: 1) }
}

#Preview {
    MinigolfLane3DView(lane: MinigolfStandardLanes.all[1])
        .frame(height: 280)
        .preferredColorScheme(.dark)
}
