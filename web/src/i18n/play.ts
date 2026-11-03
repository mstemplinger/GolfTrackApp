import type { ChallengeId } from "@/lib/minigolfChallenges";

/**
 * Texte des Spielbereichs auf `play.golftrack.app` – Startseite, QR-Ziel
 * `/p/<kennung>` und die Zählkarte im Browser.
 *
 * Der Rest der Website kann nur Deutsch und Englisch. Hier stehen dagegen
 * Gäste am Abschlag, die den Code scannen – auch aus Frankreich, Italien,
 * Spanien, Polen oder Tschechien. Deshalb dieselben sieben Sprachen wie in der
 * App, mit denselben Begriffen wie in `Localizable.xcstrings` (Bahn heißt
 * „hole" / „piste" / „pista" / „tor" / „dráha", nie „lane").
 *
 * Die Adresse bleibt dabei für alle gleich – das Schild am Abschlag kennt nur
 * eine. Welche Sprache jemand sieht, entscheidet `lib/playLang.ts`: erst die
 * eigene Wahl (Cookie), dann die Sprache des Browsers, sonst Deutsch.
 */

export const PLAY_LANGS = ["de", "en", "fr", "it", "es", "pl", "cs"] as const;
export type PlayLang = (typeof PLAY_LANGS)[number];

export const PLAY_LANG_COOKIE = "gt_lang";

/** Jede Sprache in ihrem eigenen Namen – so findet sie auch, wer die anderen nicht liest. */
export const PLAY_LANG_NAMES: Record<PlayLang, string> = {
  de: "Deutsch",
  en: "English",
  fr: "Français",
  it: "Italiano",
  es: "Español",
  pl: "Polski",
  cs: "Čeština",
};

export function isPlayLang(value: unknown): value is PlayLang {
  return typeof value === "string" && (PLAY_LANGS as readonly string[]).includes(value);
}

/** Kopf- und Fußzeile gibt es nur auf Deutsch und Englisch. */
export function siteLang(lang: PlayLang): "de" | "en" {
  return lang === "de" ? "de" : "en";
}

interface ChallengeCopy {
  name: string;
  rule: string;
  unit: string;
}

export interface PlayCopy {
  langLabel: string;
  // Startseite
  startMarginal: string;
  startTitle: string;
  startIntro: string;
  startMetaTitle: string;
  startMetaDescription: string;
  startEmpty: string;
  startEmptyLink: string;
  startFootnote: string;
  startDirectory: string;
  // Platzauswahl
  searchLabel: string;
  searchPlaceholder: string;
  courseCount: (n: number) => string;
  courseCountFiltered: (shown: number, total: number) => string;
  searchNone: string;
  searchNoneAfter: string;
  // QR-Ziel
  kindGolf: string;
  kindMinigolf: string;
  welcomeGolf: string;
  welcomeMinigolf: string;
  openInApp: string;
  getApp: string;
  playNoApp: string;
  playNoAppHint: string;
  playFootnote: string;
  moreAbout: (name: string) => string;
  playMetaTitle: (name: string) => string;
  playMetaDescription: (name: string) => string;
  notFound: string;
  // Zählkarte
  holesUnit: (kind: "golf" | "minigolf") => string;
  holeUnit: (kind: "golf" | "minigolf") => string;
  setupTitle: string;
  setupText: string;
  player: (n: number) => string;
  playerName: (n: number) => string;
  addPlayer: string;
  removePlayer: string;
  startRound: (holes: number, unit: string) => string;
  resumeTitle: string;
  holeOf: (unit: string, hole: number, holes: number) => string;
  keepCounting: string;
  discard: string;
  result: string;
  total: (n: number) => string;
  done: string;
  back: string;
  next: string;
  strokeLess: (name: string) => string;
  strokeMore: (name: string) => string;
  trophies: string;
  nobody: string;
  newRound: string;
  closeCounter: string;
  contests: string;
  contestsActive: (n: number) => string;
  contestsNone: string;
  contestsExplain: string;
  change: string;
  add: string;
  stillOpen: string;
  contestsTeaser: string;
  challenges: Record<ChallengeId, ChallengeCopy>;
}

