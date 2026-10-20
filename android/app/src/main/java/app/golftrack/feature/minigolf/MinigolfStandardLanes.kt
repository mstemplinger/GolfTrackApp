package app.golftrack.feature.minigolf

/**
 * Die 28 genormten Miniaturgolf-Bahnen – wie MinigolfStandardLanes.swift.
 *
 * Grundlage sind die Normungsbestimmungen für Miniaturgolf (S 12) des DMV, die
 * deutsche Fassung der Regeln des Weltverbands WMF. Hinterlegt ist die
 * **Nummer der Normbahn**, nicht die Bahnnummer vor Ort.
 * `tipp` ist die Spielempfehlung der App – keine Regel.
 */
data class MinigolfStandardLane(
    /** Nummer der Normbahn (1–28), nicht die Position auf der Anlage. */
    val normNumber: Int,
    val name: String,
    val hindernis: String,
    val weg: String,
    val mass: String,
    val tipp: String,
    val shape: LaneShape,
    val glyph: LaneGlyph,
)

/** Grundform der Bahn – bestimmt die Skizze. */
@Suppress("EnumEntryName")
enum class LaneShape { straight, tiltedCircle, jump }

/** Hindernis in der Skizze. */
@Suppress("EnumEntryName")
enum class LaneGlyph {
    keines, pyramiden, salto, niere, doppelwellen, liegendeSchleife, bruecke, sprungschanze,
    zielkreisfenster, rohr, staebe, labyrinth, kegel, doppelkeile, passagen, mittelhuegel, vulkan,
    vHindernis, winkel, blitz, plateau, auflaufkeil, steilschraege, rampe, raute, zielhuegel,
}

object MinigolfStandardLanes {
    /** Normmaße einer Miniaturgolfbahn. */
    const val LANE_LENGTH = "6,25 m"
    const val LANE_WIDTH = "0,90 m"
    const val TARGET_CIRCLE_DIAMETER = "1,40 m"

    fun lane(n: Int): MinigolfStandardLane? = all.firstOrNull { it.normNumber == n }

