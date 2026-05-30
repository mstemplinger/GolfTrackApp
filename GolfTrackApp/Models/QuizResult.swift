import SwiftData
import Foundation

@Model
class QuizResult {
    var date: Date
    var mode: String          // "smart" | "exam"
    var score: Int            // Correct answers
    var total: Int            // Total questions
    var durationSeconds: Int  // Time taken
    var passed: Bool

    init(date: Date = .now, mode: String, score: Int, total: Int, durationSeconds: Int) {
        self.date = date
        self.mode = mode
        self.score = score
        self.total = total
        self.durationSeconds = durationSeconds
        self.passed = mode == "exam" ? Double(score) / Double(total) >= 0.75 : true
    }

    var percentage: Double { total > 0 ? Double(score) / Double(total) * 100 : 0 }

    var durationFormatted: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}