const de: PlayCopy = {
  langLabel: "Sprache",
  startMarginal: "Spielen",
  startTitle: "Runde starten",
  startIntro:
    "Normalerweise scannst du den Code am Abschlag. Geht das nicht, such deinen Platz hier heraus – der Rest ist derselbe.",
  startMetaTitle: "Runde starten · GolfTrack",
  startMetaDescription:
    "Platz auswählen und mitzählen – mit der App, ohne Installation oder direkt im Browser.",
  startEmpty: "Noch kein Platz freigegeben.",
  startEmptyLink: "Trag deinen ein.",
  startFootnote:
    "Mit installierter App öffnet sich die Runde dort. Auf dem iPhone ohne App genügt der App Clip, ganz ohne Installation. Sonst zählst du im Browser mit.",
  startDirectory: "Alle Plätze im Verzeichnis",
  searchLabel: "Platz suchen",
  searchPlaceholder: "Platz oder Ort suchen",
  courseCount: (n) => `${n} Plätze`,
  courseCountFiltered: (shown, total) => `${shown} von ${total}`,
  searchNone:
    "Kein Platz gefunden. Steht deiner noch nicht im Verzeichnis, kann ihn der Betreiber unter",
  searchNoneAfter: "eintragen.",
  kindGolf: "Golfplatz",
  kindMinigolf: "Minigolf",
  welcomeGolf: "Schön, dass du da bist! Ab jetzt zählen wir für dich mit – Loch für Loch.",
  welcomeMinigolf: "Schön, dass du da bist! Ab jetzt zählen wir für dich mit – Bahn für Bahn.",
  openInApp: "In der App öffnen",
  getApp: "GolfTrack laden",
  playNoApp: "Ohne App mitzählen",
  playNoAppHint: "Direkt hier im Browser – nichts installieren",
  playFootnote:
    "Die Zählkarte hier reicht für die Runde. Laufspur, Schlagweiten, Handicap und die Auswertung über alle Runden gibt es in der App.",
  moreAbout: (name) => `Mehr zu ${name}`,
  playMetaTitle: (name) => `${name} · Runde mitzählen`,
  playMetaDescription: (name) =>
    `Zähle deine Runde auf ${name} mit – mit der App, ohne Installation oder direkt im Browser.`,
  notFound: "Platz nicht gefunden · GolfTrack",
  holesUnit: (kind) => (kind === "golf" ? "Löcher" : "Bahnen"),
  holeUnit: (kind) => (kind === "golf" ? "Loch" : "Bahn"),
  setupTitle: "Ohne App mitzählen",
  setupText:
    "Direkt im Browser, ohne Anmeldung. Der Stand bleibt auf diesem Gerät – auch wenn du das Fenster schließt.",
  player: (n) => `Spieler ${n}`,
  playerName: (n) => `Name von Spieler ${n}`,
  addPlayer: "+ Hinzufügen",
  removePlayer: "− Entfernen",
  startRound: (holes, unit) => `Runde starten · ${holes} ${unit}`,
  resumeTitle: "Angefangene Runde",
  holeOf: (unit, hole, holes) => `${unit} ${hole} von ${holes}`,
  keepCounting: "Weiterzählen",
  discard: "Verwerfen",
  result: "Ergebnis",
  total: (n) => `Gesamt: ${n}`,
  done: "Fertig",
  back: "‹ Zurück",
  next: "Weiter ›",
  strokeLess: (name) => `Ein Schlag weniger für ${name}`,
  strokeMore: (name) => `Ein Schlag mehr für ${name}`,
  trophies: "Pokale",
  nobody: "niemand",
  newRound: "Neue Runde",
  closeCounter: "Zähler schließen",
  contests: "Wettkämpfe",
  contestsActive: (n) => `${n} aktiv`,
  contestsNone: "keine",
  contestsExplain:
    "Laufen neben der Schlagwertung mit. Gewertet wird immer die ganze Karte, egal wann du einen dazunimmst.",
  change: "Ändern",
  add: "Hinzufügen",
  stillOpen: "noch offen",
  contestsTeaser: "Serie, Asse, Bahnenduell und mehr – laufen nebenher mit.",
  challenges: {
    streak: {
      name: "Serie",
      rule: "Wer schafft die längste Serie an Bahnen hintereinander mit höchstens 2 Schlägen?",
      unit: "in Folge",
    },
    aces: { name: "Ass-Jäger", rule: "Wer locht am häufigsten mit dem ersten Schlag ein?", unit: "Asse" },
    holeWins: {
      name: "Bahnenduell",
      rule: "Wer gewinnt die meisten Bahnen allein? Bei Gleichstand auf einer Bahn bekommt sie niemand.",
      unit: "Bahnen",
    },
    steady: {
      name: "Nervenstark",
      rule: "Wer leistet sich die wenigsten Patzer mit 4 Schlägen oder mehr?",
      unit: "Patzer",
    },
    comeback: {
      name: "Aufholjagd",
      rule: "Wer spielt die zweite Hälfte am deutlichsten besser als die erste?",
      unit: "Schläge besser",
    },
    finish: {
      name: "Schlussspurt",
      rule: "Wer braucht auf den letzten 3 Bahnen die wenigsten Schläge?",
      unit: "Schläge",
    },
  },
};

