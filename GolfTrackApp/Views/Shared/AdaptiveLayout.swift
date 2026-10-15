import SwiftUI

// MARK: - Breite Bildschirme (iPhone Duo innen, iPad, Querformat)

/// Hilfen, damit die App auf breiten Flächen nicht einfach in die Breite
/// gezogen wird. Gemessen wird nur am verfügbaren Platz, nicht am Gerät:
/// Das iPhone Duo wechselt beim Auf- und Zuklappen zwischen schmal und breit,
/// ohne dass sich das Gerät ändert.
enum AdaptiveLayout {
    /// Höchstbreite für Text und Kartenstapel. Auf dem iPhone und dem
    /// Außenbildschirm des Duo greift sie nie.
    static let readableWidth: CGFloat = 720

    /// Kartenraster: eine Spalte auf dem iPhone, zwei, sobald je Karte
    /// mindestens 300 pt Platz sind (Duo innen, iPad, Querformat).
    static let cardColumns = [GridItem(.adaptive(minimum: 300), spacing: 10, alignment: .top)]
}

extension View {
    /// Begrenzt den Inhalt auf eine lesbare Breite und zentriert ihn.
    func readableContentWidth(_ maxWidth: CGFloat = AdaptiveLayout.readableWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
