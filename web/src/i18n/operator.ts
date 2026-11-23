/**
 * Texte des Betreiber-Portals (operator.golftrack.app) – Deutsch und
 * Englisch. Welche Sprache gilt, entscheidet `lib/operatorLang.ts`.
 */

export const OPERATOR_LANGS = ["de", "en"] as const;
export type OperatorLang = (typeof OPERATOR_LANGS)[number];
export const OPERATOR_LANG_COOKIE = "gt_operator_lang";
/** Mindestlänge, wenn Betreiber ihr Passwort selbst setzen. */
export const MIN_OPERATOR_PASSWORD = 10;

export function isOperatorLang(v: unknown): v is OperatorLang {
  return v === "de" || v === "en";
}

export interface ReportCopy {
  locale: string;
  rounds: string;
  duration: string;
  durationNote: (n: number) => string;
  group: string;
  players: (n: number) => string;
  source: string;
  sources: Record<string, string>;
  anomaly: (unit: string, hole: number, delta: string, before: string, recent: string, minigolf: boolean) => string;
  perWeek: string;
  busy: string;
  weekdays: string[];
  slots: string[];
  difficulty: (unit: string) => string;
  par: string;
  hcpReal: string;
  hcpRealHint: string;
  avgStrokes: string;
  overPar: string;
  avgPutts: string;
  ace: string;
  samples: string;
  length: string;
  tees: string;
  noData: string;
  weekOf: (date: string) => string;
  unitHole: string;
  unitLane: string;
  unitHoles: string;
  unitLanes: string;
  teeNames: Record<string, string>;
  period: (days: number) => string;
  periodLabel: string;
}

export interface AccountCopy {
  nav: string;
  title: string;
  intro: string;
  profile: string;
  name: string;
  nameHint: string;
  email: string;
  emailHint: string;
  currentPassword: string;
  currentPasswordHint: string;
  save: string;
  saving: string;
  saved: string;
  passwordTitle: string;
  newPassword: string;
  newPasswordHint: (min: number) => string;
  repeatPassword: string;
  changePassword: string;
  passwordChanged: string;
  errWrongPassword: string;
  errEmailTaken: string;
  errEmailInvalid: string;
  errNameRequired: string;
  errTooShort: (min: number) => string;
  errMismatch: string;
  errSame: string;
  errLocked: string;
  coursesTitle: string;
  coursesIntro: string;
  courseName: string;
  requestChange: string;
  requested: string;
  pendingSince: (date: string) => string;
  errNameUnchanged: string;
  withdraw: string;
}

export interface OperatorCopy {
  report: ReportCopy;
  account: AccountCopy;
  portal: string;
  forOperators: string;
  signIn: string;
  signingIn: string;
  signInIntro: string;
  email: string;
  password: string;
  wrongCredentials: string;
  locked: string;
  noAccess: string;
  signOut: string;
  myCourses: string;
  roundStats: string;
  myCoursesIntro: (min: number) => string;
  noCourses: string;
  golfCourse: string;
  minigolf: string;
  minigolfFacility: string;
  roundsIn30: string;
  back: string;
  tooFew: string;
  tooFewText: (min: number) => string;
  nothingShared: string;
  footnote: string;
  titleLogin: string;
  titleHome: string;
  titleCourse: string;
}

