import type { Lang } from "./routes";

/**
 * Sämtliche Oberflächentexte. Eine Datei, zwei Sprachen – so bleibt sichtbar,
 * wenn eine Fassung hinterherhinkt. Weitere Sprachen kommen als zusätzlicher
 * Schlüssel dazu, ohne dass sich an den Views etwas ändert.
 */

const de = {
  meta: {
    locale: "de-DE",
    title: "GolfTrack – Scorekarte, Handicap und Laufspur für deine Runde",
    description:
      "GolfTrack zeichnet deine Runde auf: Scorekarte, WHS-Handicap, Schlagpositionen und Statistiken. Für iPhone und Apple Watch. Golf- und Minigolfanlagen können sich hier eintragen.",
  },
  nav: {
    home: "Start",
    directory: "Plätze",
    submit: "Anlage eintragen",
    support: "Hilfe",
    api: "API",
    langSwitch: "English",
    appStore: "Im App Store",
    menu: "Menü",
    menuClose: "Menü schließen",
  },
  home: {
    eyebrow: "iPhone · Apple Watch",
    title: "Deine Runde,\nLoch für Loch.",
    lead: "Jede Runde aufzeichnen, jeden Schlag verorten, das Handicap automatisch fortschreiben. Dieser Teil kostet nichts und braucht kein Abo.",
    ctaPrimary: "Im App Store laden",
    ctaSecondary: "Anlage eintragen",
    heroShotAlt: "Startbildschirm von GolfTrack mit Handicap-Index, letzter Runde und Wetter am Platz",
    scorecardCaption: "Wie in der App: Loch, Par, Schläge.",
    scorecardLabels: { title: "Scorekarte", hole: "Loch", par: "Par", me: "Ich", out: "Out" },

    roundEyebrow: "02 — Ablauf",
    roundTitle: "So läuft eine Runde",
    roundLead:
      "Vom Anlegen bis zur fertigen Karte sind es vier Bildschirme; die Bilder unten stammen aus der App selbst.",
    roundSteps: [
      {
        shot: "18-neue-runde",
        title: "Anlegen",
        body: "Platz, Bag, Datum, Spielform. Den Platz suchst du nach Entfernung, die Schläger kommen aus deinem Bag.",
        alt: "Runden-Setup mit Platzauswahl, Bag, Datum und Spielmodus",
      },
      {
        shot: "19-live-scorecard",
        title: "Loch für Loch",
        body: "Entfernung zur Fahne, eine Schlägerempfehlung aus deinen gemessenen Distanzen, Schläge über zwei Knöpfe. Putts, Fairway und Grün liegen im selben Bildschirm.",
        alt: "Aktuelles Loch mit 350 Metern zur Fahne, Schlägerempfehlung Driver und Schlagzähler",
      },
      {
        shot: "20-scorecard-mini",
        title: "Zwischenstand",
        body: "Unten läuft die Scorekarte mit. Damit siehst du ohne Wechsel des Bildschirms, wo du gegenüber Par stehst.",
        alt: "Loch-Ansicht mit eingeblendeter Mini-Scorekarte am unteren Rand",
      },
      {
        shot: "08-rundendetail",
        title: "Danach",
        body: "Die volle Karte, dazu die Schlagkarte, Putts, Fairwaytreffer und die Strecke, die du gelaufen bist.",
        alt: "Rundendetail mit Scorekarten-Tabelle und Schlagkarte",
      },
    ],

    featuresEyebrow: "03 — App",
    featuresTitle: "Was GolfTrack mitschreibt",
    features: [
      {
        title: "Scorekarte",
        body: "Schläge, Putts, Fairway und Grün pro Loch am iPhone, die Schläge auch an der Uhr. Auch für mehrere Mitspieler.",
      },
      {
        title: "Handicap nach WHS",
        body: "Aus deinen gewerteten Runden rechnet die App dein Handicap fort. Course und Slope Rating des Platzes fließen ein.",
      },
      {
        title: "Laufspur & Schlagkarte",
        body: "Deine Wege über den Platz, jeder Schlag verortet. Daraus schätzt die App Abschlag, Fahne und Fairwayverlauf.",
      },
      {
        title: "Statistiken",
        body: "Schlägerdistanzen, Fairwaytrefferquote, Putts pro Runde, Entwicklung über die Saison.",
      },
      {
        title: "Minigolf-Modus",
        body: "Bahn für Bahn zählen, für die ganze Gruppe. Wer den QR-Code an der Anlage scannt, startet die Runde mit der richtigen Bahnenzahl.",
      },
      {
        title: "Wetter am Platz",
        body: "Wind, Regenwahrscheinlichkeit und Temperatur für die nächsten Stunden, abgefragt für den Ort des Platzes.",
      },
    ],
    watchEyebrow: "04 — Apple Watch",
    watchTitle: "Am Handgelenk",
    watchBody:
      "Die Uhr trägt den Teil, den man mitten im Spiel braucht. Runde starten, Schläge zählen, Schlagpunkt setzen, nach dem letzten Loch die Übersicht.",
    watchPoints: [
      "Golf oder Minigolf, 9 oder 18 Löcher",
      "Schläge zählen über − und +",
      "Schlagpunkt per GPS setzen",
      "Rundenübersicht am Ende",
    ],
    watchNote:
      "Putts, Fairway- und Grüntreffer trägst du am iPhone nach. Die Watch-App gibt es nur auf Deutsch.",
    watchAlts: [
      "Apple Watch: Rundenstart mit Golf oder Minigolf und 9 oder 18 Löchern",
      "Apple Watch: Schlagzähler mit Minus, Weiter und Plus",
    ],

    trackingEyebrow: "05 — GPS",
    trackingTitle: "Positions-Tracking",
    trackingBody:
      "GolfTrack kann aufzeichnen, wo du während der Runde unterwegs warst, und daraus lernen, wie die Löcher liegen. Nach ein paar Runden zeigt die App die Entfernung zur Fahne, weil sie die Lage der Löcher aus deinen eigenen Wegen kennt.",
    trackingPoints: [
      "Standardmäßig ausgeschaltet",
      "Läuft nur während einer Runde",
      "Daten bleiben auf deinem iPhone",
      "Jederzeit löschbar",
    ],
    trackingShotAlt: "Schlagkarte im Vollbild mit den Positionen aller Schläge eines Lochs",

    statsEyebrow: "06 — Zahlen",
    statsTitle: "Handicap und Statistik",
    statsBody:
      "Nach jeder gewerteten Runde rechnet die App den WHS-Index fort, mit Course und Slope Rating des gespielten Platzes. Daneben stehen die Werte, aus denen eine Saison besteht: Fairwaytreffer, Grüns in Regulation, Putts pro Runde, gemessene Distanz je Schläger.",
    statsAlts: [
      "Profil mit WHS-Handicap und den Score Differentials der letzten Runden",
      "Diagramm des Score-Verlaufs über zehn Runden",
    ],

    modesEyebrow: "07 — Spielformen",
    modesTitle: "19 Spielformen",
    modesLead:
      "Gewählt wird beim Anlegen der Runde, gerechnet wird danach von allein. Einige Namen stehen mehrfach da, weil dieselbe Form nach Zählspiel, Stableford oder Matchplay gewertet werden kann.",
    modeGroups: [
      {
        title: "Einzeln",
        items: [
          ["Zählspiel", ""],
          ["Stableford", ""],
          ["Erado®", "Zählspiel"],
          ["Skins", "Zählspiel"],
          ["Duplicate®", "Stableford"],
          ["Matchplay", ""],
        ],
      },
      {
        title: "Zu zweit",
        items: [
          ["Better Ball", "Zählspiel"],
          ["Better Ball", "Stableford"],
          ["Better Ball", "Matchplay"],
          ["2-Mann Scramble", "Zählspiel"],
          ["Scramble", "Matchplay"],
          ["Vierer", "Matchplay"],
          ["Greensome", "Matchplay"],
        ],
      },
      {
        title: "Im Team",
        items: [
          ["Best Ball", "Zählspiel"],
          ["Best Ball", "Stableford"],
          ["Scramble", "Zählspiel"],
          ["Match/Net", "Zählspiel"],
          ["Duplicate® Scramble", "Stableford"],
          ["Irish Rumble", "Best Ball"],
        ],
      },
    ],
    modesFooter: "Dazu neun Achievements über Game Center.",

    priceEyebrow: "08 — Kosten",
    priceTitle: "Preise und Abos",
    priceFree:
      "Runden aufzeichnen, Scorekarte, Handicap und Statistiken sind kostenlos und brauchen kein Konto bei mir.",
    pricePlans: [
      { title: "Training", body: "17 Audio-Trainings, vom Griff bis zum Grün lesen." },
      { title: "Caddy", body: "Sprach-Assistent während der Runde: Schlägerwahl, Entfernungen, Fragen zu den Regeln." },
      { title: "Pro", body: "Training und Caddy in einem Abo, mit unbegrenzten Caddy-Gesprächen." },
    ],
    priceNote: "Alle drei laufen monatlich und lassen sich jederzeit im App Store kündigen; dort steht auch der Preis.",
    priceShotAlt: "Audio-Trainings nach Kategorien, mit Fortschritt je Einheit",

    coursesEyebrow: "09 — Anlagen",
    coursesTitle: "Für Golfclubs und Minigolfanlagen",
    coursesBody:
      "Trag deine Anlage einmal ein: Löcher, Par, Stroke Index, Längen, Course und Slope Rating. Nach der Freigabe steht sie in der App, und Gäste wählen sie beim Rundenstart aus der Liste.",
    coursesPoints: [
      { title: "Kostenlos", body: "Für die Anlage entstehen keine Kosten." },
      { title: "Geprüft", body: "Jede Einsendung wird vor der Veröffentlichung von Hand kontrolliert." },
      { title: "Änderbar", body: "Neue Längen oder ein neues Rating? Kurze Mail genügt." },
      { title: "QR-Start für Minigolf", body: "Gäste scannen den Code an der Kasse und zählen sofort mit." },
    ],
    coursesCta: "Anlage eintragen",
    directoryCta: "Alle Plätze ansehen",

    closingTitle: "Die nächste Runde mitschreiben",
    closingBody: "GolfTrack liegt kostenlos im App Store.",
    closingNote: "Ab iOS 17.0. Die Watch-App braucht watchOS 11.0.",
  },
  directory: {
    title: "Eingetragene Plätze",
    lead: "Alle freigegebenen Anlagen. Die App lädt genau diese Liste.",
    empty: "Bisher ist keine Anlage freigegeben.",
    golf: "Golfplätze",
    minigolf: "Minigolfanlagen",
    holes: "Löcher",
    lanes: "Bahnen",
    par: "Par",
    rating: "CR / Slope",
    submitCta: "Anlage eintragen",
    apiHint: "Dieselben Daten als JSON:",
    qrDownload: "QR-Code",
    qrTitle: "QR-Code für den Aushang",
  },
  submit: {
    title: "Anlage eintragen",
    lead: "Ein Formular, danach prüfe ich die Angaben von Hand und schalte den Platz frei. Pflichtfelder sind markiert, alles andere kann später nachgereicht werden.",
    kindLabel: "Was für eine Anlage?",
    kindGolf: "Golfplatz",
    kindGolfHint: "Mit Par, Stroke Index und Platzbewertung",
    kindMinigolf: "Minigolfanlage",
    kindMinigolfHint: "Bahnenzahl genügt",
    sectionBasics: "Die Anlage",
    sectionHoles: "Löcher",
    sectionHolesMinigolf: "Bahnen",
    sectionRating: "Platzbewertung",
    sectionExtras: "Zusatzangaben",
    sectionContact: "Dein Kontakt",
    name: "Name der Anlage",
    namePlaceholder: "Golf- und Landclub Bayerwald",
    location: "Ort",
    locationPlaceholder: "Sankt Englmar, Bayerischer Wald",
    country: "Land",
    holes: "Anzahl Löcher",
    holesMinigolf: "Anzahl Bahnen",
    coordinates: "Koordinaten",
    coordinatesHint:
      "Mittelpunkt der Anlage. In Apple Karten mit der rechten Maustaste auf den Platz klicken → „Koordinaten kopieren“.",
    latitude: "Breitengrad",
    longitude: "Längengrad",
    useLocation: "Aktuellen Standort übernehmen",
    locationDenied: "Standort nicht verfügbar. Bitte von Hand eintragen.",
    courseRating: "Course Rating",
    courseRatingHint: "Steht auf der Scorekarte, zum Beispiel 71,4",
    slopeRating: "Slope Rating",
    slopeRatingHint: "55 bis 155, Standard 113",
    holeTableHint:
      "Par ist Pflicht, Stroke Index und Länge helfen der App bei Handicap und Entfernungen. Die Werte lassen sich auch aus der Scorekarte abtippen.",
    holeTableHintMinigolf: "Optional: Par pro Bahn, falls deine Anlage eines vorgibt.",
    colHole: "Loch",
    colLane: "Bahn",
    colPar: "Par",
    colHcp: "HCP",
    colLength: "Länge (m)",
    autofillPar: "Par 72 vorbelegen",
    autofillHcp: "Stroke Index 1–18 vorbelegen",
    clearHoles: "Tabelle leeren",
    facilityNotes: "Platzinfos",
    facilityNotesHint: "Toiletten, Wasserstellen, Defibrillator, Gastronomie. Erscheint in der App unter dem Platz.",
    welcome: "Begrüßung",
    welcomeHint: "Wird Gästen beim Start der Runde angezeigt (vor allem für Minigolf per QR-Code).",
    website: "Website",
    phone: "Telefon",
    publicEmail: "E-Mail der Anlage",
    publicContactHint: "Diese Angaben sind später öffentlich sichtbar.",
    submitterName: "Dein Name",
    submitterEmail: "Deine E-Mail",
    submitterEmailHint: "Nur für Rückfragen zur Freigabe. Wird nicht veröffentlicht.",
    submitterRole: "Deine Funktion",
    submitterRolePlaceholder: "Sekretariat, Betreiber, Greenkeeper …",
    consent:
      "Ich bin berechtigt, diese Angaben einzureichen, und bin damit einverstanden, dass die Daten der Anlage in der App und auf dieser Website veröffentlicht werden.",
    submit: "Zur Prüfung einreichen",
    submitting: "Wird gesendet …",
    successTitle: "Angekommen.",
    successBody:
      "Danke! Ich schaue mir die Angaben an und melde mich per E-Mail, sobald der Platz in der App steht. Das dauert in der Regel ein bis zwei Tage.",
    successAgain: "Weitere Anlage eintragen",
    errorTitle: "Das hat nicht geklappt",
    errorGeneric: "Beim Senden ist etwas schiefgegangen. Bitte versuch es später noch einmal.",
    errorValidation: "Bitte prüf die markierten Felder.",
    errorRateLimit: "Es sind schon mehrere Einsendungen von dieser Verbindung eingegangen. Bitte später erneut versuchen.",
    required: "Pflichtfeld",
    optional: "optional",
  },
  support: {
    title: "Hilfe & Kontakt",
    lead: "Fragen zur App, zu einem Eintrag oder zu den Abos beantworte ich per Mail.",
    contactTitle: "Kontakt",
    faqTitle: "Häufige Fragen",
    faq: [
      {
        q: "Kostet die App etwas?",
        a: "Runden aufzeichnen, Scorekarte, Handicap und Statistiken sind kostenlos. Für die Audio-Trainings und den Sprach-Caddy gibt es Abos, einzeln oder zusammen als Pro.",
      },
      {
        q: "Wie kommt mein Platz in die App?",
        a: "Über das Formular auf dieser Seite. Nach der Prüfung erscheint die Anlage in der Platzliste der App.",
      },
      {
        q: "Etwas an unserem Platz hat sich geändert.",
        a: "Schreib mir eine kurze Mail mit den neuen Werten. Ich pflege sie ein, die Kennung des Platzes bleibt gleich.",
      },
      {
        q: "Werden meine Positionsdaten hochgeladen?",
        a: "Nein. Das Positions-Tracking ist standardmäßig aus, läuft nur während einer Runde und die Daten bleiben auf deinem iPhone.",
      },
      {
        q: "Wie funktioniert der QR-Code an der Minigolfanlage?",
        a: "Der Code enthält einen Link, der die App mit der richtigen Anlage und Bahnenzahl öffnet, sodass Gäste nach dem Scannen sofort zählen können.",
      },
    ],
  },
  legal: {
    imprintTitle: "Impressum",
    privacyTitle: "Datenschutzerklärung",
    lastUpdated: "Stand",
  },
  api: {
    title: "Platzdaten-API",
    lead: "Die App lädt die freigegebenen Plätze über diese öffentliche Schnittstelle. Sie ist ohne Schlüssel abrufbar.",
    endpointsTitle: "Endpunkte",
    fieldsTitle: "Felder",
    exampleTitle: "Beispielantwort",
  },
  footer: {
    tagline: "Scorekarte, Handicap und Laufspur für iPhone und Apple Watch.",
    legal: "Rechtliches",
    product: "Produkt",
    forCourses: "Für Anlagen",
    madeIn: "Gebaut im Bayerischen Wald.",
  },
};

