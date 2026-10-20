package app.golftrack.data

/** Entspricht GolfTrackApp/Models/GameMode.swift. `raw` = Swift-rawValue. */
enum class GameModeCategory(val title: String) {
    INDIVIDUAL("Individuelle Spielformen"),
    PARTNER("Partner Spielformen"),
    TEAM("Team Spielformen"),
}

enum class GameMode(
    val raw: String,
    val displayName: String,
    val subtitle: String,
    val category: GameModeCategory,
    val description: String,
    val isAvailable: Boolean,
    val minOtherPlayers: Int,
    val maxOtherPlayers: Int,
) {
    STROKE_PLAY("strokePlay", "Zählspiel", "", GameModeCategory.INDIVIDUAL,
        "Die klassische Spielform: Jeder Schlag zählt. Wer am Ende der Runde die wenigsten Schläge hat, gewinnt.", true, 0, 0),
    STABLEFORD("stableford", "Stableford", "", GameModeCategory.INDIVIDUAL,
        "Punkte statt Schläge: Albatross=5, Eagle=4, Birdie=3, Par=2, Bogey=1, Double+=0. Wer die meisten Punkte sammelt, gewinnt.", true, 0, 0),
    ERADO("erado", "Erado®", "Zählspiel", GameModeCategory.INDIVIDUAL,
        "Wie Zählspiel, aber die schlechteste(n) Löcher werden gestrichen. Bei 18 Löchern werden 2 Streichlöcher angerechnet, bei 9 Löchern 1.", true, 0, 0),
    SKINS("skins", "Skins", "Zählspiel", GameModeCategory.INDIVIDUAL,
        "Jedes Loch hat einen Wert (Skin). Wer das Loch gewinnt, erhält den Skin. Bei Gleichstand wird der Skin übertragen.", true, 1, 3),
    DUPLICATE_STABLEFORD("duplicateStableford", "Duplicate®", "Stableford", GameModeCategory.INDIVIDUAL,
        "Stableford-Punkte werden multipliziert – bestimmte Löcher zählen doppelt oder dreifach.", false, 0, 0),
    MATCHPLAY("matchplay", "Matchplay", "", GameModeCategory.INDIVIDUAL,
        "Loch für Loch. Wer das Loch mit weniger Schlägen spielt, gewinnt es. Wer am Ende mehr Löcher hat, gewinnt die Runde.", true, 1, 1),
    BETTER_BALL_STROKE("betterBallStroke", "Better Ball", "Zählspiel", GameModeCategory.PARTNER,
        "Zwei Spieler spielen gemeinsam – der bessere Score pro Loch zählt für das Team.", true, 1, 1),
    BETTER_BALL_STABLEFORD("betterBallStableford", "Better Ball", "Stableford", GameModeCategory.PARTNER,
        "Wie Better Ball, aber gewertet nach Stableford-Punkten. Die höheren Punkte pro Loch zählen für das Team.", true, 1, 1),
    SCRAMBLE_2_MANN("scramble2Mann", "2-Mann Scramble", "Zählspiel", GameModeCategory.PARTNER,
        "Beide Spieler schlagen ab. Der beste Abschlag wird gewählt und beide spielen von dort weiter.", true, 1, 1),
    BETTER_BALL_MATCHPLAY("betterBallMatchplay", "Better Ball", "Matchplay", GameModeCategory.PARTNER,
        "2 gegen 2: Pro Team zählt der bessere Score. Die Teams spielen Loch für Loch gegeneinander (Matchplay).", true, 2, 3),
    VIERER("vierer", "Vierer", "Matchplay", GameModeCategory.PARTNER,
        "Zwei Spieler spielen abwechselnd mit einem Ball (Wechselschlag). Ein Team, ein Ball, ein Score.", true, 1, 1),
    GREENSOME("greensome", "Greensome", "Matchplay", GameModeCategory.PARTNER,
        "Beide Partner schlagen ab. Der beste Abschlag wird gewählt. Danach spielen beide abwechselnd bis zum Einlochen.", true, 1, 1),
    SCRAMBLE_MATCHPLAY("scrambleMatchplay", "Scramble", "Matchplay", GameModeCategory.PARTNER,
        "Scramble-Format (bester Ball, alle spielen weiter) im Matchplay-Modus gegen ein anderes Team.", false, 0, 0),
    BEST_BALL_STROKE("bestBallStroke", "Best Ball", "Zählspiel", GameModeCategory.TEAM,
        "3 oder 4 Spieler im Team – der beste Score pro Loch zählt für das Team (Zählspiel).", true, 1, 3),
    BEST_BALL_STABLEFORD("bestBallStableford", "Best Ball", "Stableford", GameModeCategory.TEAM,
        "Best Ball mit Stableford-Wertung – der höchste Punktwert pro Loch zählt für das Team.", true, 1, 3),
    SCRAMBLE_TEAM("scrambleTeam", "Scramble", "Zählspiel", GameModeCategory.TEAM,
        "3–4 Spieler: Alle schlagen ab, bester Abschlag wird gewählt. Alle spielen von dort weiter bis zum Einlochen.", true, 2, 3),
    MATCH_NET("matchNet", "Match/Net", "Zählspiel", GameModeCategory.TEAM,
        "Zählspiel gegen eine Netto-Zielvorgabe. Das Team spielt gegen einen vorgegebenen Netto-Score.", false, 0, 0),
    DUPLICATE_SCRAMBLE("duplicateScramble", "Duplicate® Scramble", "Stableford", GameModeCategory.TEAM,
        "Scramble mit Stableford-Wertung und Multiplikator auf bestimmten Löchern.", false, 0, 0),
    IRISH_RUMBLE("irishRumble", "Irish Rumble", "Best Ball", GameModeCategory.TEAM,
        "Die ersten Löcher werden als Best Ball gespielt, dann wechselt das Format nach einem festen Schlüssel.", false, 0, 0);

    val isMultiplayer: Boolean get() = minOtherPlayers > 0

    companion object {
        fun fromRaw(raw: String?): GameMode = entries.firstOrNull { it.raw == raw } ?: STROKE_PLAY
        fun stablefordPoints(strokes: Int, par: Int): Int = maxOf(0, 2 - (strokes - par))
    }
}