const de: OperatorCopy = {
  report: {
    locale: "de-DE",
    rounds: "Gemeldete Runden",
    duration: "Ø Spieldauer (Median)",
    durationNote: (n) => `aus ${n} Runden mit Dauer`,
    group: "Ø Gruppengröße",
    players: (n) => `${n} Spieler`,
    source: "Quelle",
    sources: { app: "App", clip: "App Clip", web: "Browser" },
    anomaly: (unit, hole, delta, before, recent, minigolf) =>
      `${unit} ${hole} ist in den letzten 14 Tagen im Schnitt ${delta} Schläge schwerer als davor (${before} → ${recent}).${minigolf ? " Vielleicht beschädigt?" : ""}`,
    perWeek: "Runden pro Woche",
    busy: "Wann ist viel los?",
    weekdays: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"],
    slots: ["vormittags", "mittags", "nachmittags", "abends"],
    difficulty: (unit) => `Schwierigkeit je ${unit}`,
    par: "Par",
    hcpReal: "HCP · real",
    hcpRealHint: "Schwierigkeitsrang laut Scorecard / laut Runden",
    avgStrokes: "Ø Schläge",
    overPar: "über Par",
    avgPutts: "Ø Putts",
    ace: "Hole-in-one",
    samples: "Werte",
    length: "Gespielte Länge",
    tees: "Abschläge",
    noData: "Keine Angaben.",
    weekOf: (d) => `Woche ab ${d}`,
    unitHole: "Loch",
    unitLane: "Bahn",
    unitHoles: "Löcher",
    unitLanes: "Bahnen",
    teeNames: {},
    period: (d) => (d === 365 ? "1 Jahr" : `${d} Tage`),
    periodLabel: "Zeitraum",
  },
  account: {
    nav: "Mein Konto",
    title: "Mein Konto",
    intro: "Deine Angaben, dein Passwort und die Namen deiner Plätze.",
    profile: "Angaben",
    name: "Name",
    nameHint: "So erscheinst du im Portal und in unseren E-Mails.",
    email: "E-Mail (Anmeldename)",
    emailHint: "Damit meldest du dich an. Wir schicken einen Hinweis an die bisherige Adresse.",
    currentPassword: "Aktuelles Passwort",
    currentPasswordHint: "Nur nötig, wenn du die E-Mail-Adresse änderst.",
    save: "Speichern",
    saving: "Speichert …",
    saved: "Gespeichert.",
    passwordTitle: "Passwort ändern",
    newPassword: "Neues Passwort",
    newPasswordHint: (min) => `Mindestens ${min} Zeichen. Andere Geräte werden danach abgemeldet.`,
    repeatPassword: "Neues Passwort wiederholen",
    changePassword: "Passwort ändern",
    passwordChanged: "Passwort geändert. Andere Geräte sind abgemeldet.",
    errWrongPassword: "Das aktuelle Passwort stimmt nicht.",
    errEmailTaken: "Diese E-Mail-Adresse gehört schon zu einem anderen Konto.",
    errEmailInvalid: "Diese E-Mail-Adresse sieht nicht gültig aus.",
    errNameRequired: "Bitte einen Namen eintragen.",
    errTooShort: (min) => `Das neue Passwort braucht mindestens ${min} Zeichen.`,
    errMismatch: "Die beiden neuen Passwörter stimmen nicht überein.",
    errSame: "Das neue Passwort ist dasselbe wie das bisherige.",
    errLocked: "Zu viele Fehlversuche. Bitte in einer Viertelstunde noch einmal versuchen.",
    coursesTitle: "Namen meiner Plätze",
    coursesIntro:
      "Der Name erscheint in der GolfTrack-App, im App Clip und auf golftrack.app. Änderungen prüfen wir kurz, bevor sie überall sichtbar werden.",
    courseName: "Name",
    requestChange: "Änderung beantragen",
    requested: "Danke – wir prüfen die Änderung und schalten sie frei.",
    pendingSince: (d) => `Wartet auf Freigabe (seit ${d}):`,
    errNameUnchanged: "Der Name ist unverändert.",
    withdraw: "Zurückziehen",
  },
  portal: "Betreiber",
  forOperators: "Für Platzbetreiber",
  signIn: "Anmelden",
  signingIn: "Anmelden …",
  signInIntro:
    "Die anonyme Rundenstatistik deiner Anlage: wann viel los ist, wie lange gespielt wird und welche Bahnen schwer sind.",
  email: "E-Mail",
  password: "Passwort",
  wrongCredentials: "E-Mail oder Passwort stimmen nicht – oder das Konto ist gesperrt.",
  locked: "Zu viele Fehlversuche. Bitte in einer Viertelstunde noch einmal versuchen.",
  noAccess: "Noch keinen Zugang? Schreib an",
  signOut: "Abmelden",
  myCourses: "Meine Plätze",
  roundStats: "Rundenstatistik",
  myCoursesIntro: (min) =>
    `Anonym gemeldete Runden von Spielern, die zugestimmt haben. Zahlen erscheinen ab ${min} Runden im gewählten Zeitraum.`,
  noCourses: "Deinem Zugang ist noch kein Platz zugewiesen. Bitte melde dich bei contact@golftrack.app.",
  golfCourse: "Golfplatz",
  minigolf: "Minigolf",
  minigolfFacility: "Minigolfanlage",
  roundsIn30: "Runden in 30 Tagen",
  back: "← Meine Plätze",
  tooFew: "Noch zu wenige Runden für eine Auswertung",
  tooFewText: (min) =>
    `Damit niemand auf einzelne Spielgruppen schließen kann, zeigen wir Zahlen erst ab ${min} gemeldeten Runden im gewählten Zeitraum. Ein längerer Zeitraum hilft oft schon. Mehr Runden kommen zusammen, wenn deine Gäste mit GolfTrack zählen – den QR-Code-Aushang für deine Anlage gibt es auf golftrack.app.`,
  nothingShared: "Für deinen Zugang ist noch keine Auswertung freigeschaltet.",
  footnote:
    "Grundlage sind Runden, die Spieler in der GolfTrack-App, im App Clip oder in der Browser-Zählkarte freiwillig und anonym gemeldet haben – keine Namen, keine Uhrzeiten, keine Standorte. Die Zahlen bilden deshalb nur einen Teil aller Runden ab.",
  titleLogin: "Anmelden · GolfTrack für Betreiber",
  titleHome: "Meine Plätze · GolfTrack für Betreiber",
  titleCourse: "Platz-Statistik · GolfTrack für Betreiber",
};

