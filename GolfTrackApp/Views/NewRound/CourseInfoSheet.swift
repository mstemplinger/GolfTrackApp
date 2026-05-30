import SwiftUI

struct CourseInfoSheet: View {
    let course: Course
    @Environment(\.dismiss) private var dismiss

    private var hasHoleData: Bool { !course.hcpValues.isEmpty && !course.holeLengths.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        if hasHoleData {
                            scorecardSection
                        }
                        if !course.facilityNotes.isEmpty {
                            facilitySection
                        }
                        courseStatsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Platzinfo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
    }

    // MARK: - Scorecard section

    private var scorecardSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(icon: "tablecells", title: "Scorecard")

            VStack(spacing: 0) {
                // Table header
                tableRow(
                    hole: "Loch", hcp: "HCP", length: "Meter", par: "Par",
                    isHeader: true
                )
                Divider().background(AppTheme.cardAlt)

                // OUT holes
                ForEach(1...9, id: \.self) { h in
                    tableRow(
                        hole: "\(h)",
                        hcp: hcpText(h),
                        length: lengthText(h),
                        par: parText(h),
                        isHeader: false,
                        isMid: false
                    )
                    if h < 9 { Divider().background(AppTheme.cardAlt).padding(.leading, 16) }
                }

                // OUT sum
                sumRow(label: "OUT",
                       length: outLength,
                       par: outPar)

                Divider().background(AppTheme.cardAlt)

                // IN holes
                ForEach(10...18, id: \.self) { h in
                    tableRow(
                        hole: "\(h)",
                        hcp: hcpText(h),
                        length: lengthText(h),
                        par: parText(h),
                        isHeader: false
                    )
                    if h < 18 { Divider().background(AppTheme.cardAlt).padding(.leading, 16) }
                }

                // IN sum
                sumRow(label: "IN",
                       length: inLength,
                       par: inPar)

                Divider().background(AppTheme.cardAlt)

                // Total
                sumRow(label: "GESAMT",
                       length: totalLength,
                       par: course.totalPar,
                       isTotal: true)
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func tableRow(hole: String, hcp: String, length: String, par: String,
                          isHeader: Bool, isMid: Bool = false) -> some View {
        HStack {
            Text(hole)
                .frame(width: 44, alignment: .leading)
                .font(isHeader ? .caption.bold() : .callout)
                .foregroundStyle(isHeader ? AppTheme.textSec : AppTheme.text)
            Spacer()
            Text(hcp)
                .frame(width: 44, alignment: .center)
                .font(isHeader ? .caption.bold() : .callout)
                .foregroundStyle(isHeader ? AppTheme.textSec : AppTheme.textSec)
            Text(length)
                .frame(width: 64, alignment: .trailing)
                .font(isHeader ? .caption.bold() : .callout)
                .foregroundStyle(isHeader ? AppTheme.textSec : AppTheme.text)
            Text(par)
                .frame(width: 40, alignment: .trailing)
                .font(isHeader ? .caption.bold() : .callout.bold())
                .foregroundStyle(isHeader ? AppTheme.textSec : parColor(par))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func sumRow(label: String, length: String?, par: Int?, isTotal: Bool = false) -> some View {
        HStack {
            Text(label)
                .frame(width: 44, alignment: .leading)
                .font(.caption.bold())
                .foregroundStyle(isTotal ? AppTheme.gold : AppTheme.textSec)
            Spacer()
            Text("")
                .frame(width: 44, alignment: .center)
            Text(length ?? "–")
                .frame(width: 64, alignment: .trailing)
                .font(.caption.bold())
                .foregroundStyle(isTotal ? AppTheme.gold : AppTheme.textSec)
            Text(par != nil ? "\(par!)" : "–")
                .frame(width: 40, alignment: .trailing)
                .font(.caption.bold())
                .foregroundStyle(isTotal ? AppTheme.gold : AppTheme.textSec)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isTotal ? AppTheme.gold.opacity(0.07) : AppTheme.cardAlt.opacity(0.5))
    }

    private func parColor(_ par: String) -> Color {
        switch par {
        case "3": return .blue
        case "5": return AppTheme.gold
        default: return AppTheme.text
        }
    }

    // MARK: - Facility section

    private var facilitySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(icon: "info.circle", title: "Platzhinweise")

            VStack(alignment: .leading, spacing: 0) {
                let lines = course.facilityNotes
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }

                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    let (icon, text) = parseFacilityLine(line)
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.gold)
                            .frame(width: 20)
                            .padding(.top, 1)
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    if i < lines.count - 1 {
                        Divider().background(AppTheme.cardAlt).padding(.leading, 48)
                    }
                }
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func parseFacilityLine(_ line: String) -> (String, String) {
        if line.lowercased().contains("toilette") { return ("figure.walk", line) }
        if line.lowercased().contains("trinkwasser") { return ("drop.fill", line) }
        if line.lowercased().contains("defibrillator") { return ("heart.fill", line) }
        if line.lowercased().contains("entfernungs") { return ("ruler", line) }
        if line.lowercased().contains("biotop") { return ("leaf.fill", line) }
        if line.lowercased().contains("platzregel") { return ("exclamationmark.triangle.fill", line) }
        if line.lowercased().contains("lochspiel") || line.lowercased().contains("zählspiel") { return ("flag.fill", line) }
        if line.lowercased().contains("kontakt") || line.lowercased().contains("www.") { return ("globe", line) }
        return ("info.circle", line)
    }

    // MARK: - Course stats section

    private var courseStatsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(icon: "chart.bar", title: "Platzdaten")

            HStack(spacing: 0) {
                statCell(value: "\(course.numberOfHoles)", label: "Löcher")
                Divider().frame(height: 40)
                statCell(value: "Par \(course.totalPar)", label: "Gesamt")
                Divider().frame(height: 40)
                statCell(value: String(format: "%.1f", course.courseRating), label: "CR")
                Divider().frame(height: 40)
                statCell(value: "\(course.slopeRating)", label: "Slope")
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Section header

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.gold)
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSec)
                .tracking(1.0)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
        .padding(.top, 4)
    }

    // MARK: - Computed values

    private func hcpText(_ hole: Int) -> String {
        let i = hole - 1
        guard i < course.hcpValues.count else { return "–" }
        return "\(course.hcpValues[i])"
    }

    private func lengthText(_ hole: Int) -> String {
        let i = hole - 1
        guard i < course.holeLengths.count else { return "–" }
        return "\(course.holeLengths[i]) m"
    }

    private func parText(_ hole: Int) -> String {
        let i = hole - 1
        guard i < course.parValues.count else { return "–" }
        return "\(course.parValues[i])"
    }

    private var outLength: String? {
        guard course.holeLengths.count >= 9 else { return nil }
        let sum = course.holeLengths.prefix(9).reduce(0, +)
        return "\(sum) m"
    }

    private var inLength: String? {
        guard course.holeLengths.count >= 18 else { return nil }
        let sum = course.holeLengths.dropFirst(9).reduce(0, +)
        return "\(sum) m"
    }

    private var totalLength: String? {
        guard course.holeLengths.count >= 18 else { return nil }
        let sum = course.holeLengths.reduce(0, +)
        return "\(sum) m"
    }

    private var outPar: Int? {
        guard course.parValues.count >= 9 else { return nil }
        return course.parValues.prefix(9).reduce(0, +)
    }

    private var inPar: Int? {
        guard course.parValues.count >= 18 else { return nil }
        return course.parValues.dropFirst(9).reduce(0, +)
    }
}
