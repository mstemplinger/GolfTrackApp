import SwiftUI
import Vision
import VisionKit

/// Kamera für den Lobby-QR-Code. Erkennt sowohl den Link
/// `golftrack.app/lobby/<code>` als auch einen QR-Code mit nur den fünf Ziffern.
struct LobbyScannerView: View {
    let onCode: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    ScannerRepresentable(onCode: { code in
                        Haptics.success()
                        onCode(code)
                    })
                    .ignoresSafeArea()
                    .overlay(alignment: .bottom) {
                        Text("Halte die Kamera auf den QR-Code deines Freundes.")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 32)
                    }
                } else {
                    ContentUnavailableView(
                        "Kamera nicht verfügbar",
                        systemImage: "camera.fill",
                        description: Text("Erlaube GolfTrack den Zugriff auf die Kamera in den Einstellungen – oder gib den fünfstelligen Code ein."))
                }
            }
            .navigationTitle("Lobby-Code scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        Haptics.tap()
                        dismiss()
                    }
                }
            }
        }
    }

    /// Fünf Ziffern aus dem Inhalt eines QR-Codes – Link oder nackter Code.
    static func code(from payload: String) -> String? {
        if let url = URL(string: payload), url.pathComponents.count >= 3,
           url.pathComponents[url.pathComponents.count - 2] == "lobby" {
            let last = url.lastPathComponent
            return last.count == 5 && last.allSatisfy(\.isNumber) ? last : nil
        }
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 5 && trimmed.allSatisfy(\.isNumber) ? trimmed : nil
    }
}

private struct ScannerRepresentable: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true)
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        private var delivered = false

        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func dataScanner(_ scanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard !delivered else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item,
                   let payload = barcode.payloadStringValue,
                   let code = LobbyScannerView.code(from: payload) {
                    delivered = true
                    scanner.stopScanning()
                    onCode(code)
                    return
                }
            }
        }
    }
}
