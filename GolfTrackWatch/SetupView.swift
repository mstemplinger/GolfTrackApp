import SwiftUI

// MARK: - Setup: Anzahl Löcher wählen

struct SetupView: View {
    @State private var model: WatchRoundModel?
    @State private var selectedHoles: Int = 18

    var body: some View {
        if let model {
            StrokeTrackerView(model: model) {
                self.model = nil
            }
        } else {
            VStack(spacing: 10) {
                // Logo + Title
                HStack(spacing: 6) {
                    Image(systemName: "figure.golf")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.79, green: 0.66, blue: 0.30))
                    Text("GolfTrack")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)

                Text("Neue Runde")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Löcher Auswahl
                HStack(spacing: 8) {
                    holeButton(9)
                    holeButton(18)
                }

                // Starten
                Button {
                    model = WatchRoundModel(holes: selectedHoles)
                } label: {
                    Text("Starten")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.79, green: 0.66, blue: 0.30))
                        .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
        }
    }

    private func holeButton(_ count: Int) -> some View {
        Button {
            selectedHoles = count
            WKInterfaceDevice.current().play(.click)
        } label: {
            Text("\(count)")
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    selectedHoles == count
                        ? Color(red: 0.79, green: 0.66, blue: 0.30).opacity(0.25)
                        : Color.white.opacity(0.1)
                )
                .foregroundStyle(
                    selectedHoles == count
                        ? Color(red: 0.79, green: 0.66, blue: 0.30)
                        : .secondary
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            selectedHoles == count
                                ? Color(red: 0.79, green: 0.66, blue: 0.30)
                                : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// WKInterfaceDevice import helper
import WatchKit