    val all: List<MinigolfStandardLane> = listOf(
        MinigolfStandardLane(
            1, "Pyramiden",
            hindernis = "Zwei Pyramiden, die die Bahn auf beiden Seiten verengen.",
            weg = "Nicht festgelegt – links oder rechts vorbei ist beides erlaubt.",
            mass = "Bleibt der Ball im engen Sektor an der Pyramide liegen, darf er bis zu 20 cm abgelegt werden.",
            tipp = "Über die Bande spielen statt zwischen die Pyramiden zielen: die Spitzen lenken den Ball unberechenbar ab.",
            shape = LaneShape.straight, glyph = LaneGlyph.pyramiden,
        ),
        MinigolfStandardLane(
            2, "Salto",
            hindernis = "Senkrechte Schlaufe (Looping), die der Ball durchlaufen soll.",
            weg = "Durch den Salto. Springt der Ball vom Eingang direkt in den Ausgang, zählt das ebenfalls – über die Außenwände gesprungen nicht.",
            mass = "Hindernis beginnt 2,00–3,00 m nach dem Bahnanfang, Durchgang 15–22 cm breit.",
            tipp = "Ein Salto braucht Tempo, sonst bleibt der Ball oben stehen. Mittig und deutlich fester schlagen als sonst.",
            shape = LaneShape.straight, glyph = LaneGlyph.salto,
        ),
        MinigolfStandardLane(
            3, "Schräger Kreis mit Niere",
            hindernis = "Geneigter Kreis, davor ein nierenförmiges Hindernis mit Tunnel.",
            weg = "Entweder als Geradschlag durch den Tunnel oder am Hindernis vorbei.",
            mass = "Hindernismitte 2,00–3,00 m nach Bahnbeginn, Durchgang 15–22 cm, zwischen Hindernis und Bande 8–13 cm.",
            tipp = "Der Tunnel ist die Ass-Linie, aber schmal. Wer unsicher steht, spielt außen vorbei und legt sich den zweiten Schlag kurz.",
            shape = LaneShape.tiltedCircle, glyph = LaneGlyph.niere,
        ),
        MinigolfStandardLane(
            4, "Doppelwellen",
            hindernis = "Zwei Wellen quer über die Bahn.",
            weg = "Nicht festgelegt.",
            mass = "Siehe Zeichnung im Regelwerk.",
            tipp = "Die Wellen bremsen stärker, als sie aussehen. Lieber einen Hauch zu fest als zu kurz – zurückrollen kostet den Schlag.",
            shape = LaneShape.straight, glyph = LaneGlyph.doppelwellen,
        ),
        MinigolfStandardLane(
            5, "Liegende Schleife",
            hindernis = "Waagrechte Schleife, durch die der Ball einen ganzen Bogen läuft.",
            weg = "Durch Eingang und kompletten Gang der Schleife bis zur Grenzlinie. Springt der Ball über die Wülste oder lässt den Gang aus, hat er den Weg verlassen.",
            mass = "Hindernis beginnt 2,00–3,00 m nach Bahnbeginn.",
            tipp = "Tempo entscheidet: zu fest und der Ball hebt aus der Rinne, zu weich und er bleibt in der Schleife. Konstant gleich anspielen und die Stelle merken.",
            shape = LaneShape.straight, glyph = LaneGlyph.liegendeSchleife,
        ),
        MinigolfStandardLane(
            6, "Brücke",
            hindernis = "Hügel über die ganze Bahnbreite, Grenzlinie direkt hinter dem Scheitelpunkt.",
            weg = "Nicht festgelegt.",
            mass = "Grenzlinie unmittelbar hinter dem Scheitelpunkt des Hügels.",
            tipp = "Über den Scheitelpunkt kommen ist Pflicht – bleibt der Ball davor, rollt er zurück zum Abschlag. Fest genug schlagen, dass er hinten sauber ausläuft.",
            shape = LaneShape.straight, glyph = LaneGlyph.bruecke,
        ),
        MinigolfStandardLane(
            7, "Sprungschanze mit Netz",
            hindernis = "Schanze am Abschlag, Ziel ist ein aufgehängtes Netz.",
            weg = "Direkte Fluglinie vom Abschlag über die Schanze in das Netz.",
            mass = "Netzring 50 cm Durchmesser, Hindernisende 2,50 m nach Bahnbeginn, Ringunterkante 70–80 cm über dem Abschlag.",
            tipp = "Nicht schießen, sondern beschleunigen: die Schanze macht die Höhe. Ball genau in die Mitte der Rampe legen und die Linie vor dem Schlag von hinten prüfen.",
            shape = LaneShape.jump, glyph = LaneGlyph.sprungschanze,
        ),
        MinigolfStandardLane(
            8, "Gerade Bahn mit Zielkreisfenster",
            hindernis = "Quermauer vor dem Zielkreis mit schmalem Fenster.",
            weg = "Durch das Fenster.",
            mass = "Hinteres Hindernisende 5,00 m nach Bahnbeginn, Durchgang 10–15 cm.",
            tipp = "Reine Geradschlag-Bahn. Fußstellung und Puttlinie sauber ausrichten, Tempo nur so viel, dass der Ball im Zielkreis liegen bleibt.",
            shape = LaneShape.straight, glyph = LaneGlyph.zielkreisfenster,
        ),
        MinigolfStandardLane(
            9, "Rohr",
            hindernis = "Rohr, durch das der Ball laufen muss.",
            weg = "Nur durch das Rohr.",
            mass = "Hinteres Hindernisende 5,00 m nach Bahnbeginn, Rohrdurchmesser 4,5–6,5 cm. Grenzlinie direkt am Rohrausgang.",
            tipp = "Am Rohr gibt es keine Alternative: trifft der Ball nicht, ist der Schlag weg. Ruhig und mittig anspielen, das Rohr nimmt selbst wenig Tempo.",
            shape = LaneShape.straight, glyph = LaneGlyph.rohr,
        ),
        MinigolfStandardLane(
            10, "Stäbe",
            hindernis = "Zwei oder drei Stäbe, abwechselnd von links und rechts in die Bahn.",
            weg = "Zwischen den Hindernissen durch – nicht darüber hinweg.",
            mass = "Jeder Stab kann links oder rechts stehen, der dritte kann fehlen. Ablegen 20 cm zurück bzw. 30 cm vorwärts.",
            tipp = "Slalom über die Banden: Winkel merken, nicht Kraft erhöhen. Beim ersten Versuch lieber sicher bis hinter den letzten Stab spielen.",
            shape = LaneShape.straight, glyph = LaneGlyph.staebe,
        ),
        MinigolfStandardLane(
            11, "Labyrinth",
            hindernis = "Kasten mit vier Eingängen, nur einer führt ins Ziel.",
            weg = "Bei vier Eingängen führt nur der zweite von rechts (spiegelbildlich von links) zum Ziel, die anderen sind versperrt.",
            mass = "Eingänge 12–20 cm breit. Ziel ist der Bereich zwischen den senkrechten Wänden im Zentrum.",
            tipp = "Erst den richtigen Eingang suchen, dann die Bandenlinie darauf ausrichten. Zu fest gespielt springt der Ball im Kasten wieder heraus.",
            shape = LaneShape.straight, glyph = LaneGlyph.labyrinth,
        ),
        MinigolfStandardLane(
            12, "Stumpfe Kegel",
            hindernis = "Zwei abgeflachte Kegel in der Bahnmitte.",
            weg = "Nicht festgelegt.",
            mass = "Grenzlinie unmittelbar hinter dem Scheitelpunkt des zweiten Kegels.",
            tipp = "Der Weg an den Kegeln vorbei ist eng – über eine Bande arbeiten und die Grenzlinie hinter dem zweiten Kegel sicher überspielen.",
            shape = LaneShape.straight, glyph = LaneGlyph.kegel,
        ),
        MinigolfStandardLane(
            13, "Doppelkeile",
            hindernis = "Zwei Keile, Ziel ist eine Schüssel.",
            weg = "Nicht festgelegt.",
            mass = "Schüsseleingang 12–25 cm. Füllmaterial darf bewegt, aber nicht ergänzt oder entfernt werden.",
            tipp = "Die Schüssel schluckt Tempo: eher fest anspielen, damit der Ball über den Rand kommt. Vor dem Schlag prüfen, wie der Sand liegt.",
            shape = LaneShape.straight, glyph = LaneGlyph.doppelkeile,
        ),
        MinigolfStandardLane(
            14, "Passagen",
            hindernis = "Mehrere Durchgänge mit Hügeln.",
            weg = "Nicht festgelegt.",
            mass = "Hinteres Hindernisende 5,00 m nach Bahnbeginn. Grenzlinie in jeder Passage hinter dem Scheitelpunkt des letzten Hügels.",
            tipp = "Eine Passage auswählen und dabei bleiben. Der Hügel darin braucht Tempo, sonst rollt der Ball in die Passage zurück.",
            shape = LaneShape.straight, glyph = LaneGlyph.passagen,
        ),
        MinigolfStandardLane(
            15, "Mittelhügel",
            hindernis = "Hügel quer in der Bahnmitte.",
            weg = "Nicht festgelegt.",
            mass = "Grenzlinie 50 cm vom Abschlag. Bleibt der Ball auf dem Hügel liegen, darf er 20 cm parallel zur Bande abgelegt oder von dort weitergespielt werden.",
            tipp = "Klassische Ass-Bahn: mittig, gerade, mit dem Tempo, das den Ball hinter dem Hügel gerade noch ins Loch trägt.",
            shape = LaneShape.straight, glyph = LaneGlyph.mittelhuegel,
        ),
        MinigolfStandardLane(
            16, "Vulkan",
            hindernis = "Kegelförmiger Aufbau mit Zielloch im Plateau.",
            weg = "Nicht festgelegt.",
            mass = "Zwei Alternativen. Bei Alternative 1 zählt das komplette Plateau als Ziel, sonst nur das Zielloch.",
            tipp = "Den Ball über die Flanke hochlaufen lassen, nicht gerade auf die Spitze. Zu fest und er springt über das Plateau hinaus.",
            shape = LaneShape.straight, glyph = LaneGlyph.vulkan,
        ),
        MinigolfStandardLane(
            17, "„V\"-Hindernis",
            hindernis = "Zwei Stäbe oder Dreiecke, die sich zum Ziel hin verengen.",
            weg = "Nicht festgelegt – der Ball darf die Hindernisse aber nicht überspringen.",
            mass = "Vier Alternativen: Stäbe oder Dreiecke, unten offen oder mit Zielloch bzw. Mulde.",
            tipp = "Flach in das V spielen, damit der Ball zwischen den Schenkeln geführt wird. Ein Sprung über den Stab kostet den vorgesehenen Weg.",
            shape = LaneShape.straight, glyph = LaneGlyph.vHindernis,
        ),
        MinigolfStandardLane(
            18, "Winkel",
            hindernis = "Schräge Wand, die die Bahn diagonal verengt.",
            weg = "Nicht festgelegt.",
            mass = "Hindernislänge 40–60 cm, Grenzlinie 50 cm vom Abschlag.",
            tipp = "Über den Winkel spielen wie über eine Bande: Einfallswinkel gleich Ausfallswinkel. Einmal die richtige Stelle gefunden, immer gleich anspielen.",
            shape = LaneShape.straight, glyph = LaneGlyph.winkel,
        ),
        MinigolfStandardLane(
            19, "Blitz",
            hindernis = "Zwei versetzte Schrägen – die Bahn beschreibt ein Z.",
            weg = "Nicht festgelegt.",
            mass = "Siehe Zeichnung im Regelwerk.",
            tipp = "Doppelte Bandenrechnung: die erste Schräge bestimmt alles. Kurz vor der ersten Kante anspielen und den Rest laufen lassen.",
            shape = LaneShape.straight, glyph = LaneGlyph.blitz,
        ),
        MinigolfStandardLane(
            20, "Gerade Bahn ohne Hindernisse",
            hindernis = "Freie Bahn, nur Abschlag und Zielkreis.",
            weg = "Nicht festgelegt.",
            mass = "Grenzlinie 50 cm vom Abschlag.",
            tipp = "Die einfachste und deshalb undankbarste Bahn: hier wird ein Ass erwartet. Linie ruhig ausrichten und mit gleichmäßigem Tempo durchziehen.",
            shape = LaneShape.straight, glyph = LaneGlyph.keines,
        ),
        MinigolfStandardLane(
            21, "Schräger Kreis ohne Hindernisse",
            hindernis = "Gerade Bahn, die in einen geneigten Kreis mündet.",
            weg = "Nicht festgelegt.",
            mass = "Bahn ohne Grenzlinie.",
            tipp = "Der Kreis ist geneigt – der Ball läuft immer zur tiefsten Stelle. Die Kurve mit einrechnen und höher anspielen als das Loch liegt.",
            shape = LaneShape.tiltedCircle, glyph = LaneGlyph.keines,
        ),
        MinigolfStandardLane(
            22, "Plateau",
            hindernis = "Rampe auf eine erhöhte Fläche mit dem Ziel oben.",
            weg = "Nicht festgelegt.",
            mass = "Rampenbeginn 2,50–3,50 m nach Bahnbeginn, Rampeneingang 12–25 cm, Plateaumitte 5,00–6,00 m.",
            tipp = "Die Rampe braucht genug Tempo, das Plateau verzeiht aber kein Übermaß – der Ball fällt hinten herunter. Rampeneingang mittig treffen.",
            shape = LaneShape.straight, glyph = LaneGlyph.plateau,
        ),
        MinigolfStandardLane(
            23, "Auflaufkeil mit Zielfenster",
            hindernis = "Ansteigender Keil mit schmalem Fenster.",
            weg = "Durch das Fenster.",
            mass = "Durchgang 10–15 cm.",
            tipp = "Der Keil bremst und richtet auf: einen Hauch fester spielen als bei einer flachen Fensterbahn, dafür genauso gerade.",
            shape = LaneShape.straight, glyph = LaneGlyph.auflaufkeil,
        ),
        MinigolfStandardLane(
            24, "Steilschräge ohne Hindernisse",
            hindernis = "Stark ansteigende Bahn ohne weiteres Hindernis.",
            weg = "Nicht festgelegt.",
            mass = "Bahn ohne Grenzlinie.",
            tipp = "Die Steigung frisst Tempo. Deutlich fester schlagen und die Linie halten – kommt der Ball nicht hoch, rollt er den ganzen Weg zurück.",
            shape = LaneShape.straight, glyph = LaneGlyph.steilschraege,
        ),
        MinigolfStandardLane(
            25, "Schräger Kreis mit „V\"-Hindernis",
            hindernis = "Geneigter Kreis mit V-förmigem Hindernis vor dem Ziel.",
            weg = "Nicht festgelegt – der Ball darf die Hindernisse nicht überspringen.",
            mass = "Vier Alternativen wie bei Bahn 17. Bahn ohne Grenzlinie.",
            tipp = "Neigung und V zusammen denken: der Ball läuft in den Hang und von dort in das V. Höher anspielen, als der direkte Weg aussieht.",
            shape = LaneShape.tiltedCircle, glyph = LaneGlyph.vHindernis,
        ),
        MinigolfStandardLane(
            26, "Gerade Bahn mit Rampe",
            hindernis = "Rampe quer in der Bahn.",
            weg = "Über die Rampe.",
            mass = "Grenzlinie am Ende der Rampe. Rampe rechteckig oder trapezförmig.",
            tipp = "Über die Rampe heißt: mit Tempo. Kommt der Ball nur halb hoch, liegt er wieder vor der Rampe und der Weg gilt nicht als überwunden.",
            shape = LaneShape.straight, glyph = LaneGlyph.rampe,
        ),
        MinigolfStandardLane(
            27, "Raute",
            hindernis = "Rautenförmiges Hindernis mit engen Durchgängen an beiden Seiten.",
            weg = "Nicht festgelegt.",
            mass = "Seitliche Durchgänge 10–15 cm. Grenzlinie beidseits hinter der engsten Stelle.",
            tipp = "Eine Seite wählen und den Durchgang über die Bande anspielen. Frontal auf die Raute ist der Ball nicht zu kontrollieren.",
            shape = LaneShape.straight, glyph = LaneGlyph.raute,
        ),
        MinigolfStandardLane(
            28, "Gerade Bahn mit Zielhügel",
            hindernis = "Hügel rund um das Ziel.",
            weg = "Nicht festgelegt.",
            mass = "Hügelhöhe 10–20 cm, Durchmesser 40–60 cm. Grenzlinie 50 cm vom Abschlag.",
            tipp = "Der Hügel muss überwunden werden, ohne dass der Ball über das Loch hinausschießt. Tempo so wählen, dass er oben gerade ausrollt.",
            shape = LaneShape.straight, glyph = LaneGlyph.zielhuegel,
        ),
    )
}