type Content = typeof de;

const en: Content = {
  meta: {
    locale: "en-GB",
    title: "GolfTrack – scorecard, handicap and shot map for your round",
    description:
      "GolfTrack records your round: scorecard, WHS handicap, shot positions and statistics. For iPhone and Apple Watch. Golf and minigolf venues can list themselves here.",
  },
  nav: {
    home: "Home",
    directory: "Courses",
    submit: "List your venue",
    support: "Help",
    api: "API",
    langSwitch: "Deutsch",
    appStore: "On the App Store",
    menu: "Menu",
    menuClose: "Close menu",
  },
  home: {
    eyebrow: "iPhone · Apple Watch",
    title: "Your round,\nhole by hole.",
    lead: "Record every round, place every shot, keep the handicap up to date. That part is free and needs no subscription.",
    ctaPrimary: "Get it on the App Store",
    ctaSecondary: "List your venue",
    heroShotAlt: "GolfTrack home screen with handicap index, last round and weather at the course",
    scorecardCaption: "Just like the app: hole, par, strokes.",
    scorecardLabels: { title: "Scorecard", hole: "Hole", par: "Par", me: "Me", out: "Out" },

    roundEyebrow: "02 — A round",
    roundTitle: "How a round runs",
    roundLead:
      "From setting it up to the finished card it is four screens; the pictures below come from the app itself.",
    roundSteps: [
      {
        shot: "18-neue-runde",
        title: "Set up",
        body: "Course, bag, date, format. You pick the course by distance, the clubs come from your bag.",
        alt: "Round setup with course selection, bag, date and game mode",
      },
      {
        shot: "19-live-scorecard",
        title: "Hole by hole",
        body: "Distance to the pin, a club suggestion drawn from your measured distances, strokes on two buttons. Putts, fairway and green sit on the same screen.",
        alt: "Current hole showing 350 metres to the pin, a driver suggestion and the stroke counter",
      },
      {
        shot: "20-scorecard-mini",
        title: "Where you stand",
        body: "The scorecard runs along the bottom, so your score against par is there without changing screens.",
        alt: "Hole view with the mini scorecard shown along the bottom",
      },
      {
        shot: "08-rundendetail",
        title: "Afterwards",
        body: "The full card, plus the shot map, putts, fairways hit and the distance you walked.",
        alt: "Round detail with the scorecard table and the shot map",
      },
    ],

    featuresEyebrow: "03 — App",
    featuresTitle: "What GolfTrack keeps track of",
    features: [
      {
        title: "Scorecard",
        body: "Strokes, putts, fairways and greens per hole on the iPhone, strokes on the watch as well. Several players at once.",
      },
      {
        title: "WHS handicap",
        body: "Your handicap is carried forward from your counting rounds, using the course and slope rating of the course you played.",
      },
      {
        title: "Walking path & shot map",
        body: "Your route across the course with every shot placed on it. From that the app works out tees, pins and the shape of each fairway.",
      },
      {
        title: "Statistics",
        body: "Club distances, fairways hit, putts per round, and how it all moves across the season.",
      },
      {
        title: "Minigolf mode",
        body: "Count lane by lane for the whole group. Scanning the QR code at the venue starts the round with the right number of lanes.",
      },
      {
        title: "Weather on site",
        body: "Wind, chance of rain and temperature for the next few hours, taken for the location of the course.",
      },
    ],
    watchEyebrow: "04 — Apple Watch",
    watchTitle: "On your wrist",
    watchBody:
      "The watch carries the part you need mid-play. Start the round, count strokes, drop a shot point, see the summary after the last hole.",
    watchPoints: [
      "Golf or minigolf, 9 or 18 holes",
      "Count strokes with − and +",
      "Drop a shot point by GPS",
      "Round summary at the end",
    ],
    watchNote:
      "Putts, fairways and greens are entered on the iPhone afterwards. The watch app exists in German only.",
    watchAlts: [
      "Apple Watch: starting a round, choosing golf or minigolf and 9 or 18 holes",
      "Apple Watch: stroke counter with minus, next and plus",
    ],

    trackingEyebrow: "05 — GPS",
    trackingTitle: "Position tracking",
    trackingBody:
      "GolfTrack can record where you walked during a round and learn from it how the holes are laid out. After a few rounds it shows the distance to the pin, because it has worked out the layout from your own walks.",
    trackingPoints: [
      "Off by default",
      "Runs only during a round",
      "Data stays on your iPhone",
      "Delete it whenever you like",
    ],
    trackingShotAlt: "Full-screen shot map with the position of every shot on a hole",

    statsEyebrow: "06 — Numbers",
    statsTitle: "Handicap and statistics",
    statsBody:
      "After every counting round the app carries your WHS index forward, using the course and slope rating of the course you played. Next to it sit the numbers a season is made of: fairways hit, greens in regulation, putts per round, measured distance per club.",
    statsAlts: [
      "Profile with the WHS handicap and the score differentials of recent rounds",
      "Chart of the score trend across ten rounds",
    ],

    modesEyebrow: "07 — Formats",
    modesTitle: "19 game formats",
    modesLead:
      "You choose when setting up the round, the app does the scoring from there. Some names appear more than once because the same format can be scored as stroke play, Stableford or match play.",
    modeGroups: [
      {
        title: "Singles",
        items: [
          ["Stroke Play", ""],
          ["Stableford", ""],
          ["Erado®", "Stroke Play"],
          ["Skins", "Stroke Play"],
          ["Duplicate®", "Stableford"],
          ["Matchplay", ""],
        ],
      },
      {
        title: "Pairs",
        items: [
          ["Better Ball", "Stroke Play"],
          ["Better Ball", "Stableford"],
          ["Better Ball", "Matchplay"],
          ["2-Mann Scramble", "Stroke Play"],
          ["Scramble", "Matchplay"],
          ["Vierer", "Matchplay"],
          ["Greensome", "Matchplay"],
        ],
      },
      {
        title: "Teams",
        items: [
          ["Best Ball", "Stroke Play"],
          ["Best Ball", "Stableford"],
          ["Scramble", "Stroke Play"],
          ["Match/Net", "Stroke Play"],
          ["Duplicate® Scramble", "Stableford"],
          ["Irish Rumble", "Best Ball"],
        ],
      },
    ],
    modesFooter: "Plus nine achievements through Game Center.",

    priceEyebrow: "08 — Cost",
    priceTitle: "Price and subscriptions",
    priceFree:
      "Recording rounds, the scorecard, handicap and statistics are free and need no account with me.",
    pricePlans: [
      { title: "Training", body: "17 audio lessons, from the grip to reading a green." },
      { title: "Caddy", body: "A voice assistant during the round: club choice, distances, questions about the rules." },
      { title: "Pro", body: "Training and Caddy in one subscription, with unlimited Caddy conversations." },
    ],
    priceNote: "All three run monthly and can be cancelled in the App Store, where the price is shown as well.",
    priceShotAlt: "Audio lessons by category, with progress per lesson",

    coursesEyebrow: "09 — Venues",
    coursesTitle: "For golf clubs and minigolf venues",
    coursesBody:
      "List your venue once: holes, par, stroke index, lengths, course and slope rating. Once approved it appears in the app, and visitors pick it from the list when they start a round.",
    coursesPoints: [
      { title: "Free", body: "There is no cost for the venue." },
      { title: "Reviewed", body: "Every submission is checked by hand before it goes live." },
      { title: "Editable", body: "New lengths or a new rating? A short email is enough." },
      { title: "QR start for minigolf", body: "Guests scan the code at the desk and start counting straight away." },
    ],
    coursesCta: "List your venue",
    directoryCta: "See all courses",

    closingTitle: "Put the next round on record",
    closingBody: "GolfTrack is a free download on the App Store.",
    closingNote: "iOS 17.0 and up. The watch app needs watchOS 11.0.",
  },
  directory: {
    title: "Listed courses",
    lead: "Every approved venue. This is exactly the list the app loads.",
    empty: "No venue has been approved yet.",
    golf: "Golf courses",
    minigolf: "Minigolf venues",
    holes: "holes",
    lanes: "lanes",
    par: "Par",
    rating: "CR / slope",
    submitCta: "List your venue",
    apiHint: "The same data as JSON:",
    qrDownload: "QR code",
    qrTitle: "QR code for the venue sign",
  },
  submit: {
    title: "List a venue",
    lead: "One form. I check the details by hand and publish the course. Required fields are marked, everything else can follow later.",
    kindLabel: "What kind of venue?",
    kindGolf: "Golf course",
    kindGolfHint: "With par, stroke index and course rating",
    kindMinigolf: "Minigolf venue",
    kindMinigolfHint: "Number of lanes is enough",
    sectionBasics: "The venue",
    sectionHoles: "Holes",
    sectionHolesMinigolf: "Lanes",
    sectionRating: "Course rating",
    sectionExtras: "Extra details",
    sectionContact: "Your contact details",
    name: "Name of the venue",
    namePlaceholder: "Golf- und Landclub Bayerwald",
    location: "Town",
    locationPlaceholder: "Sankt Englmar, Bavarian Forest",
    country: "Country",
    holes: "Number of holes",
    holesMinigolf: "Number of lanes",
    coordinates: "Coordinates",
    coordinatesHint:
      "The centre of the venue. In Apple Maps, right-click the spot → “Copy coordinates”.",
    latitude: "Latitude",
    longitude: "Longitude",
    useLocation: "Use my current location",
    locationDenied: "Location unavailable. Please enter it manually.",
    courseRating: "Course rating",
    courseRatingHint: "Printed on the scorecard, for example 71.4",
    slopeRating: "Slope rating",
    slopeRatingHint: "55 to 155, standard is 113",
    holeTableHint:
      "Par is required; stroke index and length help the app with handicaps and distances. You can copy the values straight off your scorecard.",
    holeTableHintMinigolf: "Optional: par per lane, if your venue sets one.",
    colHole: "Hole",
    colLane: "Lane",
    colPar: "Par",
    colHcp: "SI",
    colLength: "Length (m)",
    autofillPar: "Prefill par 72",
    autofillHcp: "Prefill stroke index 1–18",
    clearHoles: "Clear table",
    facilityNotes: "Facilities",
    facilityNotesHint: "Toilets, water points, defibrillator, catering. Shown in the app under the course.",
    welcome: "Welcome message",
    welcomeHint: "Shown to guests when a round starts (mainly for minigolf via QR code).",
    website: "Website",
    phone: "Phone",
    publicEmail: "Email of the venue",
    publicContactHint: "These details will be publicly visible.",
    submitterName: "Your name",
    submitterEmail: "Your email",
    submitterEmailHint: "Only for questions about the listing. Never published.",
    submitterRole: "Your role",
    submitterRolePlaceholder: "Office, owner, greenkeeper …",
    consent:
      "I am entitled to submit these details and agree that the venue's data may be published in the app and on this website.",
    submit: "Submit for review",
    submitting: "Sending …",
    successTitle: "Received.",
    successBody:
      "Thank you! I will go through the details and email you as soon as the course is live in the app. That usually takes a day or two.",
    successAgain: "List another venue",
    errorTitle: "That did not work",
    errorGeneric: "Something went wrong while sending. Please try again later.",
    errorValidation: "Please check the highlighted fields.",
    errorRateLimit: "Several submissions have already come in from this connection. Please try again later.",
    required: "required",
    optional: "optional",
  },
  support: {
    title: "Help & contact",
    lead: "Questions about the app, a listing or the subscriptions are answered by email.",
    contactTitle: "Contact",
    faqTitle: "Frequently asked",
    faq: [
      {
        q: "Does the app cost anything?",
        a: "Recording rounds, the scorecard, handicap and statistics are free. The audio lessons and the voice caddy are subscriptions, separately or together as Pro.",
      },
      {
        q: "How does my course get into the app?",
        a: "Through the form on this site. After review the venue appears in the app's course list.",
      },
      {
        q: "Something about our course has changed.",
        a: "Send me a short email with the new values. I will update them, and the course keeps its identifier.",
      },
      {
        q: "Is my location data uploaded?",
        a: "No. Position tracking is off by default, runs only during a round, and the data stays on your iPhone.",
      },
      {
        q: "How does the QR code at a minigolf venue work?",
        a: "The code holds a link that opens the app with the right venue and number of lanes, so guests can scan it and start counting.",
      },
    ],
  },
  legal: {
    imprintTitle: "Legal notice",
    privacyTitle: "Privacy policy",
    lastUpdated: "Last updated",
  },
  api: {
    title: "Course data API",
    lead: "The app loads approved courses through this public endpoint. No key required.",
    endpointsTitle: "Endpoints",
    fieldsTitle: "Fields",
    exampleTitle: "Example response",
  },
  footer: {
    tagline: "Scorecard, handicap and shot map for iPhone and Apple Watch.",
    legal: "Legal",
    product: "Product",
    forCourses: "For venues",
    madeIn: "Built in the Bavarian Forest.",
  },
};

const dictionaries = { de, en } satisfies Record<Lang, Content>;

export function t(lang: Lang): Content {
  return dictionaries[lang];
}