const en: PlayCopy = {
  langLabel: "Language",
  startMarginal: "Play",
  startTitle: "Start a round",
  startIntro:
    "Usually you scan the code at the tee. If that doesn't work, pick your course here – everything else is the same.",
  startMetaTitle: "Start a round · GolfTrack",
  startMetaDescription:
    "Pick a course and keep score – in the app, without installing anything, or right in the browser.",
  startEmpty: "No course approved yet.",
  startEmptyLink: "Add yours.",
  startFootnote:
    "If the app is installed, the round opens there. On an iPhone without the app, the App Clip is enough – no installation needed. Otherwise you keep score in the browser.",
  startDirectory: "All courses in the directory",
  searchLabel: "Search course",
  searchPlaceholder: "Search course or town",
  courseCount: (n) => `${n} courses`,
  courseCountFiltered: (shown, total) => `${shown} of ${total}`,
  searchNone: "No course found. If yours isn't listed yet, the operator can add it at",
  searchNoneAfter: ".",
  kindGolf: "Golf course",
  kindMinigolf: "Mini golf",
  welcomeGolf: "Great to have you here! From now on we keep score for you – hole by hole.",
  welcomeMinigolf: "Great to have you here! From now on we keep score for you – hole by hole.",
  openInApp: "Open in the app",
  getApp: "Get GolfTrack",
  playNoApp: "Keep score without the app",
  playNoAppHint: "Right here in your browser – nothing to install",
  playFootnote:
    "The scorecard here is all you need for the round. Shot tracking, distances, handicap and stats across all your rounds are in the app.",
  moreAbout: (name) => `More about ${name}`,
  playMetaTitle: (name) => `${name} · Keep score`,
  playMetaDescription: (name) =>
    `Keep score of your round at ${name} – in the app, without installing anything, or right in the browser.`,
  notFound: "Course not found · GolfTrack",
  holesUnit: () => "holes",
  holeUnit: () => "Hole",
  setupTitle: "Keep score without the app",
  setupText:
    "Right in the browser, no sign-up. The score stays on this device – even if you close the window.",
  player: (n) => `Player ${n}`,
  playerName: (n) => `Name of player ${n}`,
  addPlayer: "+ Add",
  removePlayer: "− Remove",
  startRound: (holes, unit) => `Start round · ${holes} ${unit}`,
  resumeTitle: "Round in progress",
  holeOf: (unit, hole, holes) => `${unit} ${hole} of ${holes}`,
  keepCounting: "Continue",
  discard: "Discard",
  result: "Result",
  total: (n) => `Total: ${n}`,
  done: "Done",
  back: "‹ Back",
  next: "Next ›",
  strokeLess: (name) => `One stroke less for ${name}`,
  strokeMore: (name) => `One stroke more for ${name}`,
  trophies: "Trophies",
  nobody: "nobody",
  newRound: "New round",
  closeCounter: "Close scorecard",
  contests: "Contests",
  contestsActive: (n) => `${n} active`,
  contestsNone: "none",
  contestsExplain:
    "They run alongside the stroke count. The whole card always counts, no matter when you add one.",
  change: "Change",
  add: "Add",
  stillOpen: "still open",
  contestsTeaser: "Streak, aces, hole duel and more – running alongside.",
  challenges: {
    streak: {
      name: "Streak",
      rule: "Who gets the longest run of holes in a row with at most 2 strokes?",
      unit: "in a row",
    },
    aces: { name: "Ace hunter", rule: "Who holes out with the first stroke most often?", unit: "aces" },
    holeWins: {
      name: "Hole duel",
      rule: "Who wins the most holes outright? A tied hole goes to nobody.",
      unit: "holes",
    },
    steady: {
      name: "Nerves of steel",
      rule: "Who has the fewest blow-ups of 4 strokes or more?",
      unit: "blow-ups",
    },
    comeback: {
      name: "Comeback",
      rule: "Who plays the second half most clearly better than the first?",
      unit: "strokes better",
    },
    finish: {
      name: "Final sprint",
      rule: "Who needs the fewest strokes on the last 3 holes?",
      unit: "strokes",
    },
  },
};

