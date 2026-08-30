import SwiftUI

/// Allererster Screen beim App-Start: Golf oder Minigolf?
///
/// Läuft **vor** dem Tutorial. Bei Minigolf wird das Tutorial übersprungen,
/// weil es ausschließlich Golf-Funktionen erklärt.
struct AppFocusSelectionView: View {

    @AppStorage(AppFocus.storageKey) private var appFocus: AppFocus = .golf
    @AppStorage(AppFocus.chosenKey)  private var hasChosenAppFocus = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var selection: AppFocus? = nil
    @State private var appear = false

    var body: some View {
        ZStack {
            // Hintergrund – etwas dunkler als die App, damit der Screen "davor" wirkt
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.100, blue: 0.062),
                    AppTheme.bg
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                            .padding(.top, max(geo.safeAreaInsets.top, 24) + 12)

                        VStack(spacing: 14) {
                            ForEach(AppFocus.allCases) { focus in
                                focusCard(focus)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 28)

                        continueButton
                            .padding(.horizontal, 22)
                            .padding(.top, 26)

                        Text("Du kannst das später jederzeit im Profil ändern.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTer)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 14)
                            .padding(.bottom, 30)
                    }
                    .frame(minHeight: geo.size.height, alignment: .top)
                }
            }
        }
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { appear = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.45), radius: 14, y: 6)

            VStack(spacing: 8) {
                Text("Willkommen bei GolfTrack")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.center)

                Text("Was möchtest du hauptsächlich tracken?")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSec)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Auswahlkarte

    private func focusCard(_ focus: AppFocus) -> some View {
        let isSelected = selection == focus

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selection = focus
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? AppTheme.gold.opacity(0.22) : AppTheme.cardAlt)
                            .frame(width: 52, height: 52)
                        Image(systemName: focus.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isSelected ? AppTheme.gold : AppTheme.textSec)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(focus.title)
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.text)
                        Text(focus.subtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 4)

                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? AppTheme.gold : Color.white.opacity(0.22),
                                          lineWidth: isSelected ? 0 : 1.5)
                            .background(Circle().fill(isSelected ? AppTheme.gold : .clear))
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                        }
                    }
                }

                if isSelected {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(focus.highlights, id: \.self) { line in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.gold)
                                    .padding(.top, 1)
                                Text(line)
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSec)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? AppTheme.gold : Color.white.opacity(0.08),
                                    lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: .black.opacity(isSelected ? 0.4 : 0.2),
                            radius: isSelected ? 18 : 10, y: 6)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Weiter

    private var continueButton: some View {
        Button {
            guard let choice = selection else { return }
            apply(choice)
        } label: {
            HStack(spacing: 7) {
                Text(selection == .minigolf ? "Los geht's" : "Weiter")
                    .font(.headline)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                (selection == nil ? AppTheme.gold.opacity(0.35) : AppTheme.gold),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .disabled(selection == nil)
        .animation(.easeInOut(duration: 0.2), value: selection)
    }

    // MARK: - Auswahl übernehmen

    private func apply(_ choice: AppFocus) {
        appFocus = choice
        // Minigolf-Spieler bekommen kein Tutorial – es erklärt nur Golf-Features.
        if choice == .minigolf { hasSeenOnboarding = true }
        withAnimation(.easeInOut(duration: 0.3)) {
            hasChosenAppFocus = true
        }
    }
}

#Preview {
    AppFocusSelectionView()
        .preferredColorScheme(.dark)
}
