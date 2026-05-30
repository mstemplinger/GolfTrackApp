import SwiftUI

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

func golfScoreColor(_ diff: Int?) -> Color {
    guard let diff else { return .primary }
    if diff < 0 { return AppTheme.gold }
    if diff == 0 { return .primary }
    return diff == 1 ? .orange : .red
}