const fr: PlayCopy = {
  langLabel: "Langue",
  startMarginal: "Jouer",
  startTitle: "Démarrer la partie",
  startIntro:
    "D'habitude, tu scannes le code au départ. Si ça ne marche pas, choisis ton parcours ici – le reste est identique.",
  startMetaTitle: "Démarrer la partie · GolfTrack",
  startMetaDescription:
    "Choisis un parcours et compte tes coups – dans l'app, sans installation ou directement dans le navigateur.",
  startEmpty: "Aucun parcours validé pour l'instant.",
  startEmptyLink: "Ajoute le tien.",
  startFootnote:
    "Si l'app est installée, la partie s'y ouvre. Sur iPhone sans l'app, l'App Clip suffit, sans aucune installation. Sinon, tu comptes dans le navigateur.",
  startDirectory: "Tous les parcours de l'annuaire",
  searchLabel: "Rechercher un parcours",
  searchPlaceholder: "Parcours ou ville",
  courseCount: (n) => `${n} parcours`,
  courseCountFiltered: (shown, total) => `${shown} sur ${total}`,
  searchNone:
    "Aucun parcours trouvé. Si le tien n'est pas encore dans l'annuaire, l'exploitant peut l'ajouter sur",
  searchNoneAfter: ".",
  kindGolf: "Parcours de golf",
  kindMinigolf: "Minigolf",
  welcomeGolf: "Ravi de te voir ! Désormais, on compte pour toi – trou après trou.",
  welcomeMinigolf: "Ravi de te voir ! Désormais, on compte pour toi – piste après piste.",
  openInApp: "Ouvrir dans l'app",
  getApp: "Télécharger GolfTrack",
  playNoApp: "Compter sans l'app",
  playNoAppHint: "Directement dans le navigateur – rien à installer",
  playFootnote:
    "La carte de score ici suffit pour la partie. Le tracé, les distances, le handicap et les statistiques de toutes tes parties sont dans l'app.",
  moreAbout: (name) => `En savoir plus sur ${name}`,
  playMetaTitle: (name) => `${name} · Compter ses coups`,
  playMetaDescription: (name) =>
    `Compte ta partie à ${name} – dans l'app, sans installation ou directement dans le navigateur.`,
  notFound: "Parcours introuvable · GolfTrack",
  holesUnit: (kind) => (kind === "golf" ? "trous" : "pistes"),
  holeUnit: (kind) => (kind === "golf" ? "Trou" : "Piste"),
  setupTitle: "Compter sans l'app",
  setupText:
    "Directement dans le navigateur, sans inscription. Le score reste sur cet appareil – même si tu fermes la fenêtre.",
  player: (n) => `Joueur ${n}`,
  playerName: (n) => `Nom du joueur ${n}`,
  addPlayer: "+ Ajouter",
  removePlayer: "− Retirer",
  startRound: (holes, unit) => `Démarrer · ${holes} ${unit}`,
  resumeTitle: "Partie en cours",
  holeOf: (unit, hole, holes) => `${unit} ${hole} sur ${holes}`,
  keepCounting: "Continuer",
  discard: "Abandonner",
  result: "Résultat",
  total: (n) => `Total : ${n}`,
  done: "Terminé",
  back: "‹ Retour",
  next: "Suivant ›",
  strokeLess: (name) => `Un coup de moins pour ${name}`,
  strokeMore: (name) => `Un coup de plus pour ${name}`,
  trophies: "Trophées",
  nobody: "personne",
  newRound: "Nouvelle partie",
  closeCounter: "Fermer la carte",
  contests: "Concours",
  contestsActive: (n) => `${n} actif${n > 1 ? "s" : ""}`,
  contestsNone: "aucun",
  contestsExplain:
    "Ils se jouent en parallèle du score. C'est toujours toute la carte qui compte, peu importe quand tu en ajoutes un.",
  change: "Modifier",
  add: "Ajouter",
  stillOpen: "en cours",
  contestsTeaser: "Série, as, duel de pistes et plus – en parallèle.",
  challenges: {
    streak: {
      name: "Série",
      rule: "Qui réussit la plus longue série de pistes d'affilée en 2 coups maximum ?",
      unit: "d'affilée",
    },
    aces: { name: "Chasseur d'as", rule: "Qui rentre le plus souvent la balle au premier coup ?", unit: "as" },
    holeWins: {
      name: "Duel de pistes",
      rule: "Qui gagne seul le plus de pistes ? En cas d'égalité sur une piste, personne ne l'emporte.",
      unit: "pistes",
    },
    steady: {
      name: "Sang-froid",
      rule: "Qui fait le moins de ratés à 4 coups ou plus ?",
      unit: "ratés",
    },
    comeback: {
      name: "Remontée",
      rule: "Qui joue la seconde moitié nettement mieux que la première ?",
      unit: "coups de mieux",
    },
    finish: {
      name: "Sprint final",
      rule: "Qui a besoin du moins de coups sur les 3 dernières pistes ?",
      unit: "coups",
    },
  },
};

