import SwiftUI
import WatchKit

// MARK: - Farbkonstanten

private let gold   = Color(red: 0.79, green: 0.66, blue: 0.30)
private let darkBg = Color(red: 0.06, green: 0.14, blue: 0.08)
private let rowBg  = Color(red: 0.10, green: 0.20, blue: 0.12)

// MARK: - Main stroke tracker

struct StrokeTrackerView: View {
    @ObservedObject var model: WatchRoundModel
    let onFinish: () -> Void

    // Schlag-GPS-Erfassung
    @State private var showShotTracker = false

    // Auto-Erkennung
    @StateObject private var locationService = WatchLocationService()
    @State private var showUndoBanner = false

    var body: some View {
        if model.isFinished {
            RoundSummaryView(model: model, onNewRound: onFinish)
        } else {
            trackerBody
                .background(darkBg)
                .sheet(isPresented: $showShotTracker) {
                    WatchShotView(holeIndex: model.currentHoleIndex) {
                        showShotTracker = false
                    }
                }
                .onAppear {
                    locationService.start()
                    model.linkLocationService(locationService)
                    if model.autoDetectEnabled { model.swingDetector.start() }
                }
                .onDisappear {
                    model.swingDetector.stop()
                }
                .onChange(of: model.lastAutoSwingDate) { _, _ in
                    showUndoBanner = true
                    Task {
                        try? await Task.sleep(for: .seconds(4))
                        showUndoBanner = false
                    }
                }
        }
    }

    private var trackerBody: some View {
        VStack(spacing: 0) {

            // ── Status-Leiste ──────────────────────────────────────
            HStack(alignment: .center, spacing: 0) {

                // Links: LIVE (erstes Loch) oder ← ZURÜCK
                if model.currentHoleIndex > 0 {
                    Button {
                        model.previousHole()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 9, weight: .bold))
                            Text("ZURÜCK")
                                .font(.system(size: 9, weight: .semibold))
                                .kerning(0.3)
                        }
                        .foregroundStyle(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(gold)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(gold)
                            .kerning(0.3)
                    }
                }

                Spacer()

                // Loch-Info (Mitte)
                Text("LOCH \(model.currentHole) · \(model.holes)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                // Rechts: Auto-Detect-Toggle + GPS-Button
                HStack(spacing: 4) {
                    // Auto-Erkennung ein/aus
                    Button {
                        model.autoDetectEnabled.toggle()
                    } label: {
                        Image(systemName: model.autoDetectEnabled ? "figure.golf" : "figure.golf")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(model.autoDetectEnabled ? gold : Color.white.opacity(0.35))
                            .frame(width: 24, height: 24)
                            .background(
                                model.autoDetectEnabled ? gold.opacity(0.2) : rowBg,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                    }
                    .buttonStyle(.plain)

                    // Manueller GPS-Schlag
                    Button {
                        showShotTracker = true
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(gold)
                            .frame(width: 24, height: 24)
                            .background(rowBg, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 5)

            // Trennlinie
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
                .padding(.horizontal, 8)
                .padding(.top, 4)

            // ── Undo-Banner (nach auto-erkanntem Schlag) ───────────
            if showUndoBanner {
                Button {
                    model.undoLastAutoSwing()
                    showUndoBanner = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 10))
                        Text("Schlag rückgängig")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(gold, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            // ── Schlag-Zähler ──────────────────────────────────────
            VStack(spacing: 2) {
                Text("Schläge")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("\(model.currentStrokes)")
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: model.currentStrokes)
            }

            Spacer()

            // ── Buttons: − | WEITER | + ────────────────────────────
            HStack(spacing: 5) {

                // Minus
                Button {
                    model.decrement()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(rowBg)
                        .foregroundStyle(model.currentStrokes == 0 ? Color.white.opacity(0.25) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(model.currentStrokes == 0)
                .frame(width: 44)

                // Weiter / Fertig
                Button {
                    model.nextHole()
                } label: {
                    HStack(spacing: 4) {
                        Text(model.currentHole == model.holes ? "FERTIG" : "WEITER")
                            .font(.system(size: 12, weight: .bold))
                            .kerning(0.2)
                        Image(systemName: model.currentHole == model.holes ? "checkmark" : "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(gold)
                    .foregroundStyle(darkBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                // Plus
                Button {
                    model.increment()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(rowBg)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .frame(width: 44)
            }
            .frame(height: 42)
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
    }
}
