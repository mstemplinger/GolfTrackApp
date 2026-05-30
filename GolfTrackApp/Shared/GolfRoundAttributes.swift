import ActivityKit
import Foundation

/// ActivityAttributes shared between GolfTrackApp and GolfWidget.
/// This file must be added to BOTH targets.
struct GolfRoundAttributes: ActivityAttributes {

    // Static — set once when the activity starts
    var courseName: String

    // Dynamic — updated on every stroke / hole change
    struct ContentState: Codable, Hashable {
        var holeNumber: Int
        var totalHoles: Int
        var strokes: Int
        var par: Int
    }
}
