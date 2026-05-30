import Foundation
import UIKit

// MARK: - Dokumenttypen

enum GolfDocumentType: String, Codable, CaseIterable {
    case membershipCard    = "Mitgliedskarte"
    case greenFeeReceipt   = "Greenfee-Beleg"
    case tournamentEntry   = "Turnierregistrierung"
    case startingFee       = "Startgeld"
    case other             = "Sonstiges"

    var icon: String {
        switch self {
        case .membershipCard:  return "creditcard.fill"
        case .greenFeeReceipt: return "doc.text.fill"
        case .tournamentEntry: return "trophy.fill"
        case .startingFee:     return "eurosign.square.fill"
        case .other:           return "doc.fill"
        }
    }
}

// MARK: - Datenmodell

struct GolfDocument: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var type: GolfDocumentType
    var date: Date
    /// Dateinamen der gespeicherten Seiten (JPEG) im Dokument-Verzeichnis
    var imageFilenames: [String]

    var pageCount: Int { imageFilenames.count }
}

// MARK: - Persistenz

final class GolfDocumentStore {
    static let shared = GolfDocumentStore()
    private init() { ensureDirectory() }

    // MARK: Verzeichnis

    private var directory: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("golf_documents", isDirectory: true)
    }

    private var metaURL: URL {
        directory.appendingPathComponent("metadata.json")
    }

    private func ensureDirectory() {
        try? FileManager.default.createDirectory(at: directory,
                                                 withIntermediateDirectories: true)
    }

    // MARK: Laden

    func loadAll() -> [GolfDocument] {
        guard let data = try? Data(contentsOf: metaURL),
              let docs = try? JSONDecoder().decode([GolfDocument].self, from: data)
        else { return [] }
        return docs.sorted { $0.date > $1.date }
    }

    // MARK: Speichern

    @discardableResult
    func save(title: String,
              type: GolfDocumentType,
              images: [UIImage]) -> GolfDocument {
        var filenames: [String] = []
        for (i, img) in images.enumerated() {
            let name = "\(UUID().uuidString)_p\(i).jpg"
            let url  = directory.appendingPathComponent(name)
            if let data = img.jpegData(compressionQuality: 0.85) {
                try? data.write(to: url, options: .atomic)
                filenames.append(name)
            }
        }
        var all = loadAll()
        let doc = GolfDocument(title: title,
                               type: type,
                               date: Date(),
                               imageFilenames: filenames)
        all.insert(doc, at: 0)
        saveMeta(all)
        return doc
    }

    // MARK: Laden eines Bildes

    func loadImage(filename: String) -> UIImage? {
        let url = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: Löschen

    func delete(_ doc: GolfDocument) {
        for name in doc.imageFilenames {
            try? FileManager.default.removeItem(
                at: directory.appendingPathComponent(name))
        }
        var all = loadAll()
        all.removeAll { $0.id == doc.id }
        saveMeta(all)
    }

    // MARK: Metadaten schreiben

    private func saveMeta(_ docs: [GolfDocument]) {
        guard let data = try? JSONEncoder().encode(docs) else { return }
        try? data.write(to: metaURL, options: .atomic)
    }
}