const it: PlayCopy = {
  langLabel: "Lingua",
  startMarginal: "Gioca",
  startTitle: "Inizia giro",
  startIntro:
    "Di solito scansioni il codice alla partenza. Se non funziona, scegli qui il tuo campo – il resto è uguale.",
  startMetaTitle: "Inizia giro · GolfTrack",
  startMetaDescription:
    "Scegli un campo e segna i colpi – nell'app, senza installare nulla o direttamente nel browser.",
  startEmpty: "Nessun campo ancora approvato.",
  startEmptyLink: "Aggiungi il tuo.",
  startFootnote:
    "Se l'app è installata, il giro si apre lì. Su iPhone senza app basta l'App Clip, senza installazione. Altrimenti segni i colpi nel browser.",
  startDirectory: "Tutti i campi nell'elenco",
  searchLabel: "Cerca campo",
  searchPlaceholder: "Cerca campo o località",
  courseCount: (n) => `${n} campi`,
  courseCountFiltered: (shown, total) => `${shown} di ${total}`,
  searchNone:
    "Nessun campo trovato. Se il tuo non è ancora nell'elenco, il gestore può aggiungerlo su",
  searchNoneAfter: ".",
  kindGolf: "Campo da golf",
  kindMinigolf: "Minigolf",
  welcomeGolf: "Che bello averti qui! Da ora contiamo noi per te – buca dopo buca.",
  welcomeMinigolf: "Che bello averti qui! Da ora contiamo noi per te – pista dopo pista.",
  openInApp: "Apri nell'app",
  getApp: "Scarica GolfTrack",
  playNoApp: "Conta senza app",
  playNoAppHint: "Direttamente nel browser – niente da installare",
  playFootnote:
    "Lo segnapunti qui basta per il giro. Tracciato, distanze, handicap e statistiche su tutti i giri sono nell'app.",
  moreAbout: (name) => `Di più su ${name}`,
  playMetaTitle: (name) => `${name} · Segna i colpi`,
  playMetaDescription: (name) =>
    `Segna il tuo giro a ${name} – nell'app, senza installare nulla o direttamente nel browser.`,
  notFound: "Campo non trovato · GolfTrack",
  holesUnit: (kind) => (kind === "golf" ? "buche" : "piste"),
  holeUnit: (kind) => (kind === "golf" ? "Buca" : "Pista"),
  setupTitle: "Segna i colpi senza app",
  setupText:
    "Direttamente nel browser, senza registrazione. Il punteggio resta su questo dispositivo – anche se chiudi la finestra.",
  player: (n) => `Giocatore ${n}`,
  playerName: (n) => `Nome del giocatore ${n}`,
  addPlayer: "+ Aggiungi",
  removePlayer: "− Rimuovi",
  startRound: (holes, unit) => `Inizia giro · ${holes} ${unit}`,
  resumeTitle: "Giro in corso",
  holeOf: (unit, hole, holes) => `${unit} ${hole} di ${holes}`,
  keepCounting: "Continua",
  discard: "Scarta",
  result: "Risultato",
  total: (n) => `Totale: ${n}`,
  done: "Fatto",
  back: "‹ Indietro",
  next: "Avanti ›",
  strokeLess: (name) => `Un colpo in meno per ${name}`,
  strokeMore: (name) => `Un colpo in più per ${name}`,
  trophies: "Trofei",
  nobody: "nessuno",
  newRound: "Nuovo giro",
  closeCounter: "Chiudi segnapunti",
  contests: "Sfide",
  contestsActive: (n) => `${n} ${n === 1 ? "attiva" : "attive"}`,
  contestsNone: "nessuna",
  contestsExplain:
    "Si giocano accanto al punteggio. Conta sempre tutta la scheda, non importa quando ne aggiungi una.",
  change: "Modifica",
  add: "Aggiungi",
  stillOpen: "ancora aperta",
  contestsTeaser: "Serie, assi, duello di piste e altro – in parallelo.",
  challenges: {
    streak: {
      name: "Serie",
      rule: "Chi fa la serie più lunga di piste consecutive con al massimo 2 colpi?",
      unit: "di fila",
    },
    aces: { name: "Cacciatore di assi", rule: "Chi imbuca più spesso al primo colpo?", unit: "assi" },
    holeWins: {
      name: "Duello di piste",
      rule: "Chi vince da solo più piste? In caso di parità su una pista, non va a nessuno.",
      unit: "piste",
    },
    steady: {
      name: "Nervi saldi",
      rule: "Chi fa meno disastri da 4 colpi o più?",
      unit: "disastri",
    },
    comeback: {
      name: "Rimonta",
      rule: "Chi gioca la seconda metà nettamente meglio della prima?",
      unit: "colpi in meno",
    },
    finish: {
      name: "Volata finale",
      rule: "Chi usa meno colpi sulle ultime 3 piste?",
      unit: "colpi",
    },
  },
};

