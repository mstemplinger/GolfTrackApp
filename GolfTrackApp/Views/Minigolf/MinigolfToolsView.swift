import SwiftUI

/// Distanzmessung und Karte.
///
/// Lag früher als zweiter Tab im Minigolf-Bereich. Dort war es ein Fremdkörper:
/// gebraucht wird es beim Üben und auf dem Golfplatz, nicht beim Mitzählen auf
/// der Minigolfanlage. Deshalb hängt es jetzt als eigener Punkt im Profil.
struct MinigolfToolsView: View {
    @State private var tracker = DistanceTracker()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                DistanceTrackerCard(tracker: tracker)
                DistanceMapCard(tracker: tracker)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Distanz & Karte")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { MinigolfToolsView() }
        .preferredColorScheme(.dark)
}