const en: OperatorCopy = {
  report: {
    locale: "en-GB",
    rounds: "Rounds reported",
    duration: "Ø duration (median)",
    durationNote: (n) => `from ${n} rounds with a duration`,
    group: "Ø group size",
    players: (n) => `${n} players`,
    source: "Source",
    sources: { app: "App", clip: "App Clip", web: "Browser" },
    anomaly: (unit, hole, delta, before, recent, minigolf) =>
      `${unit} ${hole} has been ${delta} strokes harder on average over the last 14 days than before (${before} → ${recent}).${minigolf ? " Possibly damaged?" : ""}`,
    perWeek: "Rounds per week",
    busy: "When is it busy?",
    weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
    slots: ["morning", "midday", "afternoon", "evening"],
    difficulty: () => "Difficulty per hole",
    par: "Par",
    hcpReal: "HCP · actual",
    hcpRealHint: "Difficulty rank per scorecard / per rounds played",
    avgStrokes: "Ø strokes",
    overPar: "over par",
    avgPutts: "Ø putts",
    ace: "Hole-in-one",
    samples: "Values",
    length: "Length played",
    tees: "Tees",
    noData: "No data.",
    weekOf: (d) => `Week of ${d}`,
    unitHole: "Hole",
    unitLane: "Hole",
    unitHoles: "holes",
    unitLanes: "holes",
    teeNames: {
      black: "Black",
      white: "White",
      gold: "Gold",
      blue: "Blue",
      yellow: "Yellow",
      red: "Red",
      orange: "Orange",
      green: "Green",
      unbekannt: "unknown",
    },
    period: (d) => (d === 365 ? "1 year" : `${d} days`),
    periodLabel: "Period",
  },
  account: {
    nav: "My account",
    title: "My account",
    intro: "Your details, your password and the names of your courses.",
    profile: "Details",
    name: "Name",
    nameHint: "How you appear in the portal and in our emails.",
    email: "Email (username)",
    emailHint: "You sign in with it. We send a notice to the previous address.",
    currentPassword: "Current password",
    currentPasswordHint: "Only needed when you change the email address.",
    save: "Save",
    saving: "Saving …",
    saved: "Saved.",
    passwordTitle: "Change password",
    newPassword: "New password",
    newPasswordHint: (min) => `At least ${min} characters. Other devices are signed out afterwards.`,
    repeatPassword: "Repeat new password",
    changePassword: "Change password",
    passwordChanged: "Password changed. Other devices have been signed out.",
    errWrongPassword: "The current password is wrong.",
    errEmailTaken: "This email address already belongs to another account.",
    errEmailInvalid: "This email address doesn't look valid.",
    errNameRequired: "Please enter a name.",
    errTooShort: (min) => `The new password needs at least ${min} characters.`,
    errMismatch: "The two new passwords don't match.",
    errSame: "The new password is the same as the current one.",
    errLocked: "Too many failed attempts. Please try again in fifteen minutes.",
    coursesTitle: "Names of my courses",
    coursesIntro:
      "The name appears in the GolfTrack app, the App Clip and on golftrack.app. We briefly review changes before they go live everywhere.",
    courseName: "Name",
    requestChange: "Request change",
    requested: "Thanks – we'll review the change and publish it.",
    pendingSince: (d) => `Awaiting review (since ${d}):`,
    errNameUnchanged: "The name hasn't changed.",
    withdraw: "Withdraw",
  },
  portal: "Operator",
  forOperators: "For course operators",
  signIn: "Sign in",
  signingIn: "Signing in …",
  signInIntro:
    "The anonymous round statistics for your course: when it gets busy, how long rounds take and which holes are hard.",
  email: "Email",
  password: "Password",
  wrongCredentials: "Email or password is wrong – or the account is disabled.",
  locked: "Too many failed attempts. Please try again in fifteen minutes.",
  noAccess: "No access yet? Write to",
  signOut: "Sign out",
  myCourses: "My courses",
  roundStats: "Round statistics",
  myCoursesIntro: (min) =>
    `Rounds reported anonymously by players who agreed to it. Figures appear from ${min} rounds in the selected period.`,
  noCourses: "No course has been assigned to your account yet. Please contact contact@golftrack.app.",
  golfCourse: "Golf course",
  minigolf: "Mini golf",
  minigolfFacility: "Mini golf course",
  roundsIn30: "rounds in 30 days",
  back: "← My courses",
  tooFew: "Not enough rounds for an evaluation yet",
  tooFewText: (min) =>
    `So that nobody can draw conclusions about individual groups, we only show figures from ${min} reported rounds in the selected period. A longer period often helps. More rounds come in when your guests keep score with GolfTrack – the QR code poster for your course is available on golftrack.app.`,
  nothingShared: "No evaluation has been enabled for your account yet.",
  footnote:
    "Based on rounds that players reported voluntarily and anonymously in the GolfTrack app, the App Clip or the browser scorecard – no names, no times of day, no locations. The figures therefore cover only part of all rounds played.",
  titleLogin: "Sign in · GolfTrack for operators",
  titleHome: "My courses · GolfTrack for operators",
  titleCourse: "Course statistics · GolfTrack for operators",
};

const COPY: Record<OperatorLang, OperatorCopy> = { de, en };

export function operatorCopy(lang: OperatorLang): OperatorCopy {
  return COPY[lang];
}

/** Deutsch, wenn der Browser Deutsch zuerst nennt – sonst Englisch. */
export function operatorLangFromAccept(header: string | null | undefined): OperatorLang {
  const first = (header ?? "").split(",")[0]?.trim().toLowerCase() ?? "";
  return first.startsWith("de") ? "de" : "en";
}
