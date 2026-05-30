import ActivityKit
import WidgetKit
import SwiftUI

private let gold = Color(red: 0.85, green: 0.7, blue: 0.2)

// MARK: - Lock Screen Banner

struct GolfLockScreenView: View {
    let context: ActivityViewContext<GolfRoundAttributes>

    private var relToPar: Int { context.state.strokes - context.state.par }
    private var relText: String {
        if relToPar == 0 { return "Par" }
        return relToPar > 0 ? "+\(relToPar)" : "\(relToPar)"
    }
    private var relColor: Color {
        if relToPar < 0 { return gold }
        if relToPar == 0 { return .primary }
        return relToPar <= 2 ? .orange : .red
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left: hole
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.courseName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(context.state.holeNumber)")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .italic()
                        .foregroundStyle(gold)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Loch")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("/ \(context.state.totalHoles)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 48)
                .padding(.horizontal, 12)

            // Right: strokes + par + button
            VStack(spacing: 6) {
                HStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Text("\(context.state.strokes)")
                            .font(.title2.bold())
                        Text("Schläge")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 0) {
                        Text(relText)
                            .font(.title2.bold())
                            .foregroundStyle(relColor)
                        Text("zum Par")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "golftrack://shottracker")!) {
                    Text("Schlag tracken")
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(gold, in: Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Widget

struct GolfLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GolfRoundAttributes.self) { context in
            GolfLockScreenView(context: context)
                .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Loch")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(context.state.holeNumber)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .italic()
                            .foregroundStyle(gold)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Schläge")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(context.state.strokes)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Par \(context.state.par) · \(context.attributes.courseName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Link(destination: URL(string: "golftrack://shottracker")!) {
                            Text("Tracken")
                                .font(.caption.bold())
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(gold, in: Capsule())
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                HStack(spacing: 2) {
                    Image(systemName: "figure.golf")
                        .font(.caption2)
                        .foregroundStyle(gold)
                    Text("\(context.state.holeNumber)")
                        .font(.caption.bold())
                        .foregroundStyle(gold)
                }
            } compactTrailing: {
                Text("\(context.state.strokes)S")
                    .font(.caption.bold())
            } minimal: {
                Text("\(context.state.holeNumber)")
                    .font(.caption.bold())
                    .foregroundStyle(gold)
            }
            .widgetURL(URL(string: "golftrack://home"))
        }
    }
}
