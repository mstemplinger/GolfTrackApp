import { Footer, Header, PageHeader } from "@/components/Chrome";
import { t } from "@/i18n/content";
import { isPlaceholder, site } from "@/lib/site";
import type { Lang } from "@/i18n/routes";

function Placeholder({ value }: { value: string }) {
  return isPlaceholder(value) ? (
    <span className="rounded-sm border border-[#a6321f]/50 bg-[#a6321f]/10 px-1.5 py-0.5 font-mono text-xs text-[#e07a63]">
      {value}
    </span>
  ) : (
    <>{value}</>
  );
}

export function Imprint({ lang }: { lang: Lang }) {
  const copy = t(lang);
  const de = lang === "de";
  return (
    <LegalShell lang={lang} title={copy.legal.imprintTitle} route="imprint">
      <h2>{de ? "Angaben gemäß § 5 DDG" : "Provider information"}</h2>
      <p>
        {site.operator}
        <br />
        <Placeholder value={site.street} />
        <br />
        <Placeholder value={site.city} />
        <br />
        {site.country}
      </p>

      <h2>{de ? "Kontakt" : "Contact"}</h2>
      <p>
        {de ? "E-Mail" : "Email"}: <Placeholder value={site.email} />
        {site.phone ? (
          <>
            <br />
            {de ? "Telefon" : "Phone"}: {site.phone}
          </>
        ) : null}
      </p>

      {site.vatId ? (
        <>
          <h2>{de ? "Umsatzsteuer-Identifikationsnummer" : "VAT ID"}</h2>
          <p>{site.vatId}</p>
        </>
      ) : null}

      <h2>{de ? "Verantwortlich für den Inhalt" : "Responsible for content"}</h2>
      <p>
        {site.operator}, {de ? "Anschrift wie oben" : "address as above"}
      </p>

      <h2>{de ? "Streitbeilegung" : "Dispute resolution"}</h2>
      <p>
        {de
          ? "Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung bereit: "
          : "The European Commission provides a platform for online dispute resolution: "}
        <a href="https://ec.europa.eu/consumers/odr/" target="_blank" rel="noreferrer">
          ec.europa.eu/consumers/odr
        </a>
        {de
          ? ". Ich bin nicht verpflichtet und nicht bereit, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen."
          : ". I am neither obliged nor willing to take part in dispute resolution proceedings before a consumer arbitration board."}
      </p>

      <h2>{de ? "App Store" : "App Store"}</h2>
      <p>
        {de
          ? "GolfTrack wird über den App Store von Apple vertrieben. Apple Inc. ist nicht Betreiber dieser Website."
          : "GolfTrack is distributed through Apple's App Store. Apple Inc. does not operate this website."}
      </p>
    </LegalShell>
  );
}