const es: PlayCopy = {
  langLabel: "Idioma",
  startMarginal: "Jugar",
  startTitle: "Empezar vuelta",
  startIntro:
    "Normalmente escaneas el código en la salida. Si no funciona, elige aquí tu campo – lo demás es igual.",
  startMetaTitle: "Empezar vuelta · GolfTrack",
  startMetaDescription:
    "Elige un campo y lleva la cuenta – en la app, sin instalar nada o directamente en el navegador.",
  startEmpty: "Todavía no hay ningún campo aprobado.",
  startEmptyLink: "Añade el tuyo.",
  startFootnote:
    "Si tienes la app instalada, la vuelta se abre allí. En un iPhone sin la app basta el App Clip, sin instalar nada. Si no, llevas la cuenta en el navegador.",
  startDirectory: "Todos los campos del directorio",
  searchLabel: "Buscar campo",
  searchPlaceholder: "Buscar campo o localidad",
  courseCount: (n) => `${n} campos`,
  courseCountFiltered: (shown, total) => `${shown} de ${total}`,
  searchNone:
    "No se encontró ningún campo. Si el tuyo aún no está en el directorio, el operador puede añadirlo en",
  searchNoneAfter: ".",
  kindGolf: "Campo de golf",
  kindMinigolf: "Minigolf",
  welcomeGolf: "¡Qué bien que estés aquí! A partir de ahora contamos por ti – hoyo a hoyo.",
  welcomeMinigolf: "¡Qué bien que estés aquí! A partir de ahora contamos por ti – pista a pista.",
  openInApp: "Abrir en la app",
  getApp: "Descargar GolfTrack",
  playNoApp: "Contar sin la app",
  playNoAppHint: "Directamente en el navegador – sin instalar nada",
  playFootnote:
    "La tarjeta de aquí basta para la vuelta. El recorrido, las distancias, el hándicap y las estadísticas de todas tus vueltas están en la app.",
  moreAbout: (name) => `Más sobre ${name}`,
  playMetaTitle: (name) => `${name} · Llevar la cuenta`,
  playMetaDescription: (name) =>
    `Lleva la cuenta de tu vuelta en ${name} – en la app, sin instalar nada o directamente en el navegador.`,
  notFound: "Campo no encontrado · GolfTrack",
  holesUnit: (kind) => (kind === "golf" ? "hoyos" : "pistas"),
  holeUnit: (kind) => (kind === "golf" ? "Hoyo" : "Pista"),
  setupTitle: "Contar sin la app",
  setupText:
    "Directamente en el navegador, sin registro. La puntuación se queda en este dispositivo – aunque cierres la ventana.",
  player: (n) => `Jugador ${n}`,
  playerName: (n) => `Nombre del jugador ${n}`,
  addPlayer: "+ Añadir",
  removePlayer: "− Quitar",
  startRound: (holes, unit) => `Empezar vuelta · ${holes} ${unit}`,
  resumeTitle: "Vuelta en curso",
  holeOf: (unit, hole, holes) => `${unit} ${hole} de ${holes}`,
  keepCounting: "Seguir",
  discard: "Descartar",
  result: "Resultado",
  total: (n) => `Total: ${n}`,
  done: "Listo",
  back: "‹ Atrás",
  next: "Siguiente ›",
  strokeLess: (name) => `Un golpe menos para ${name}`,
  strokeMore: (name) => `Un golpe más para ${name}`,
  trophies: "Trofeos",
  nobody: "nadie",
  newRound: "Nueva vuelta",
  closeCounter: "Cerrar tarjeta",
  contests: "Retos",
  contestsActive: (n) => `${n} ${n === 1 ? "activo" : "activos"}`,
  contestsNone: "ninguno",
  contestsExplain:
    "Se juegan junto a la puntuación. Siempre cuenta toda la tarjeta, da igual cuándo añadas uno.",
  change: "Cambiar",
  add: "Añadir",
  stillOpen: "pendiente",
  contestsTeaser: "Racha, ases, duelo de pistas y más – en paralelo.",
  challenges: {
    streak: {
      name: "Racha",
      rule: "¿Quién logra la racha más larga de pistas seguidas con 2 golpes como máximo?",
      unit: "seguidas",
    },
    aces: { name: "Cazador de ases", rule: "¿Quién emboca más veces al primer golpe?", unit: "ases" },
    holeWins: {
      name: "Duelo de pistas",
      rule: "¿Quién gana más pistas en solitario? Si hay empate en una pista, no es para nadie.",
      unit: "pistas",
    },
    steady: {
      name: "Nervios de acero",
      rule: "¿Quién comete menos fallos de 4 golpes o más?",
      unit: "fallos",
    },
    comeback: {
      name: "Remontada",
      rule: "¿Quién juega la segunda mitad claramente mejor que la primera?",
      unit: "golpes menos",
    },
    finish: {
      name: "Esprint final",
      rule: "¿Quién necesita menos golpes en las últimas 3 pistas?",
      unit: "golpes",
    },
  },
};

