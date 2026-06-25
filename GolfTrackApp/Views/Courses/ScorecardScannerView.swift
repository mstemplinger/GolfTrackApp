import SwiftUI
import VisionKit
import SwiftData

// MARK: - Entry point (shown as sheet)

struct ScorecardScannerView: View {
    var onSave: (Course) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .scanning

    enum Phase {
        case scanning
        case processing
        case confirming(ParsedScorecardData)
        case error(String)
    }

    var body: some View {
        switch phase {
        case .scanning:
            DocumentScannerRepresentable { images in
                guard let first = images.first else { dismiss(); return }
                phase = .processing
                Task {
                    do {
                        let parsed = try await ScorecardParserService.shared.parse(image: first)
                        phase = .confirming(parsed)
                    } catch {
                        phase = .error(error.localizedDescription)
                    }
                }
            } onCancel: {
                dismiss()
            }
            .ignoresSafeArea()

        case .processing:
            ProcessingView()

        case .confirming(let data):
            ScorecardConfirmView(data: data, onSave: { course in
                onSave(course)
                dismiss()
            }, onCancel: {
                dismiss()
            })

        case .error(let message):
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.red)
                    Text("Scan fehlgeschlagen")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.text)
                    Text(message)
                        .font(.body)
                        .foregroundStyle(AppTheme.textSec)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Schließen") { dismiss() }
                        .buttonStyle(GoldButtonStyle())
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Processing screen

private struct ProcessingView: View {
    @State private var step = 0
    @State private var dots = ""

    private let steps = [
        "Scorecard wird erkannt",
        "Text wird ausgelesen",
        "Par & HCP werden analysiert",
        "Platz wird vorbereitet",
    ]

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()

                // Animated golf icon
                ZStack {
                    Circle()
                        .fill(AppTheme.gold.opacity(0.12))
                        .frame(width: 110, height: 110)
                    Circle()
                        .fill(AppTheme.gold.opacity(0.07))
                        .frame(width: 140, height: 140)
                    Image(systemName: "doc.viewfinder.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.gold)
                        .symbolEffect(.pulse)
                }

                VStack(spacing: 10) {
                    Text("Scorecard wird gelesen\(dots)")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.text)
                        .animation(.none, value: dots)

                    Text(steps[step % steps.count])
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id(step)
                        .animation(.easeInOut(duration: 0.4), value: step)
                }

                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= step % steps.count ? AppTheme.gold : AppTheme.textTer)
                            .frame(width: i == step % steps.count ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.4), value: step)
                    }
                }

                Spacer()

                Text("Einen Moment bitte …")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTer)
                    .padding(.bottom, 40)
            }
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Cycle through steps every 1.4 seconds
        Timer.scheduledTimer(withTimeInterval: 1.4, repeats: true) { t in
            withAnimation { step += 1 }
            if step > 20 { t.invalidate() } // safety
        }
        // Animate dots independently
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dots = dots.count >= 3 ? "" : dots + "."
        }
    }
}

// MARK: - VisionKit bridge

private struct DocumentScannerRepresentable: UIViewControllerRepresentable {
    var onScanned: ([UIImage]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScanned: onScanned, onCancel: onCancel) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var onScanned: ([UIImage]) -> Void
        var onCancel: () -> Void
        init(onScanned: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onScanned = onScanned
            self.onCancel = onCancel
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            onScanned(images)
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            onCancel()
        }
    }
}

// MARK: - Confirmation / editing screen

struct ScorecardConfirmView: View {
    @State var data: ParsedScorecardData
    var onSave: (Course) -> Void
    var onCancel: () -> Void

