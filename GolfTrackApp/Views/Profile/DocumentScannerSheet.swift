import SwiftUI
import VisionKit
import PhotosUI

// MARK: - Scanner-Sheet: Kamera / Fotobibliothek → Dokument speichern

struct DocumentScannerSheet: View {
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var scannedImages: [UIImage] = []
    @State private var title: String = ""
    @State private var selectedType: GolfDocumentType = .membershipCard
    @State private var showScanner  = false
    @State private var showPicker   = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showTitleEdit = false
    @State private var saving = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Quellenauswahl ────────────────────────────
                        if scannedImages.isEmpty {
                            sourcePickerSection
                        } else {
                            previewSection
                        }

                        // ── Typ & Titel ───────────────────────────────
                        if !scannedImages.isEmpty {
                            metaSection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Dokument scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(AppTheme.textSec)
                }
                if !scannedImages.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") { saveDocument() }
                            .bold()
                            .foregroundStyle(AppTheme.gold)
                            .disabled(saving)
                    }
                }
            }
        }
        // VisionKit Document Scanner
        .sheet(isPresented: $showScanner) {
            if VNDocumentCameraViewController.isSupported {
                DocumentCameraView { images in
                    scannedImages = images
                    if title.isEmpty { title = selectedType.rawValue }
                    showScanner = false
                }
            }
        }
        // Fotobibliothek
        .photosPicker(isPresented: $showPicker,
                      selection: $photoItems,
                      maxSelectionCount: 10,
                      matching: .images)
        .onChange(of: photoItems) { _, items in
            Task {
                var loaded: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        loaded.append(img)
                    }
                }
                scannedImages = loaded
                if title.isEmpty { title = selectedType.rawValue }
            }
        }
    }

    // MARK: - Quellen-Auswahl

    private var sourcePickerSection: some View {
        VStack(spacing: 14) {
            Text("Wie möchtest du das Dokument hinzufügen?")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            // Dokumentkamera (bevorzugt – Perspektivkorrektur)
            sourceButton(
                icon: "doc.viewfinder.fill",
                title: "Dokument scannen",
                subtitle: "Automatische Randenerkennung",
                color: AppTheme.gold
            ) { showScanner = true }

            // Fotobibliothek
            sourceButton(
                icon: "photo.on.rectangle.angled",
                title: "Aus Fotos wählen",
                subtitle: "Bereits gemachte Fotos",
                color: Color(red: 0.3, green: 0.7, blue: 1.0)
            ) { showPicker = true }

            // Typ-Vorauswahl
            typePicker
                .padding(.top, 4)
        }
    }

    private func sourceButton(icon: String,
                               title: String,
                               subtitle: String,
                               color: Color,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTer)
            }
            .padding(16)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Vorschau gescannter Seiten

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(scannedImages.count) Seite\(scannedImages.count == 1 ? "" : "n") gescannt")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Button {
                    scannedImages = []
                    photoItems   = []
                } label: {
                    Label("Neu scannen", systemImage: "arrow.counterclockwise")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.gold)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(scannedImages.enumerated()), id: \.offset) { i, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(AppTheme.gold.opacity(0.4), lineWidth: 1)
                            )
                            .overlay(
                                Text("S.\(i + 1)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(.black.opacity(0.5),
                                                in: RoundedRectangle(cornerRadius: 4))
                                    .padding(4),
                                alignment: .bottomLeading
                            )
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Titel & Typ

    private var metaSection: some View {
        VStack(spacing: 14) {

            // Typ
            typePicker

            // Titel
            VStack(alignment: .leading, spacing: 6) {
                Text("Titel")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSec)
                    .padding(.horizontal, 4)

                TextField("z.B. Mitgliedskarte 2025", text: $title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text)
                    .padding(12)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kategorie")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSec)
                .padding(.horizontal, 2)

            let cols = [GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)]
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(GolfDocumentType.allCases, id: \.rawValue) { t in
                    typeTile(t)
                }
            }
        }
    }

    private func typeTile(_ type: GolfDocumentType) -> some View {
        let selected = selectedType == type
        return Button {
            selectedType = type
            if title.isEmpty || GolfDocumentType.allCases.map(\.rawValue).contains(title) {
                title = type.rawValue
            }
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(selected ? AppTheme.gold.opacity(0.2) : AppTheme.cardAlt)
                        .frame(width: 40, height: 40)
                    Image(systemName: type.icon)
                        .font(.system(size: 17))
                        .foregroundStyle(selected ? AppTheme.gold : AppTheme.textSec)
                }
                Text(type.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selected ? AppTheme.gold : AppTheme.textSec)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? AppTheme.gold.opacity(0.1) : AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(selected ? AppTheme.gold : Color.clear, lineWidth: 1.5)
                    )
            )
        }
    }

    // MARK: - Speichern

    private func saveDocument() {
        saving = true
        let finalTitle = title.isEmpty ? selectedType.rawValue : title
        Task.detached(priority: .userInitiated) {
            GolfDocumentStore.shared.save(title: finalTitle,
                                          type: selectedType,
                                          images: scannedImages)
            await MainActor.run {
                onSaved()
                dismiss()
            }
        }
    }
}

// MARK: - VisionKit Wrapper

struct DocumentCameraView: UIViewControllerRepresentable {
    var onScanned: ([UIImage]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onScanned: onScanned) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController,
                                 context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var onScanned: ([UIImage]) -> Void
        init(onScanned: @escaping ([UIImage]) -> Void) { self.onScanned = onScanned }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            onScanned(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onScanned([])
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            onScanned([])
        }
    }
}