/** Polnisch: Zahlwörter je nach Endung (1 / 2–4 / 5+), wie in der App. */
function plPlural(n: number, one: string, few: string, many: string): string {
  if (n === 1) return one;
  const mod10 = n % 10;
  const mod100 = n % 100;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

/** Tschechisch: 1 / 2–4 / 5+. */
function csPlural(n: number, one: string, few: string, many: string): string {
  if (n === 1) return one;
  if (n >= 2 && n <= 4) return few;
  return many;
}

const pl: PlayCopy = {
  langLabel: "Język",
  startMarginal: "Graj",
  startTitle: "Rozpocznij rundę",
  startIntro:
    "Zwykle skanujesz kod przy starcie. Jeśli to nie działa, wybierz tutaj swoje pole – reszta jest taka sama.",
  startMetaTitle: "Rozpocznij rundę · GolfTrack",
  startMetaDescription:
    "Wybierz pole i licz uderzenia – w aplikacji, bez instalacji albo prosto w przeglądarce.",
  startEmpty: "Nie zatwierdzono jeszcze żadnego pola.",
  startEmptyLink: "Dodaj swoje.",
  startFootnote:
    "Jeśli aplikacja jest zainstalowana, runda otworzy się w niej. Na iPhonie bez aplikacji wystarczy App Clip – bez instalacji. W przeciwnym razie liczysz w przeglądarce.",
  startDirectory: "Wszystkie pola w katalogu",
  searchLabel: "Szukaj pola",
  searchPlaceholder: "Szukaj pola lub miejscowości",
  courseCount: (n) => `${n} ${plPlural(n, "pole", "pola", "pól")}`,
  courseCountFiltered: (shown, total) => `${shown} z ${total}`,
  searchNone:
    "Nie znaleziono pola. Jeśli twojego jeszcze nie ma w katalogu, zarządca może je dodać na",
  searchNoneAfter: ".",
  kindGolf: "Pole golfowe",
  kindMinigolf: "Minigolf",
  welcomeGolf: "Miło, że jesteś! Od teraz liczymy za ciebie – dołek po dołku.",
  welcomeMinigolf: "Miło, że jesteś! Od teraz liczymy za ciebie – tor po torze.",
  openInApp: "Otwórz w aplikacji",
  getApp: "Pobierz GolfTrack",
  playNoApp: "Licz bez aplikacji",
  playNoAppHint: "Prosto w przeglądarce – bez instalowania",
  playFootnote:
    "Ta karta wyników wystarczy na rundę. Ślad gry, odległości, handicap i statystyki ze wszystkich rund są w aplikacji.",
  moreAbout: (name) => `Więcej o ${name}`,
  playMetaTitle: (name) => `${name} · Licz uderzenia`,
  playMetaDescription: (name) =>
    `Licz swoją rundę na ${name} – w aplikacji, bez instalacji albo prosto w przeglądarce.`,
  notFound: "Nie znaleziono pola · GolfTrack",
  holesUnit: (kind) => (kind === "golf" ? "dołków" : "torów"),
  holeUnit: (kind) => (kind === "golf" ? "Dołek" : "Tor"),
  setupTitle: "Licz bez aplikacji",
  setupText:
    "Prosto w przeglądarce, bez logowania. Wynik zostaje na tym urządzeniu – nawet jeśli zamkniesz okno.",
  player: (n) => `Gracz ${n}`,
  playerName: (n) => `Imię gracza ${n}`,
  addPlayer: "+ Dodaj",
  removePlayer: "− Usuń",
  startRound: (holes, unit) => `Rozpocznij rundę · ${holes} ${unit}`,
  resumeTitle: "Rozpoczęta runda",
  holeOf: (unit, hole, holes) => `${unit} ${hole} z ${holes}`,
  keepCounting: "Licz dalej",
  discard: "Odrzuć",
  result: "Wynik",
  total: (n) => `Razem: ${n}`,
  done: "Gotowe",
  back: "‹ Wstecz",
  next: "Dalej ›",
  strokeLess: (name) => `Jedno uderzenie mniej dla: ${name}`,
  strokeMore: (name) => `Jedno uderzenie więcej dla: ${name}`,
  trophies: "Puchary",
  nobody: "nikt",
  newRound: "Nowa runda",
  closeCounter: "Zamknij kartę",
  contests: "Rywalizacje",
  contestsActive: (n) => `${n} ${plPlural(n, "aktywna", "aktywne", "aktywnych")}`,
  contestsNone: "brak",
  contestsExplain:
    "Toczą się obok liczenia uderzeń. Liczy się zawsze cała karta, niezależnie od tego, kiedy jakąś dodasz.",
  change: "Zmień",
  add: "Dodaj",
  stillOpen: "jeszcze otwarte",
  contestsTeaser: "Seria, asy, pojedynek na torach i więcej – równolegle.",
  challenges: {
    streak: {
      name: "Seria",
      rule: "Kto zrobi najdłuższą serię torów z rzędu, każdy w maksymalnie 2 uderzeniach?",
      unit: "z rzędu",
    },
    aces: { name: "Łowca asów", rule: "Kto najczęściej trafia do dołka pierwszym uderzeniem?", unit: "asy" },
    holeWins: {
      name: "Pojedynek na torach",
      rule: "Kto samodzielnie wygra najwięcej torów? Przy remisie na torze nie dostaje go nikt.",
      unit: "torów",
    },
    steady: {
      name: "Nerwy ze stali",
      rule: "Kto zaliczy najmniej wpadek po 4 uderzenia lub więcej?",
      unit: "wpadek",
    },
    comeback: {
      name: "Pogoń",
      rule: "Kto zagra drugą połowę wyraźnie lepiej niż pierwszą?",
      unit: "uderzeń lepiej",
    },
    finish: {
      name: "Finisz",
      rule: "Kto potrzebuje najmniej uderzeń na ostatnich 3 torach?",
      unit: "uderzeń",
    },
  },
};

const cs: PlayCopy = {
  langLabel: "Jazyk",
  startMarginal: "Hrát",
  startTitle: "Spustit kolo",
  startIntro:
    "Obvykle naskenuješ kód u odpaliště. Pokud to nejde, vyber si hřiště tady – zbytek je stejný.",
  startMetaTitle: "Spustit kolo · GolfTrack",
  startMetaDescription:
    "Vyber hřiště a počítej rány – v aplikaci, bez instalace nebo přímo v prohlížeči.",
  startEmpty: "Zatím není schválené žádné hřiště.",
  startEmptyLink: "Přidej své.",
  startFootnote:
    "Pokud máš aplikaci nainstalovanou, kolo se otevře v ní. Na iPhonu bez aplikace stačí App Clip – bez instalace. Jinak počítáš v prohlížeči.",
  startDirectory: "Všechna hřiště v adresáři",
  searchLabel: "Hledat hřiště",
  searchPlaceholder: "Hledat hřiště nebo obec",
  courseCount: (n) => `${n} ${csPlural(n, "hřiště", "hřiště", "hřišť")}`,
  courseCountFiltered: (shown, total) => `${shown} z ${total}`,
  searchNone:
    "Hřiště nenalezeno. Pokud tvoje ještě není v adresáři, provozovatel ho může přidat na",
  searchNoneAfter: ".",
  kindGolf: "Golfové hřiště",
  kindMinigolf: "Minigolf",
  welcomeGolf: "Vítej! Od teď počítáme za tebe – jamku po jamce.",
  welcomeMinigolf: "Vítej! Od teď počítáme za tebe – dráhu po dráze.",
  openInApp: "Otevřít v aplikaci",
  getApp: "Stáhnout GolfTrack",
  playNoApp: "Počítat bez aplikace",
  playNoAppHint: "Přímo v prohlížeči – nic neinstaluješ",
  playFootnote:
    "Tahle karta na kolo stačí. Záznam trasy, vzdálenosti, handicap a statistiky ze všech kol najdeš v aplikaci.",
  moreAbout: (name) => `Více o ${name}`,
  playMetaTitle: (name) => `${name} · Počítat rány`,
  playMetaDescription: (name) =>
    `Počítej své kolo na ${name} – v aplikaci, bez instalace nebo přímo v prohlížeči.`,
  notFound: "Hřiště nenalezeno · GolfTrack",
  holesUnit: (kind) => (kind === "golf" ? "jamek" : "drah"),
  holeUnit: (kind) => (kind === "golf" ? "Jamka" : "Dráha"),
  setupTitle: "Počítat bez aplikace",
  setupText:
    "Přímo v prohlížeči, bez přihlášení. Stav zůstane na tomto zařízení – i když okno zavřeš.",
  player: (n) => `Hráč ${n}`,
  playerName: (n) => `Jméno hráče ${n}`,
  addPlayer: "+ Přidat",
  removePlayer: "− Odebrat",
  startRound: (holes, unit) => `Spustit kolo · ${holes} ${unit}`,
  resumeTitle: "Rozehrané kolo",
  holeOf: (unit, hole, holes) => `${unit} ${hole} z ${holes}`,
  keepCounting: "Pokračovat",
  discard: "Zahodit",
  result: "Výsledek",
  total: (n) => `Celkem: ${n}`,
  done: "Hotovo",
  back: "‹ Zpět",
  next: "Další ›",
  strokeLess: (name) => `O ránu méně: ${name}`,
  strokeMore: (name) => `O ránu více: ${name}`,
  trophies: "Poháry",
  nobody: "nikdo",
  newRound: "Nové kolo",
  closeCounter: "Zavřít kartu",
  contests: "Soutěže",
  contestsActive: (n) => `${n} ${csPlural(n, "aktivní", "aktivní", "aktivních")}`,
  contestsNone: "žádné",
  contestsExplain:
    "Běží souběžně s počítáním ran. Hodnotí se vždy celá karta, ať soutěž přidáš kdykoli.",
  change: "Změnit",
  add: "Přidat",
  stillOpen: "zatím otevřené",
  contestsTeaser: "Série, esa, souboj na drahách a další – běží souběžně.",
  challenges: {
    streak: {
      name: "Série",
      rule: "Kdo zahraje nejdelší sérii drah za sebou, každou nejvýš na 2 rány?",
      unit: "za sebou",
    },
    aces: { name: "Lovec es", rule: "Kdo nejčastěji trefí jamku první ranou?", unit: "es" },
    holeWins: {
      name: "Souboj na drahách",
      rule: "Kdo vyhraje sám nejvíc drah? Při remíze na dráze ji nezíská nikdo.",
      unit: "drah",
    },
    steady: {
      name: "Ocelové nervy",
      rule: "Kdo má nejméně zaváhání na 4 rány a více?",
      unit: "zaváhání",
    },
    comeback: {
      name: "Stíhací jízda",
      rule: "Kdo zahraje druhou polovinu nejvýrazněji lépe než první?",
      unit: "ran lépe",
    },
    finish: {
      name: "Závěrečný finiš",
      rule: "Kdo potřebuje na posledních 3 drahách nejméně ran?",
      unit: "ran",
    },
  },
};

const COPY: Record<PlayLang, PlayCopy> = { de, en, fr, it, es, pl, cs };

export function playCopy(lang: PlayLang): PlayCopy {
  return COPY[lang];
}

/**
 * Bevorzugte Sprache aus dem `Accept-Language`-Kopf: die erste unterstützte,
 * nach Gewichtung sortiert. `de-AT` zählt als `de`, `cz` (wie auf manchen
 * Aushängen) als `cs`.
 */
export function langFromAcceptLanguage(header: string | null | undefined): PlayLang | null {
  if (!header) return null;
  const entries = header
    .split(",")
    .map((part, index) => {
      const [tag, ...params] = part.trim().split(";");
      const q = params.find((p) => p.trim().startsWith("q="));
      return { tag: tag.toLowerCase(), q: q ? Number(q.trim().slice(2)) || 0 : 1, index };
    })
    .filter((entry) => entry.tag && entry.q > 0)
    .sort((a, b) => b.q - a.q || a.index - b.index);

  for (const { tag } of entries) {
    const base = tag.split("-")[0];
    const lang = base === "cz" ? "cs" : base;
    if (isPlayLang(lang)) return lang;
  }
  return null;
}
