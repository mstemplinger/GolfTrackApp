/**
 * Texte der Werkzeuge im Betreiber-Portal: Reiter je Platz, Gäste-Aushang,
 * Werbung in der Zählkarte und Werbemittel. Eigene Datei neben
 * `operator.ts`, damit die Statistik-Texte übersichtlich bleiben.
 */
import type { PrintItem } from "@/lib/printItems";
import type { OperatorLang } from "./operator";

export type CourseTab = "stats" | "sign" | "ads" | "print";

export interface FormCopy {
  contact: string;
  name: string;
  email: string;
  phone: string;
  phoneHint: string;
  required: string;
  sending: string;
  invalid: string;
  failed: string;
  nameError: string;
  emailError: string;
}

export interface SignCopy {
  title: string;
  intro: string;
  languages: string;
  languagesHint: string;
  download: string;
  preparing: string;
  codeTitle: string;
  codeLeadsTo: string;
  tryIt: string;
  codeSvg: string;
  codePng: string;
  codeHint: string;
  notApproved: string;
  tipsTitle: string;
  tips: string[];
  langNames: Record<string, string>;
}

export interface AdsCopy {
  title: string;
  intro: string;
  mine: string;
  status: { draft: string; active: string; scheduled: (date: string) => string; ended: string; paused: string };
  onCourse: (name: string) => string;
  around: (km: number, name: string) => string;
  views: string;
  taps: string;
  last30: string;
  newTitle: string;
  newIntro: string;
  where: string;
  targetCourse: (name: string) => string;
  targetCourseHint: string;
  targetRadius: (name: string) => string;
  targetRadiusHint: string;
  noCoordinates: string;
  radiusLabel: (km: number) => string;
  radiusAria: string;
  reach: (n: number, km: number) => string;
  reachNone: (km: number) => string;
  andMore: (n: number) => string;
  split: (golf: number, minigolf: number) => string;
  ownCourse: string;
  duration: string;
  months: (n: number) => string;
  content: string;
  headline: string;
  subline: string;
  chars: (n: number, max: number) => string;
  link: string;
  linkHint: string;
  image: string;
  imageHint: string;
  advertiser: string;
  advertiserHint: string;
  note: string;
  noteHint: string;
  price: string;
  perMonth: string;
  total: (months: string, total: string) => string;
  discount: (percent: number) => string;
  operatorDiscount: (percent: number) => string;
  minimum: string;
  priceNote: string;
  terms: string;
  termsLink: string;
  submit: string;
  done: string;
  doneText: string;
  another: string;
  preview: string;
  previewHint: string;
  adLabel: string;
  errTitle: string;
  errUrl: string;
  errNoCourses: string;
  errTooMany: string;
  errNoLocation: string;
  errNotApproved: string;
}

export interface PrintCopy {
  title: string;
  introGolf: string;
  introMinigolf: string;
  columns: string;
  columnsText: string;
  fenceTee: string;
  fenceRange: string;
  fenceText: string;
  what: string;
  pickOne: string;
  items: Record<PrintItem, string>;
  message: string;
  messageHint: string;
  nonBinding: string;
  submit: string;
  done: string;
  doneText: string;
  another: string;
  writeDirectly: (email: string) => string;
}

export interface OperatorToolsCopy {
  tabs: Record<CourseTab, string>;
  tabsLabel: string;
  form: FormCopy;
  sign: SignCopy;
  ads: AdsCopy;
  print: PrintCopy;
  titleSign: string;
  titleAds: string;
  titlePrint: string;
  toSign: string;
}

