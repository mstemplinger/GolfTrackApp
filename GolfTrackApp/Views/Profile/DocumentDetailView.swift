import SwiftUI

// MARK: - Vollbild-Dokumentansicht

struct DocumentDetailView: View {
    let document: GolfDocument
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int? = 0
    @State private var showDeleteAlert = false

    // Bilder gecacht
    @State private var pages: [UIImage?] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if pages.isEmpty {
                    ProgressView()
                        .tint(AppTheme.gold)
                } else {
                    VStack(spacing: 0) {
                        pageViewer
                        metaBar
                    }
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button { showDeleteAlert = true } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                    }
                }
            }
            .alert("Dokument löschen?", isPresented: $showDeleteAlert) {
                Button("Löschen", role: .destructive) {
                    GolfDocumentStore.shared.delete(document)
                    onDelete()
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("\"\(document.title)\" wird unwiderruflich gelöscht.")
            }
        }
        .onAppear { loadPages() }
    }

    // MARK: - Seiten-Viewer
    // Nutzt ScrollView + scrollTargetBehavior statt TabView/UIPageViewController,
    // damit Wischen direkt auf dem Bild (ohne Geste-Konflikt) funktioniert.

    private var pageViewer: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, img in
                        ZStack {
                            if let img {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(12)
                            } else {
                                ProgressView()
                                    .tint(.white.opacity(0.4))
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .contentShape(Rectangle())
                        .id(i)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage)
        }
    }

    // MARK: - Meta-Leiste

    private var metaBar: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.gold.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: document.type.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(document.type.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Text(document.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            if document.pageCount > 1 {
                // Punkte-Indikator
                HStack(spacing: 5) {
                    ForEach(0..<document.pageCount, id: \.self) { i in
                        Circle()
                            .fill(i == (currentPage ?? 0)
                                  ? AppTheme.gold
                                  : Color.white.opacity(0.3))
                            .frame(width: i == (currentPage ?? 0) ? 7 : 5,
                                   height: i == (currentPage ?? 0) ? 7 : 5)
                            .animation(.spring(duration: 0.2), value: currentPage)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.black)
    }

    // MARK: - Bilder laden

    private func loadPages() {
        pages = Array(repeating: nil, count: document.pageCount)
        for (i, name) in document.imageFilenames.enumerated() {
            Task.detached(priority: .userInitiated) {
                let img = GolfDocumentStore.shared.loadImage(filename: name)
                await MainActor.run { pages[i] = img }
            }
        }
    }
}
