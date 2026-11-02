import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

// Farben wie AppTheme der App – das Widget-Target sieht GolfTrackShared nicht.
private let gold     = Color(red: 0.788, green: 0.627, blue: 0.208)  // #C9A035
private let bg       = Color(red: 0.055, green: 0.153, blue: 0.094)  // #0E2718
private let card     = Color(red: 0.110, green: 0.255, blue: 0.161)  // #1C4129
private let darkText = Color(red: 0.06, green: 0.14, blue: 0.08)
private let textSec  = Color.white.opacity(0.60)

private let shotTrackerURL = URL(string: "golftrack://shottracker")!

private extension GolfRoundAttributes.ContentState {
    /// Vor dem ersten Schlag gibt es noch kein Ergebnis zum Par – sonst stünde
    /// auf einem Par 4 schon „−4“.
    var relText: String {
        guard strokes > 0 else { return "–" }
        let rel = strokes - par
        if rel == 0 { return "±0" }
        return rel > 0 ? "+\(rel)" : "\(rel)"
    }

    var relColor: Color {
        guard strokes > 0 else { return textSec }
        let rel = strokes - par
        if rel < 0 { return Color(red: 0.4, green: 0.85, blue: 0.5) }
        if rel == 0 { return .white }
        return rel <= 2 ? Color(red: 1.0, green: 0.75, blue: 0.3) : Color(red: 1.0, green: 0.4, blue: 0.4)
    }
}

/// Der große goldene Knopf: zählt einen Schlag, ohne die App zu öffnen.
private struct AddStrokeButton: View {
    var height: CGFloat = 52

    var body: some View {
        Button(intent: AddStrokeIntent()) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                Text("Schlag hinzufügen")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(darkText)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(gold, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Schaltet aufs nächste Loch – auf dem letzten Loch ausgeblendet.
private struct NextHoleButton: View {
    let state: GolfRoundAttributes.ContentState
    var height: CGFloat = 52

    var body: some View {
        if state.holeNumber < state.totalHoles {
            Button(intent: NextHoleIntent()) {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .bold))
                    Text("Loch \(state.holeNumber + 1)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(gold)
                .frame(width: 64, height: height)
                .background(card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Nächstes Loch")
        }
    }
}

// MARK: - Lock Screen Banner

struct GolfLockScreenView: View {
    let context: ActivityViewContext<GolfRoundAttributes>

    var body: some View {
        let state = context.state
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                // Links: Loch
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.golf")
                        Text(context.attributes.courseName)
                            .lineLimit(1)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(textSec)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(state.holeNumber)")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(gold)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Loch / \(state.totalHoles)")
                            Text("Par \(state.par)")
                        }
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(textSec)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Rechts: Schläge und Ergebnis zum Par
                HStack(spacing: 8) {
                    statTile(value: "\(state.strokes)", label: "Schläge", color: .white)
                    statTile(value: state.relText, label: "zum Par", color: state.relColor)
                }
            }

            HStack(spacing: 8) {
                Link(destination: shotTrackerURL) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(gold)
                        .frame(width: 52, height: 52)
                        .background(card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityLabel("Schlag aufzeichnen")
                AddStrokeButton()
                NextHoleButton(state: state)
            }
        }
        .padding(14)
    }

    private func statTile(value: String, label: LocalizedStringKey, color: Color) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(textSec)
        }
        .frame(width: 64, height: 56)
        .background(card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Widget

struct GolfLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GolfRoundAttributes.self) { context in
            GolfLockScreenView(context: context)
                .activityBackgroundTint(bg)
                .activitySystemActionForegroundColor(gold)
                .environment(\.colorScheme, .dark)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Loch")
                            .font(.caption2)
                            .foregroundStyle(textSec)
                        Text("\(context.state.holeNumber)")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(gold)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Par \(context.state.par) · \(context.attributes.courseName)")
                        .font(.caption)
                        .foregroundStyle(textSec)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Schläge")
                            .font(.caption2)
                            .foregroundStyle(textSec)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(context.state.strokes)")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                            Text(context.state.relText)
                                .font(.caption.bold())
                                .foregroundStyle(context.state.relColor)
                        }
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        AddStrokeButton(height: 46)
                        NextHoleButton(state: context.state, height: 46)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 3) {
                    Image(systemName: "figure.golf")
                    Text("\(context.state.holeNumber)")
                }
                .font(.caption.bold())
                .foregroundStyle(gold)
            } compactTrailing: {
                Text("\(context.state.strokes)")
                    .font(.caption.bold())
                    .foregroundStyle(context.state.strokes > 0 ? context.state.relColor : .white)
            } minimal: {
                Text("\(context.state.holeNumber)")
                    .font(.caption.bold())
                    .foregroundStyle(gold)
            }
            .widgetURL(URL(string: "golftrack://home"))
            .keylineTint(gold)
        }
    }
}
