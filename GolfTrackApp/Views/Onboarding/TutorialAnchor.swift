import SwiftUI

// MARK: - Anchor identifiers

enum TutorialAnchor: String {
    case newRoundButton   = "newRoundButton"
    case dashboardCards   = "dashboardCards"
    case profileHeader    = "profileHeader"
    case handicapCard     = "handicapCard"
}

// MARK: - PreferenceKey

struct TutorialFrameKey: PreferenceKey {
    typealias Value = [String: CGRect]
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - View modifier helper

extension View {
    /// Meldet den eigenen Frame (im CoordinateSpace "screen") an TutorialFrameKey.
    func tutorialAnchor(_ id: TutorialAnchor) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: TutorialFrameKey.self,
                    value: [id.rawValue: geo.frame(in: .named("screen"))]
                )
            }
        )
    }
}
