import SwiftUI

// MARK: - Karte im Profil-Tab

struct DocumentsCard: View {
    @State private var documents: [GolfDocument] = []
    @State private var showScanner  = false
    @State private var selected: GolfDocument?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header ─────────────────────────────────────────────
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dokumente")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Text("Mitgliedskarte, Belege & mehr")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Button {
                    showScanner = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Hinzufügen")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(AppTheme.gold.opacity(0.15), in: Capsule())
                    .foregroundStyle(AppTheme.gold)
                }
            }

            Divider().background(AppTheme.cardAlt)

            if documents.isEmpty {
                // ── Leerer Zustand ──────────────────────────────────
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.cardAlt)
                            .frame(width: 52, height: 52)
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.textTer)
                    }
                    Text("Noch keine Dokumente")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textSec)
                    Text("Scanne deine Mitgliedskarte oder Greenfee-Belege für schnellen Zugriff.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTer)
                        .multilineTextAlignment(.center)

                    Button {
                        showScanner = true
                    } label: {
                        Label("Erstes Dokument scannen", systemImage: "doc.viewfinder.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

            } else {
                // ── Dokument-Raster ─────────────────────────────────
                let cols = [GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)]
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(documents) { doc in
                        documentTile(doc)
                            .onTapGesture { selected = doc }
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
        .onAppear { reload() }
        // Scanner-Sheet
        .sheet(isPresented: $showScanner) {
            DocumentScannerSheet { reload() }
                .presentationDetents([.large])
        }
        // Detail-Sheet
        .sheet(item: $selected) { doc in
            DocumentDetailView(document: doc) { reload() }
        }
    }

    // MARK: - Dokument-Kachel

    private func documentTile(_ doc: GolfDocument) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Vorschau (erstes Bild oder Icon-Fallback)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.cardAlt)
                    .frame(height: 90)

                ThumbnailView(filename: doc.imageFilenames.first)

                // Seiten-Badge
                if doc.pageCount > 1 {
                    Text("\(doc.pageCount) Seiten")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }

            // Meta
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: doc.type.icon)
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.gold)
                    Text(doc.type.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                }
                .padding(.top, 6)

                Text(doc.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)

                Text(doc.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTer)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 8)
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.cardAlt, lineWidth: 1)
        )
    }

    // MARK: - Reload

    private func reload() {
        documents = GolfDocumentStore.shared.loadAll()
    }
}

// MARK: - Thumbnail Lazy-Loader

private struct ThumbnailView: View {
    let filename: String?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 90)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "doc.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.textTer)
                    .frame(height: 90)
            }
        }
        .onAppear {
            guard let name = filename else { return }
            Task.detached(priority: .utility) {
                let img = GolfDocumentStore.shared.loadImage(filename: name)
                await MainActor.run { image = img }
            }
        }
    }
}
