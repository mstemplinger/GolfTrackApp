import SwiftUI
import AVFoundation

/// Kamera zum Scannen des QR-Codes an der Anlage – im Clip selbst.
///
/// Nötig, weil iOS den Clip auch ohne Link startet: aus der App-Mediathek,
/// aus „Zuletzt verwendet“ oder nach einem Absturz. Dann soll niemand erst
/// die Kamera-App suchen müssen.
///
/// Bewusst AVFoundation und nicht `DataScannerViewController`: der läuft erst
/// ab A12 und meldet auf älteren Geräten schlicht „nicht verfügbar“.
struct QRScannerView: UIViewControllerRepresentable {

    /// Wird einmal aufgerufen, mit dem ersten Code, der eine Adresse ist.
    let onFound: (URL) -> Void

    func makeUIViewController(context: Context) -> ScannerController {
        let controller = ScannerController()
        controller.onFound = onFound
        return controller
    }

    func updateUIViewController(_ controller: ScannerController, context: Context) {}

    final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

        var onFound: ((URL) -> Void)?
        private let session = AVCaptureSession()
        private var preview: AVCaptureVideoPreviewLayer?
        private var reported = false

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer)
            preview = layer
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            preview?.frame = view.bounds
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // `startRunning` blockiert, bis die Kamera läuft – nicht auf dem
            // Hauptthread.
            let session = session
            DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            let session = session
            DispatchQueue.global(qos: .userInitiated).async { session.stopRunning() }
        }

        nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                        didOutput metadataObjects: [AVMetadataObject],
                                        from connection: AVCaptureConnection) {
            let value = metadataObjects
                .compactMap { ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }
                .first
            MainActor.assumeIsolated {
                guard !reported, let value, let url = URL(string: value) else { return }
                reported = true
                Haptics.success()
                onFound?(url)
            }
        }
    }
}

/// Der Scanner als Blatt, mit Rahmen und Hinweis, falls die Kamera fehlt.
struct QRScannerSheet: View {

    let onFound: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var access = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        NavigationStack {
            ZStack {
                if access == .authorized {
                    QRScannerView { url in
                        dismiss()
                        onFound(url)
                    }
                    .ignoresSafeArea()

                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppTheme.gold, lineWidth: 4)
                        .frame(width: 250, height: 250)

                    VStack {
                        Spacer()
                        Text("Halte die Kamera auf den QR-Code am Platz.")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(.bottom, 40)
                    }
                } else if access == .notDetermined {
                    ProgressView().tint(AppTheme.gold)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.gold)
                        Text("Kein Zugriff auf die Kamera")
                            .font(.title3.bold())
                        Text("Erlaube GolfTrack die Kamera in den Einstellungen – oder scanne den Code mit der Kamera-App.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .appBackground()
                }
            }
            .navigationTitle("Code scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .task {
            guard access == .notDetermined else { return }
            _ = await AVCaptureDevice.requestAccess(for: .video)
            access = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }
}