const de: OperatorToolsCopy = {
  tabs: { stats: "Statistik", sign: "Aushang", ads: "Werbung", print: "Werbemittel" },
  tabsLabel: "Bereiche dieses Platzes",
  form: {
    contact: "Kontakt",
    name: "Name",
    email: "E-Mail",
    phone: "Telefon",
    phoneHint: "Freiwillig – manches klärt ein Anruf schneller.",
    required: "Pflichtfeld",
    sending: "Wird geschickt …",
    invalid: "Bitte die markierten Felder prüfen.",
    failed: "Das hat nicht geklappt. Bitte später noch einmal versuchen.",
    nameError: "Bitte einen Namen angeben.",
    emailError: "Bitte eine gültige Mailadresse angeben.",
  },
  sign: {
    title: "Gäste-Aushang",
    intro:
      "Ein Blatt für den ersten Abschlag, die Kasse oder den Eingang. Gäste scannen den Code und zählen ihre Runde – in der App, im App Clip ohne Installation oder direkt im Browser. Jede gemeldete Runde fließt in deine Statistik.",
    languages: "Sprachen auf dem Aushang",
    languagesHint:
      "Eine Sprache: A4 hoch. Zwei oder drei: A4 quer nebeneinander. Mehr: auf mehrere Blätter verteilt.",
    download: "PDF herunterladen",
    preparing: "PDF wird erstellt …",
    codeTitle: "Dein QR-Code",
    codeLeadsTo: "Führt zu",
    tryIt: "Ausprobieren",
    codeSvg: "QR-Code als SVG",
    codePng: "QR-Code als PNG",
    codeHint: "Für eigene Schilder, Flyer oder deine Website. Der Code bleibt immer gleich.",
    notApproved:
      "Dein Platz ist noch nicht freigegeben. Sobald er im Verzeichnis steht, gibt es hier Aushang und QR-Code.",
    tipsTitle: "So kommen mehr Runden zusammen",
    tips: [
      "Am ersten Abschlag bzw. an Bahn 1 aufhängen – dort, wo die Runde beginnt.",
      "Einen zweiten an Kasse oder Schlägerausgabe: Dort haben Gäste das Handy ohnehin in der Hand.",
      "Laminiert oder in einer Klarsichthülle hält er Regen und Sonne aus.",
    ],
    langNames: {
      de: "Deutsch",
      en: "Englisch",
      it: "Italienisch",
      fr: "Französisch",
      es: "Spanisch",
      pl: "Polnisch",
      cz: "Tschechisch",
    },
  },
  ads: {
    title: "Werbung in der Zählkarte",
    intro:
      "Während der ganzen Runde steht unter den Spielernamen eine Anzeige: Bild, Überschrift, eine Zeile Text und ein Ziel beim Antippen. Gut für Restaurant, Pro-Shop, Turniere oder Kurse.",
    mine: "Deine Anzeigen",
    status: {
      draft: "In Prüfung",
      active: "Läuft",
      scheduled: (d) => `Ab ${d}`,
      ended: "Abgelaufen",
      paused: "Nicht geschaltet",
    },
    onCourse: (name) => `Nur auf ${name}`,
    around: (km, name) => `Umkreis ${km} km um ${name}`,
    views: "Einblendungen",
    taps: "Antipper",
    last30: "letzte 30 Tage",
    newTitle: "Neue Anzeige anfragen",
    newIntro:
      "Als Platzbetreiber zahlst du nur die Hälfte. Unverbindlich – geschaltet wird erst, wenn wir Text, Laufzeit und Preis per Mail bestätigt haben.",
    where: "Wo soll sie laufen?",
    targetCourse: (name) => `Nur auf ${name}`,
    targetCourseHint: "Deine Gäste sehen sie während ihrer Runde.",
    targetRadius: (name) => `Im Umkreis um ${name}`,
    targetRadiusHint: "Auch Spieler auf den Plätzen ringsum sehen sie – damit sie mal bei dir vorbeikommen.",
    noCoordinates: "Für deinen Platz ist keine Lage hinterlegt – der Umkreis geht deshalb nicht.",
    radiusLabel: (km) => `Umkreis: ${km} km`,
    radiusAria: "Umkreis in Kilometern",
    reach: (n, km) => `${n} ${n === 1 ? "Platz" : "Plätze"} im Umkreis von ${km} km`,
    reachNone: (km) => `In ${km} km liegt kein eingetragener Platz – größeren Umkreis wählen.`,
    andMore: (n) => `und ${n} weitere`,
    split: (g, m) => `${g} Golf, ${m} Minigolf`,
    ownCourse: "dein Platz",
    duration: "Laufzeit",
    months: (n) => (n === 1 ? "1 Monat" : `${n} Monate`),
    content: "Was in der Anzeige steht",
    headline: "Überschrift",
    subline: "Zeile darunter",
    chars: (n, max) => `${n}/${max} Zeichen`,
    link: "Ziel beim Antippen",
    linkHint: "Website, Speisekarte oder Turnieranmeldung. Leer lassen, wenn es nichts zu öffnen gibt.",
    image: "Bild",
    imageHint: "Adresse eines quadratischen Bildes. Hast du keines, melden wir uns.",
    advertiser: "Wer wirbt",
    advertiserHint: "Der Name, der auf der Rechnung steht.",
    note: "Anmerkung",
    noteHint: "Wunschzeitraum, Fragen, alles was sonst noch dazugehört.",
    price: "Richtpreis",
    perMonth: "/ Monat",
    total: (months, total) => `${months}: ${total}`,
    discount: (p) => `−${p} % Laufzeitrabatt`,
    operatorDiscount: (p) => `−${p} % Betreiberrabatt`,
    minimum: "Mindestpreis",
    priceNote: "Netto, zzgl. MwSt. Verbindlich wird der Preis mit unserer Antwort.",
    terms: "Für eine Buchung gelten die",
    termsLink: "Bedingungen für Werbekunden",
    submit: "Anfrage schicken",
    done: "Anfrage ist da",
    doneText: "Wir melden uns per Mail – meist innerhalb von zwei Tagen. Bis dahin steht sie unter „Deine Anzeigen“ als „In Prüfung“.",
    another: "Weitere Anzeige anfragen",
    preview: "So sieht es aus",
    previewHint:
      "So steht die Anzeige während der Runde unter den Spielernamen. Wer GolfTrack Pro hat, sieht die Fläche nicht.",
    adLabel: "Anzeige",
    errTitle: "Mindestens 2 Zeichen.",
    errUrl: "Bitte eine vollständige Adresse mit https:// angeben.",
    errNoCourses: "In diesem Umkreis liegt noch kein Platz – bitte einen größeren wählen.",
    errTooMany: "Es liegen schon mehrere offene Anfragen von dir vor. Wir melden uns – danach geht es weiter.",
    errNoLocation: "Für deinen Platz ist keine Lage hinterlegt – bitte „Nur auf diesem Platz“ wählen.",
    errNotApproved: "Dein Platz ist noch nicht freigegeben – Werbung gibt es erst danach.",
  },
  print: {
    title: "Werbemittel für deinen Platz",
    introGolf:
      "Werbesäulen fürs Clubhaus, eine Plane für den Zaun am ersten Abschlag, Plakate und Flyer – alle mit dem QR-Code, der deine Spieler direkt zur Scorekarte bringt. Wir melden uns mit Vorschlag, Lieferzeit und Konditionen.",
    introMinigolf:
      "Eine Werbesäule für den Eingang, Plakate und Flyer für die Kasse – alle mit dem QR-Code, der deine Gäste direkt zur Zählkarte bringt. Wir melden uns mit Vorschlag, Lieferzeit und Konditionen.",
    columns: "Werbesäulen",
    columnsText: "Stabile Wellpappe, vorne und hinten bedruckt. Stehen ohne Sockel und ohne Strom.",
    fenceTee: "Bauzaunplane Abschlag",
    fenceRange: "Bauzaunplane Driving Range",
    fenceText: "340 × 173 cm mit Ösen – passt an jeden Standard-Bauzaun.",
    what: "Was darf es sein?",
    pickOne: "Bitte mindestens ein Werbemittel wählen.",
    items: {
      "saeule-golf": "Werbesäule Golf · 60 × 200 cm",
      "saeule-minigolf": "Werbesäule Minigolf · 60 × 180 cm",
      "saeule-lernen": "Werbesäule Golf lernen · 50 × 155 cm",
      "plane-abschlag": "Bauzaunplane Abschlag · 340 × 173 cm",
      "plane-range": "Bauzaunplane Driving Range · 340 × 173 cm",
      plakate: "Plakate und Flyer",
    },
    message: "Nachricht",
    messageHint: "Wo soll es stehen oder hängen? Stückzahl, Wunschtermin, Fragen.",
    nonBinding: "Unverbindlich. Die Anfrage geht per Mail an uns, wir antworten an deine Adresse.",
    submit: "Werbemittel anfragen",
    done: "Anfrage ist da",
    doneText: "Wir melden uns per Mail – meist innerhalb von zwei Tagen – mit einem Vorschlag für deinen Platz.",
    another: "Noch etwas anfragen",
    writeDirectly: (email) => `Bitte schreib uns direkt an ${email}.`,
  },
  titleSign: "Aushang · GolfTrack für Betreiber",
  titleAds: "Werbung · GolfTrack für Betreiber",
  titlePrint: "Werbemittel · GolfTrack für Betreiber",
  toSign: "Aushang herunterladen",
};

