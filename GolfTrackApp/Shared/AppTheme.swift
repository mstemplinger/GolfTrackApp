import SwiftUI

// MARK: - Design System

enum AppTheme {
    // Backgrounds
    static let bg       = Color(red: 0.055, green: 0.153, blue: 0.094)  // #0E2718 deepest bg
    static let card     = Color(red: 0.086, green: 0.204, blue: 0.129)  // #163421 card bg
    static let cardAlt  = Color(red: 0.110, green: 0.255, blue: 0.161)  // #1C4129 card variant
    static let cardDark = Color(red: 0.068, green: 0.176, blue: 0.110)  // #112D1C dark card

    // Accent
    static let gold     = Color(red: 0.788, green: 0.627, blue: 0.208)  // #C9A035 gold CTA
    static let goldDark = Color(red: 0.635, green: 0.498, blue: 0.153)  // #A27F27 pressed gold
    static let green    = Color(red: 0.157, green: 0.510, blue: 0.294)  // #28824B medium green
    static let greenMid = Color(red: 0.110, green: 0.380, blue: 0.220)  // #1C6138 mid green

    // Text
    static let text     = Color.white
    static let textSec  = Color.white.opacity(0.60)
    static let textTer  = Color.white.opacity(0.40)

    // Tab bar
    static let tabBg    = Color(red: 0.068, green: 0.176, blue: 0.110)  // same as cardDark

    // Score colors
    static func scoreColor(_ scoreToPar: Int?) -> Color {
        guard let s = scoreToPar else { return .white }
        if s < 0 { return Color(red: 0.4, green: 0.85, blue: 0.5) }   // under par: bright green
        if s == 0 { return .white }
        if s <= 2 { return Color(red: 1.0, green: 0.75, blue: 0.3) }  // bogey: gold
        return Color(red: 1.0, green: 0.4, blue: 0.4)                  // double+: red
    }
}

// MARK: - Convenience View Modifiers

extension View {
    func appBackground() -> some View {
        self.background(AppTheme.bg.ignoresSafeArea())
    }

    func cardStyle() -> some View {
        self
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    func goldButton() -> some View {
        self
            .font(.headline)
            .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
    }

    func greenButton() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.greenMid, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Navigation Bar Appearance

func configureNavigationBarAppearance() {
    let bgColor = UIColor(AppTheme.bg)
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = bgColor
    appearance.titleTextAttributes      = [.foregroundColor: UIColor.white]
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    // Separator line
    appearance.shadowColor = UIColor.white.withAlphaComponent(0.08)

    UINavigationBar.appearance().standardAppearance   = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().compactAppearance    = appearance
    UINavigationBar.appearance().tintColor            = UIColor(AppTheme.gold)
}

// MARK: - Tab Bar Appearance

func configureTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(AppTheme.tabBg)

    // Normal state
    let normal = appearance.stackedLayoutAppearance
    normal.normal.iconColor = UIColor.white.withAlphaComponent(0.45)
    normal.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.45)]
    // Selected state
    normal.selected.iconColor = UIColor(AppTheme.gold)
    normal.selected.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.gold)]

    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
}
