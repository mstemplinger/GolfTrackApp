import SwiftUI
import WatchKit

// MARK: - Round Model

@Observable
final class WatchRoundModel {

    var holes: Int = 18
    var strokes: [Int]          // strokes[i] = Schläge auf Loch i+1
    var currentHoleIndex: Int = 0
    var isFinished: Bool = false

    init(holes: Int = 18) {
        self.holes = holes
        self.strokes = Array(repeating: 0, count: holes)
    }

    // MARK: Current hole

    var currentHole: Int { currentHoleIndex + 1 }
    var currentStrokes: Int {
        get { strokes[currentHoleIndex] }
        set { strokes[currentHoleIndex] = max(0, newValue) }
    }

    func increment() {
        strokes[currentHoleIndex] = min(20, strokes[currentHoleIndex] + 1)
        WKInterfaceDevice.current().play(.click)
    }

    func decrement() {
        guard strokes[currentHoleIndex] > 0 else { return }
        strokes[currentHoleIndex] -= 1
        WKInterfaceDevice.current().play(.click)
    }

    func nextHole() {
        if currentHoleIndex < holes - 1 {
            currentHoleIndex += 1
            WKInterfaceDevice.current().play(.success)
        } else {
            isFinished = true
            WKInterfaceDevice.current().play(.success)
        }
    }

    func previousHole() {
        guard currentHoleIndex > 0 else { return }
        currentHoleIndex -= 1
        WKInterfaceDevice.current().play(.click)
    }

    // MARK: Stats

    var totalStrokes: Int { strokes.reduce(0, +) }

    var completedHoles: Int {
        strokes.filter { $0 > 0 }.count
    }

    func reset() {
        strokes = Array(repeating: 0, count: holes)
        currentHoleIndex = 0
        isFinished = false
    }
}