const en: OperatorToolsCopy = {
  tabs: { stats: "Statistics", sign: "Sign", ads: "Advertising", print: "Print" },
  tabsLabel: "Sections for this course",
  form: {
    contact: "Contact",
    name: "Name",
    email: "Email",
    phone: "Phone",
    phoneHint: "Optional – some things are quicker on the phone.",
    required: "Required",
    sending: "Sending …",
    invalid: "Please check the highlighted fields.",
    failed: "That didn't work. Please try again later.",
    nameError: "Please enter a name.",
    emailError: "Please enter a valid email address.",
  },
  sign: {
    title: "Guest sign",
    intro:
      "A sheet for the first tee, the till or the entrance. Guests scan the code and keep score – in the app, in the App Clip without installing anything, or right in the browser. Every reported round feeds your statistics.",
    languages: "Languages on the sign",
    languagesHint: "One language: A4 portrait. Two or three: A4 landscape, side by side. More: spread over several sheets.",
    download: "Download PDF",
    preparing: "Creating PDF …",
    codeTitle: "Your QR code",
    codeLeadsTo: "Leads to",
    tryIt: "Try it",
    codeSvg: "QR code as SVG",
    codePng: "QR code as PNG",
    codeHint: "For your own signs, flyers or website. The code never changes.",
    notApproved: "Your course hasn't been approved yet. Once it's in the directory, the sign and QR code appear here.",
    tipsTitle: "How to get more rounds",
    tips: [
      "Put it up at the first tee or hole 1 – where the round starts.",
      "Add a second one at the till or club hire: guests have their phone in hand there anyway.",
      "Laminated or in a plastic sleeve it survives rain and sun.",
    ],
    langNames: {
      de: "German",
      en: "English",
      it: "Italian",
      fr: "French",
      es: "Spanish",
      pl: "Polish",
      cz: "Czech",
    },
  },
  ads: {
    title: "Advertising on the scorecard",
    intro:
      "Throughout the round an ad sits below the player names: image, headline, one line of text and a link when tapped. Good for your restaurant, pro shop, tournaments or lessons.",
    mine: "Your ads",
    status: {
      draft: "Under review",
      active: "Running",
      scheduled: (d) => `From ${d}`,
      ended: "Ended",
      paused: "Not running",
    },
    onCourse: (name) => `Only at ${name}`,
    around: (km, name) => `${km} km around ${name}`,
    views: "Impressions",
    taps: "Taps",
    last30: "last 30 days",
    newTitle: "Request a new ad",
    newIntro:
      "As a course operator you pay only half. Non-binding – it only goes live once we've confirmed text, duration and price by email.",
    where: "Where should it run?",
    targetCourse: (name) => `Only at ${name}`,
    targetCourseHint: "Your guests see it during their round.",
    targetRadius: (name) => `Around ${name}`,
    targetRadiusHint: "Players at nearby courses see it too – so they drop by at yours.",
    noCoordinates: "No location is stored for your course, so the radius option isn't available.",
    radiusLabel: (km) => `Radius: ${km} km`,
    radiusAria: "Radius in kilometres",
    reach: (n, km) => `${n} ${n === 1 ? "course" : "courses"} within ${km} km`,
    reachNone: (km) => `No listed course within ${km} km – choose a larger radius.`,
    andMore: (n) => `and ${n} more`,
    split: (g, m) => `${g} golf, ${m} mini golf`,
    ownCourse: "your course",
    duration: "Duration",
    months: (n) => (n === 1 ? "1 month" : `${n} months`),
    content: "What the ad says",
    headline: "Headline",
    subline: "Line below",
    chars: (n, max) => `${n}/${max} characters`,
    link: "Link when tapped",
    linkHint: "Website, menu or tournament sign-up. Leave empty if there's nothing to open.",
    image: "Image",
    imageHint: "Address of a square image. If you don't have one, we'll get in touch.",
    advertiser: "Advertiser",
    advertiserHint: "The name that goes on the invoice.",
    note: "Note",
    noteHint: "Preferred dates, questions, anything else.",
    price: "Guide price",
    perMonth: "/ month",
    total: (months, total) => `${months}: ${total}`,
    discount: (p) => `−${p} % duration discount`,
    operatorDiscount: (p) => `−${p} % operator discount`,
    minimum: "Minimum price",
    priceNote: "Net, plus VAT. The price becomes binding with our reply.",
    terms: "Bookings are subject to the",
    termsLink: "terms for advertisers (German)",
    submit: "Send request",
    done: "Request received",
    doneText: "We'll reply by email – usually within two days. Until then it's listed under “Your ads” as “Under review”.",
    another: "Request another ad",
    preview: "Preview",
    previewHint: "This is how the ad appears below the player names during a round. GolfTrack Pro subscribers don't see the slot.",
    adLabel: "Ad",
    errTitle: "At least 2 characters.",
    errUrl: "Please enter a full address starting with https://.",
    errNoCourses: "There's no course within this radius yet – please choose a larger one.",
    errTooMany: "You already have several open requests. We'll be in touch – then you can continue.",
    errNoLocation: "No location is stored for your course – please choose “Only at this course”.",
    errNotApproved: "Your course hasn't been approved yet – ads are only possible afterwards.",
  },
  print: {
    title: "Print materials for your course",
    introGolf:
      "Display columns for the clubhouse, a banner for the fence at the first tee, posters and flyers – all with the QR code that takes your players straight to the scorecard. We'll reply with a proposal, delivery time and terms.",
    introMinigolf:
      "A display column for the entrance, posters and flyers for the till – all with the QR code that takes your guests straight to the scorecard. We'll reply with a proposal, delivery time and terms.",
    columns: "Display columns",
    columnsText: "Sturdy corrugated board, printed front and back. Free-standing, no base, no power.",
    fenceTee: "Fence banner, first tee",
    fenceRange: "Fence banner, driving range",
    fenceText: "340 × 173 cm with eyelets – fits any standard construction fence.",
    what: "What would you like?",
    pickOne: "Please choose at least one item.",
    items: {
      "saeule-golf": "Display column Golf · 60 × 200 cm",
      "saeule-minigolf": "Display column Mini golf · 60 × 180 cm",
      "saeule-lernen": "Display column Learn golf · 50 × 155 cm",
      "plane-abschlag": "Fence banner, first tee · 340 × 173 cm",
      "plane-range": "Fence banner, driving range · 340 × 173 cm",
      plakate: "Posters and flyers",
    },
    message: "Message",
    messageHint: "Where should it stand or hang? Quantity, preferred date, questions.",
    nonBinding: "Non-binding. The request reaches us by email and we reply to your address.",
    submit: "Request print materials",
    done: "Request received",
    doneText: "We'll reply by email – usually within two days – with a proposal for your course.",
    another: "Request something else",
    writeDirectly: (email) => `Please write to us directly at ${email}.`,
  },
  titleSign: "Sign · GolfTrack for operators",
  titleAds: "Advertising · GolfTrack for operators",
  titlePrint: "Print materials · GolfTrack for operators",
  toSign: "Download the sign",
};

const COPY: Record<OperatorLang, OperatorToolsCopy> = { de, en };

export function operatorToolsCopy(lang: OperatorLang): OperatorToolsCopy {
  return COPY[lang];
}
