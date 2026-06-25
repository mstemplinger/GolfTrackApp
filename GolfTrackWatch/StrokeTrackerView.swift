import SwiftUI
import WatchKit

private let gold = Color(red: 0.79, green: 0.66, blue: 0.30)
private let darkBg = Color(red: 0.06, green: 0.14, blue: 0.08)

// MARK: - Main stroke tracker

struct StrokeTrackerView: View {
    @Bindable var model: WatchRoundModel
    let onFinish: () -> Void

    // Digital Crown
    @State private var crownValue: Double = 0
    @State private var lastCrownValue: Double = 0
    @FocusState private var crownFocused: Bool

    var body: some View {
        if model.isFinished {
            RoundSummaryView(model: model, onNewRound: onFinish)
        } else {
            trackerBody
        }
    }

    private var trackerBody: some View {
        VStack(spacing: 0) {

            // Hole indicator
            HStack {
                Button { model.previousHole() } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                        .foregroundStyle(model.currentHoleIndex > 0 ? gold : .clear)
                }
                .buttonStyle(.plain)
                .frame(width: 24)

                Spacer()
                Text("Loch \(model.currentHole) / \(model.holes)")
                    .font(.caption2.bold())
                    .foregroundStyle(gold)
                Spacer()

                // Progress dots
                Text("\(model.totalStrokes) ges.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            Spacer()

            // Big stroke number
            Text("\(model.currentStrokes)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.15), value: model.currentStrokes)
                .focusable()
                .focused($crownFocused)
                .digitalCrownRotation(
                    $crownValue,
                    from: 0, through: 20, by: 1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: crownValue) { _, new in
                    let delta = Int(new) - Int(lastCrownValue)
                    if delta > 0 { model.increment() }
                    else if delta < 0 { model.decrement() }
                    lastCrownValue = new
                }

            Text("Schläge")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            // − / + buttons
            HStack(spacing: 12) {
                Button {
                    model.decrement()
                    crownValue = Double(model.currentStrokes)
                    lastCrownValue = crownValue
                } label: {
                    Image(systemName: "minus")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(model.currentStrokes == 0)

                Button {
                    model.increment()
                    crownValue = Double(model.currentStrokes)
                    lastCrownValue = crownValue
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(gold.opacity(0.85))
                        .foregroundStyle(darkBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .frame(height: 44)
            .padding(.horizontal, 4)

            // Next hole button
            Button {
                model.nextHole()
                crownValue = Double(model.currentStrokes)
                lastCrownValue = crownValue
                crownFocused = true
            } label: {
                HStack(spacing: 4) {
                    Text(model.currentHole == model.holes ? "Abschließen" : "Nächstes Loch")
                        .font(.caption.bold())
                    Image(systemName: model.currentHole == model.holes ? "checkmark" : "arrow.right")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
        }
        .onAppear {
            crownValue = Double(model.currentStrokes)
            lastCrownValue = crownValue
            crownFocused = true
        }
        .onChange(of: model.currentHoleIndex) { _, _ in
            crownValue = Double(model.currentStrokes)
            lastCrownValue = crownValue
        }
    }
}