export function Privacy({ lang }: { lang: Lang }) {
  const copy = t(lang);
  const de = lang === "de";
  return (
    <LegalShell lang={lang} title={copy.legal.privacyTitle} route="privacy">
      <h2>{de ? "Verantwortlicher" : "Controller"}</h2>
      <p>
        {site.operator}, <Placeholder value={site.street} />, <Placeholder value={site.city} />,{" "}
        {de ? "E-Mail" : "email"}: <Placeholder value={site.email} />
      </p>

      <h2>{de ? "Diese Website" : "This website"}</h2>
      <p>
        {de
          ? "Die Website läuft auf einem von mir angemieteten Server. Beim Abruf werden technisch notwendige Serverprotokolle erzeugt (IP-Adresse, Zeitpunkt, abgerufene Seite, Browserkennung). Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO – das berechtigte Interesse am sicheren und störungsfreien Betrieb. Die Protokolle werden nach kurzer Zeit gelöscht."
          : "This website runs on a server I rent. Serving a page creates technically necessary server logs (IP address, time, page requested, browser identification). The legal basis is Art. 6(1)(f) GDPR – the legitimate interest in secure and reliable operation. Logs are deleted after a short period."}
      </p>
      <p>
        {de
          ? "Es werden keine Cookies zu Analyse- oder Werbezwecken gesetzt und keine externen Tracking-Dienste eingebunden. Schriftarten werden mit der Seite ausgeliefert und nicht von fremden Servern nachgeladen."
          : "No cookies are set for analytics or advertising and no external tracking services are embedded. Fonts are served with the page and not loaded from third-party servers."}
      </p>

      <h2>{de ? "Anlage eintragen" : "Listing a venue"}</h2>
      <p>
        {de
          ? "Wenn du eine Anlage einträgst, werden die Angaben zur Anlage sowie dein Name, deine E-Mail-Adresse und deine Funktion gespeichert. Die Angaben zur Anlage werden nach der Freigabe in der App und auf dieser Website veröffentlicht; dein Name und deine E-Mail-Adresse werden nicht veröffentlicht, sondern nur für Rückfragen zur Freigabe verwendet. Rechtsgrundlage ist Art. 6 Abs. 1 lit. a und lit. b DSGVO."
          : "When you list a venue, the venue details plus your name, email address and role are stored. After approval the venue details are published in the app and on this website; your name and email address are not published and are only used for questions about the listing. Legal basis: Art. 6(1)(a) and (b) GDPR."}
      </p>
      <p>
        {de
          ? "Zum Schutz vor automatisierten Einsendungen wird ein aus deiner IP-Adresse abgeleiteter Prüfwert gespeichert. Die IP-Adresse selbst wird nicht gespeichert; der Prüfwert wird nach 24 Stunden gelöscht."
          : "To guard against automated submissions, a value derived from your IP address is stored. The IP address itself is not stored; the derived value is deleted after 24 hours."}
      </p>
      <p>
        {de
          ? "Zum Setzen von Abschlägen und Grüns lässt sich im Formular eine Satellitenkarte einblenden. Die Luftbilder kommen von Esri (Environmental Systems Research Institute, Inc., 380 New York Street, Redlands, CA 92373, USA). Sie werden erst nach einem Klick auf „Satellitenkarte laden“ abgerufen; erst dann erhält Esri deine IP-Adresse und die üblichen Browserangaben, was eine Übermittlung in die USA bedeutet. Rechtsgrundlage ist deine Einwilligung durch den Klick (Art. 6 Abs. 1 lit. a DSGVO). Ohne Karte funktioniert das Formular genauso. Näheres: esri.com/de-de/privacy."
          : "To set tees and greens you can show a satellite map in the form. The aerial images come from Esri (Environmental Systems Research Institute, Inc., 380 New York Street, Redlands, CA 92373, USA). They are only loaded after you click “Load satellite map”; only then does Esri receive your IP address and the usual browser information, which means a transfer to the USA. The legal basis is your consent given by that click (Art. 6(1)(a) GDPR). The form works just as well without the map. Details: esri.com/privacy."}
      </p>

      <h2>{de ? "Erinnerung zur Android-App" : "Android app reminder"}</h2>
      <p>
        {de
          ? "Wer sich erinnern lässt, wann GolfTrack im Google Play Store erscheint, gibt seine E-Mail-Adresse an. Wir schicken daraufhin einen Bestätigungscode; erst nach dessen Eingabe gilt die Adresse als eingetragen (Double-Opt-in). Unbestätigte Adressen werden nach 24 Stunden gelöscht. Bestätigte Adressen erhalten eine Bestätigung der Anmeldung und genau eine weitere Nachricht, sobald die App im Play Store steht, und werden danach gelöscht. Jede Mail enthält einen Abmeldelink, der die Adresse sofort löscht. Versendet wird über unser Postfach bei der IONOS SE (Elgendorfer Str. 57, 56410 Montabaur). Rechtsgrundlage ist deine Einwilligung (Art. 6 Abs. 1 lit. a DSGVO)."
          : "If you ask to be reminded when GolfTrack appears on Google Play, you enter your email address. We then send a confirmation code; the address only counts as registered once you enter it (double opt-in). Unconfirmed addresses are deleted after 24 hours. Confirmed addresses receive a confirmation of the sign-up and exactly one further message once the app is on Google Play, and are deleted afterwards. Every email contains an unsubscribe link that deletes the address immediately. Emails are sent via our mailbox at IONOS SE (Elgendorfer Str. 57, 56410 Montabaur, Germany). The legal basis is your consent (Art. 6(1)(a) GDPR)."}
      </p>

      <h2>{de ? "Werbeplatz anfragen und Karte" : "Ad requests and map"}</h2>
      <p>
        {de
          ? "Wer auf /werbung einen Werbeplatz anfragt, übermittelt Standort, Umkreis, Anzeigentext sowie Name, E-Mail-Adresse und auf Wunsch Telefonnummer. Die Angaben dienen nur der Bearbeitung der Anfrage. Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO."
          : "Anyone requesting an ad slot on /werbung submits a location, radius, ad text as well as name, email address and optionally a phone number. The data is only used to handle the request. Legal basis: Art. 6(1)(b) GDPR."}
      </p>
      <p>
        {de
          ? "Zum Setzen des Standorts lässt sich dort eine Karte einblenden. Das Kartenbild kommt von der OpenStreetMap Foundation (St John’s Innovation Centre, Cowley Road, Cambridge, CB4 0WS, Großbritannien), das wahlweise einblendbare Luftbild von Esri (380 New York Street, Redlands, CA 92373, USA). Die Karte wird erst nach einem Klick auf „Karte laden“ abgerufen; erst dann erhalten diese Dienste deine IP-Adresse und die üblichen Browserangaben, was eine Übermittlung nach Großbritannien bzw. in die USA bedeuten kann. Rechtsgrundlage ist deine Einwilligung durch den Klick (Art. 6 Abs. 1 lit. a DSGVO). Ohne Karte funktioniert das Formular mit den Koordinatenfeldern genauso. Näheres: osmfoundation.org/wiki/Privacy_Policy und esri.com/de-de/privacy."
          : "To set the location you can show a map there. The map tiles come from the OpenStreetMap Foundation (St John’s Innovation Centre, Cowley Road, Cambridge, CB4 0WS, United Kingdom), the optional aerial view from Esri (380 New York Street, Redlands, CA 92373, USA). The map is only loaded after you click “Karte laden” (load map); only then do these services receive your IP address and the usual browser information, which may involve a transfer to the UK or the USA. The legal basis is your consent given by that click (Art. 6(1)(a) GDPR). Without the map the form works just as well using the coordinate fields. Details: osmfoundation.org/wiki/Privacy_Policy and esri.com/privacy."}
      </p>

      <h2>{de ? "Die App" : "The app"}</h2>
      <p>
        {de
          ? "Runden, Scores und – falls eingeschaltet – Positionsdaten bleiben auf deinem Gerät und in deiner privaten iCloud, sofern du iCloud nutzt. Sie werden nicht an mich übertragen. Das Positions-Tracking ist standardmäßig ausgeschaltet, läuft nur während einer Runde und lässt sich jederzeit im Profil löschen."
          : "Rounds, scores and – if enabled – position data stay on your device and in your private iCloud if you use iCloud. They are not transmitted to me. Position tracking is off by default, runs only during a round and can be deleted at any time in the profile."}
      </p>
      <p>
        {de
          ? "Für Wetterdaten fragt die App einen Wetterdienst ab; dabei wird der ungefähre Standort des Platzes übermittelt. Für den Sprach-Caddy wird der eingegebene Text an ElevenLabs übertragen, um daraus Sprache zu erzeugen. Käufe und Abos wickelt Apple über den App Store ab; ich erhalte dabei keine Zahlungsdaten."
          : "For weather data the app queries a weather service, transmitting the approximate location of the course. For the voice caddy the given text is sent to ElevenLabs to be turned into speech. Purchases and subscriptions are handled by Apple through the App Store; I receive no payment data."}
      </p>

      <p>
        {de
          ? "Das Verzeichnis der Anlagen und die Anzeigen der Anlagen lädt die App von dieser Website; dabei wird nichts über deine Runden übertragen. Damit eine Anlage weiß, wie oft ihre Anzeige gesehen und angetippt wurde, meldet die App gebündelt die Kennung der Anzeige, die Art des Ereignisses und die Anzahl zurück – ohne Gerätekennung und ohne Profilbildung."
          : "The app loads the venue directory and the venues' ads from this website; nothing about your rounds is transmitted. So that a venue knows how often its ad was seen and tapped, the app reports back the ad's identifier, the type of event and a count, in batches – with no device identifier and no profiling."}
      </p>

      <h2>{de ? "Deine Rechte" : "Your rights"}</h2>
      <p>
        {de
          ? "Du hast das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung der Verarbeitung, Datenübertragbarkeit und Widerspruch sowie das Recht, eine erteilte Einwilligung jederzeit zu widerrufen. Eine formlose E-Mail genügt. Außerdem kannst du dich bei einer Datenschutz-Aufsichtsbehörde beschweren."
          : "You have the right to access, rectification, erasure, restriction of processing, data portability and objection, and you may withdraw consent at any time. An informal email is enough. You may also lodge a complaint with a data protection authority."}
      </p>
    </LegalShell>
  );
}

function LegalShell({
  lang,
  title,
  route,
  children,
}: {
  lang: Lang;
  title: string;
  route: "imprint" | "privacy";
  children: React.ReactNode;
}) {
  const copy = t(lang);
  return (
    <>
      <Header lang={lang} />
      <PageHeader index={route === "imprint" ? "14 — Recht" : "15 — Recht"} title={title} />
      <main className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        <p className="font-mono text-xs text-cream/60">
          {copy.legal.lastUpdated}: {new Date(site.legalUpdated).toLocaleDateString(copy.meta.locale)}
        </p>
        <div className="legal-prose mt-8 max-w-3xl">{children}</div>
      </main>
      <Footer lang={lang} />
    </>
  );
}