    @State private var showHoleEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        headerCard
                        ratingsCard
                        holeTableCard
                        saveButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Scan-Ergebnis prüfen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onCancel)
                }
            }
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Platzname", systemImage: "flag.fill")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.gold)

            TextField("Platzname", text: $data.name)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text)
                .padding(12)
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Löcher").font(.caption).foregroundStyle(AppTheme.textSec)
                    Text("\(data.numberOfHoles)").font(.headline.bold()).foregroundStyle(AppTheme.text)
                }
                Divider().frame(height: 30).overlay(AppTheme.textTer)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gesamt Par").font(.caption).foregroundStyle(AppTheme.textSec)
                    Text("\(data.parValues.reduce(0, +))").font(.headline.bold()).foregroundStyle(AppTheme.gold)
                }
            }
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var ratingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ratings", systemImage: "chart.bar.fill")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.gold)

            HStack(spacing: 12) {
                ratingField(
                    label: "Course Rating",
                    text: Binding(
                        get: { data.courseRating.map { String(format: "%.1f", $0) } ?? "" },
                        set: { data.courseRating = Double($0.replacingOccurrences(of: ",", with: ".")) }
                    ),
                    placeholder: "z.B. 72.4"
                )
                ratingField(
                    label: "Slope Rating",
                    text: Binding(
                        get: { data.slopeRating.map { String($0) } ?? "" },
                        set: { data.slopeRating = Int($0) }
                    ),
                    placeholder: "z.B. 125"
                )
            }
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func ratingField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(AppTheme.textSec)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .font(.body.bold())
                .foregroundStyle(AppTheme.text)
                .padding(10)
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity)
    }

    private var holeTableCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Loch-Details", systemImage: "table.fill")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.gold)
                Spacer()
                Button("Bearbeiten") { showHoleEditor = true }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.gold)
            }

            // Table header
            HStack(spacing: 0) {
                tableHeaderCell("Loch", width: 44)
                tableHeaderCell("Par", width: 44)
                tableHeaderCell("HCP", width: 44)
                tableHeaderCell("Meter", width: 60)
            }

            // Rows
            let holes = data.numberOfHoles
            ForEach(0..<holes, id: \.self) { i in
                HStack(spacing: 0) {
                    tableCell("\(i + 1)", width: 44, bold: true)
                    tableCell(i < data.parValues.count ? "\(data.parValues[i])" : "–", width: 44, color: parColor(i))
                    tableCell(i < data.hcpValues.count ? "\(data.hcpValues[i])" : "–", width: 44)
                    tableCell(i < data.holeLengths.count ? "\(data.holeLengths[i])" : "–", width: 60)
                }
                .background(i % 2 == 0 ? AppTheme.cardAlt.opacity(0.5) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if data.parValues.isEmpty {
                Text("Keine Par-Werte erkannt – bitte manuell im Bearbeiten-Modus eingeben.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showHoleEditor) {
            HoleEditorSheet(data: $data)
        }
    }

    private var saveButton: some View {
        Button {
            let course = Course(
                name: data.name.isEmpty ? "Unbekannter Platz" : data.name,
                numberOfHoles: data.numberOfHoles,
                parValues: data.parValues.isEmpty ? Course.defaultPars(for: 18) : data.parValues,
                courseRating: data.courseRating ?? 72.0,
                slopeRating: data.slopeRating ?? 113,
                hcpValues: data.hcpValues,
                holeLengths: data.holeLengths
            )
            onSave(course)
        } label: {
            Label("Platz speichern", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GoldButtonStyle())
    }

    // MARK: - Helpers

    private func tableHeaderCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(AppTheme.textSec)
            .frame(width: width, alignment: .center)
    }

    private func tableCell(_ text: String, width: CGFloat, bold: Bool = false, color: Color = AppTheme.text) -> some View {
        Text(text)
            .font(bold ? .caption.bold() : .caption)
            .foregroundStyle(color)
            .frame(width: width, alignment: .center)
            .padding(.vertical, 5)
    }

    private func parColor(_ i: Int) -> Color {
        guard i < data.parValues.count else { return AppTheme.text }
        switch data.parValues[i] {
        case 3: return Color(hex: "#66D97F")
        case 4: return AppTheme.text
        case 5: return AppTheme.gold
        default: return AppTheme.text
        }
    }
}

// MARK: - Hole editor sheet

private struct HoleEditorSheet: View {
    @Binding var data: ParsedScorecardData
    @Environment(\.dismiss) private var dismiss

    @State private var holes: Int = 18
    @State private var pars: [String] = Array(repeating: "", count: 18)
    @State private var hcps: [String] = Array(repeating: "", count: 18)
    @State private var lengths: [String] = Array(repeating: "", count: 18)

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                List {
                    Section("Anzahl Löcher") {
                        Picker("Löcher", selection: $holes) {
                            Text("9 Loch").tag(9)
                            Text("18 Loch").tag(18)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(AppTheme.card)
                    }

                    Section("Loch-Werte") {
                        ForEach(0..<holes, id: \.self) { i in
                            HStack(spacing: 12) {
                                Text("L \(i+1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.gold)
                                    .frame(width: 36)
                                numField("Par", text: $pars[i])
                                numField("HCP", text: $hcps[i])
                                numField("m", text: $lengths[i])
                            }
                            .listRowBackground(AppTheme.card)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Löcher bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        data.parValues = pars.prefix(holes).compactMap { Int($0) }
                        data.hcpValues = hcps.prefix(holes).compactMap { Int($0) }
                        data.holeLengths = lengths.prefix(holes).compactMap { Int($0) }
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.gold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .onAppear {
            holes = data.numberOfHoles == 0 ? 18 : data.numberOfHoles
            pars = padded(data.parValues.map { String($0) })
            hcps = padded(data.hcpValues.map { String($0) })
            lengths = padded(data.holeLengths.map { String($0) })
        }
    }

    private func numField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .font(.body)
            .foregroundStyle(AppTheme.text)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(6)
            .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 8))
    }

    private func padded(_ arr: [String]) -> [String] {
        var result = arr
        while result.count < 18 { result.append("") }
        return result
    }
}

// MARK: - Button style (reuse or define locally if not global)

private struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color(hex: "#0E2718"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(configuration.isPressed ? Color(hex: "#A27F27") : Color(hex: "#C9A035"),
                        in: RoundedRectangle(cornerRadius: 14))
    }
}

// Color hex helper (in case not globally available)
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
