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
          ? "Ich bin nicht verpflichtet und nicht bereit, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen."
          : "I am neither obliged nor willing to take part in dispute resolution proceedings before a consumer arbitration board."}
      </p>

      <h2>{de ? "Datenquellen" : "Data sources"}</h2>
      <p>
        {de
          ? "Platzwertungen (Course Rating, Slope, Par) deutscher Golfplätze stammen mit freundlicher Genehmigung von "
          : "Course ratings (course rating, slope, par) of German golf courses are used with kind permission of "}
        <a href="https://handicap.report" target="_blank" rel="noreferrer">
          handicap.report
        </a>
        {de ? ". Platzkoordinaten: © " : ". Course coordinates: © "}
        <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noreferrer">
          {de ? "OpenStreetMap-Mitwirkende" : "OpenStreetMap contributors"}
        </a>
        {de
          ? ", verfügbar unter der Open Database License (ODbL)."
          : ", available under the Open Database License (ODbL)."}
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
          ? "Die Website und die Schnittstelle für die App laufen auf einem Server der Hetzner Online GmbH (Industriestr. 25, 91710 Gunzenhausen) in einem Rechenzentrum in Deutschland. Hetzner verarbeitet die Daten in meinem Auftrag (Art. 28 DSGVO). Beim Abruf werden technisch notwendige Serverprotokolle erzeugt (IP-Adresse, Zeitpunkt, abgerufene Seite, Browserkennung). Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO – das berechtigte Interesse am sicheren und störungsfreien Betrieb. Die Protokolle werden nach 14 Tagen automatisch gelöscht."
          : "The website and the app's interface run on a server of Hetzner Online GmbH (Industriestr. 25, 91710 Gunzenhausen, Germany) in a data centre in Germany. Hetzner processes the data on my behalf (Art. 28 GDPR). Serving a page creates technically necessary server logs (IP address, time, page requested, browser identification). The legal basis is Art. 6(1)(f) GDPR – the legitimate interest in secure and reliable operation. Logs are deleted automatically after 14 days."}
      </p>
      <p>
        {de
          ? "Es werden keine Cookies zu Analyse- oder Werbezwecken gesetzt und keine externen Tracking-Dienste eingebunden. Schriftarten werden mit der Seite ausgeliefert und nicht von fremden Servern nachgeladen."
          : "No cookies are set for analytics or advertising and no external tracking services are embedded. Fonts are served with the page and not loaded from third-party servers."}
      </p>
      <p>
        {de
          ? "Einige Funktionen legen Angaben im Speicher deines Browsers (localStorage) ab, damit sie funktionieren: die Scorekarte im Browser (Aufruf über den QR-Code am Abschlag) den Spielstand der laufenden Runde, damit eine unterbrochene Runde nicht verloren geht, und die Android-Seite deine dort eingetragene E-Mail-Adresse bzw. dass du den Hinweis auf die Android-Mails schon gesehen hast, damit er nicht bei jedem Besuch erscheint. Diese Angaben bleiben auf deinem Gerät und werden nicht an mich übertragen; du kannst sie jederzeit in den Browsereinstellungen löschen. Für das Adminpanel wird nach der Anmeldung ein Sitzungscookie gesetzt. Beides ist für den jeweils gewünschten Dienst unbedingt erforderlich (§ 25 Abs. 2 Nr. 2 TDDDG)."
          : "Some features store data in your browser's storage (localStorage) so that they work: the browser scorecard (opened via the QR code at the tee) keeps the score of the current round so that an interrupted round is not lost, and the Android page remembers the email address you entered there, or that you have already seen the note about the Android emails, so it does not appear on every visit. This data stays on your device and is not transmitted to me; you can delete it at any time in your browser settings. The admin panel sets a session cookie after sign-in. Both are strictly necessary for the service you requested (Section 25(2) no. 2 TDDDG)."}
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

      <h2>{de ? "Fehler zu einem Platz melden" : "Reporting an error for a course"}</h2>
      <p>
        {de
          ? "Über „Fehler melden“ auf der Platzliste und den Platzseiten übermittelst du den betroffenen Platz, die Art des Fehlers, deine Beschreibung und – freiwillig – deinen Namen, deine E-Mail-Adresse und deine Rolle (zum Beispiel Betreiber oder Spieler). Die Meldung wird gespeichert und mir per Mail zugeschickt; Name und E-Mail-Adresse nutze ich nur für Rückfragen. Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO – das berechtigte Interesse an richtigen Platzdaten – und, soweit du Kontaktdaten angibst, deine Einwilligung (Art. 6 Abs. 1 lit. a DSGVO). Die Meldung wird gelöscht, sobald sie erledigt ist, spätestens nach zwölf Monaten."
          : "Using “Report an error” on the course list and course pages you submit the course concerned, the type of error, your description and – optionally – your name, email address and role (for example operator or player). The report is stored and emailed to me; I only use your name and email address for follow-up questions. The legal basis is Art. 6(1)(f) GDPR – the legitimate interest in correct course data – and, where you provide contact details, your consent (Art. 6(1)(a) GDPR). The report is deleted once it has been dealt with, at the latest after twelve months."}
      </p>

      <h2>{de ? "Werbemittel für Golfplätze anfragen" : "Requesting print materials for golf courses"}</h2>
      <p>
        {de
          ? "Wer auf /werbung/golfplatz Werbesäulen, Bauzaunplanen oder Plakate anfragt, übermittelt den Namen und Ort des Platzes, einen Ansprechpartner, die E-Mail-Adresse, auf Wunsch eine Telefonnummer, die gewünschten Werbemittel und eine Nachricht. Die Anfrage wird mir per Mail zugeschickt und nur zu ihrer Bearbeitung verwendet. Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO. Kommt kein Auftrag zustande, lösche ich die Anfrage spätestens sechs Monate nach dem letzten Kontakt."
          : "Anyone requesting advertising columns, fence banners or posters on /werbung/golfplatz submits the name and location of the course, a contact person, an email address, optionally a phone number, the requested materials and a message. The request is emailed to me and only used to handle it. Legal basis: Art. 6(1)(b) GDPR. If no order results, I delete the request no later than six months after the last contact."}
      </p>

      <h2>{de ? "Mails zur Android-App" : "Android app emails"}</h2>
      <p>
        {de
          ? "Wer sich für die Android-Mails einträgt – Hinweis auf jede neue APK-Version und darauf, wann GolfTrack im Google Play Store erscheint –, gibt seine E-Mail-Adresse an. Wir schicken daraufhin einen Bestätigungscode; erst nach dessen Eingabe gilt die Adresse als eingetragen (Double-Opt-in). Unbestätigte Adressen werden nach 24 Stunden gelöscht. Bestätigte Adressen erhalten eine Bestätigung der Anmeldung, eine Mail zu jeder neuen APK-Version und eine Nachricht, sobald die App im Play Store steht. Wer zusätzlich das freiwillige Kästchen ankreuzt oder den Knopf in der Bestätigungsmail nutzt, willigt außerdem ein, per Mail über Neuigkeiten, neue Funktionen und Angebote von GolfTrack informiert zu werden; ohne dieses Häkchen nutzen wir die Adresse für nichts anderes. Die Adresse bleibt gespeichert, bis du dich abmeldest. Jede Mail enthält einen Abmeldelink, der die Adresse sofort löscht; die Einwilligung kannst du jederzeit mit Wirkung für die Zukunft widerrufen. Versendet wird über unser Postfach bei der IONOS SE (Elgendorfer Str. 57, 56410 Montabaur). Rechtsgrundlage ist deine Einwilligung (Art. 6 Abs. 1 lit. a DSGVO)."
          : "If you sign up for the Android emails – a note on every new APK version and on when GolfTrack appears on Google Play – you enter your email address. We then send a confirmation code; the address only counts as registered once you enter it (double opt-in). Unconfirmed addresses are deleted after 24 hours. Confirmed addresses receive a confirmation of the sign-up, an email for every new APK version and a message once the app is on Google Play. If you also tick the optional box or use the button in the confirmation email, you additionally consent to receiving emails about news, new features and offers from GolfTrack; without that tick we use the address for nothing else. The address is kept until you unsubscribe. Every email contains an unsubscribe link that deletes the address immediately; you can withdraw your consent at any time with effect for the future. Emails are sent via our mailbox at IONOS SE (Elgendorfer Str. 57, 56410 Montabaur, Germany). The legal basis is your consent (Art. 6(1)(a) GDPR)."}
      </p>

      <h2>{de ? "Werbeplatz anfragen und Karte" : "Ad requests and map"}</h2>
      <p>
        {de
          ? "Wer auf /werbung einen Werbeplatz anfragt, übermittelt Standort, Umkreis, Anzeigentext sowie Name, E-Mail-Adresse und auf Wunsch Telefonnummer. Die Angaben dienen nur der Bearbeitung der Anfrage und der Durchführung des Auftrags. Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO. Kommt kein Auftrag zustande, lösche ich die Anfrage spätestens sechs Monate nach dem letzten Kontakt; Unterlagen zu einem gebuchten Auftrag bewahre ich so lange auf, wie es handels- und steuerrechtliche Pflichten verlangen (bis zu zehn Jahre, Art. 6 Abs. 1 lit. c DSGVO)."
          : "Anyone requesting an ad slot on /werbung submits a location, radius, ad text as well as name, email address and optionally a phone number. The data is only used to handle the request and carry out the order. Legal basis: Art. 6(1)(b) GDPR. If no order results, I delete the request no later than six months after the last contact; records relating to a booked order are kept as long as commercial and tax law require (up to ten years, Art. 6(1)(c) GDPR)."}
      </p>
      <p>
        {de
          ? "Zum Setzen des Standorts lässt sich dort eine Karte einblenden. Das Kartenbild kommt von der OpenStreetMap Foundation (St John’s Innovation Centre, Cowley Road, Cambridge, CB4 0WS, Großbritannien), das wahlweise einblendbare Luftbild von Esri (380 New York Street, Redlands, CA 92373, USA). Die Karte wird erst nach einem Klick auf „Karte laden“ abgerufen; erst dann erhalten diese Dienste deine IP-Adresse und die üblichen Browserangaben, was eine Übermittlung nach Großbritannien bzw. in die USA bedeuten kann. Rechtsgrundlage ist deine Einwilligung durch den Klick (Art. 6 Abs. 1 lit. a DSGVO). Ohne Karte funktioniert das Formular mit den Koordinatenfeldern genauso. Näheres: osmfoundation.org/wiki/Privacy_Policy und esri.com/de-de/privacy."
          : "To set the location you can show a map there. The map tiles come from the OpenStreetMap Foundation (St John’s Innovation Centre, Cowley Road, Cambridge, CB4 0WS, United Kingdom), the optional aerial view from Esri (380 New York Street, Redlands, CA 92373, USA). The map is only loaded after you click “Karte laden” (load map); only then do these services receive your IP address and the usual browser information, which may involve a transfer to the UK or the USA. The legal basis is your consent given by that click (Art. 6(1)(a) GDPR). Without the map the form works just as well using the coordinate fields. Details: osmfoundation.org/wiki/Privacy_Policy and esri.com/privacy."}
      </p>

      <h2>{de ? "Die App" : "The app"}</h2>
      <p>
        {de
          ? "Runden, Scores und – falls eingeschaltet – Positionsdaten bleiben auf deinem Gerät und in deiner privaten iCloud, sofern du iCloud nutzt. Sie werden nicht an mich übertragen – außer du spielst in einer Lobby mit Freunden, teilst Platzpositionen oder die anonyme Rundenstatistik (siehe unten). Das Positions-Tracking ist standardmäßig ausgeschaltet, läuft nur während einer Runde und lässt sich jederzeit im Profil löschen."
          : "Rounds, scores and – if enabled – position data stay on your device and in your private iCloud if you use iCloud. They are not transmitted to me – unless you play in a lobby with friends, share course positions or the anonymous round statistics (see below). Position tracking is off by default, runs only during a round and can be deleted at any time in the profile."}
      </p>
      <p>
        {de
          ? "Für Wetterdaten fragt die App direkt bei Open-Meteo (open-meteo.com, Schweiz) an; dabei werden die Koordinaten des Platzes sowie – technisch bedingt – die IP-Adresse deines Geräts übermittelt, aber keine Angaben zu dir oder deiner Runde. Für die Schweiz besteht ein Angemessenheitsbeschluss der EU-Kommission. Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO (Bereitstellung der Wetteranzeige). Käufe und Abos wickelt Apple über den App Store ab; ich erhalte dabei keine Zahlungsdaten."
          : "For weather data the app queries Open-Meteo (open-meteo.com, Switzerland) directly, transmitting the course coordinates and – for technical reasons – your device's IP address, but no information about you or your round. Switzerland is covered by an adequacy decision of the European Commission. The legal basis is Art. 6(1)(b) GDPR (providing the weather display). Purchases and subscriptions are handled by Apple through the App Store; I receive no payment data."}
      </p>
      <p>
        {de
          ? "Bist du auf deinem Gerät bei Game Center angemeldet, meldet die App Ergebnisse für Bestenlisten und freigeschaltete Erfolge an Apples Game Center. Was dort sichtbar ist, legst du in den Game-Center-Einstellungen deines Geräts fest; verantwortlich für Game Center ist Apple (Apple Distribution International Ltd., Hollyhill Industrial Estate, Cork, Irland). Ich erhalte darüber keine Angaben zu dir. Ohne Game-Center-Anmeldung wird nichts gemeldet."
          : "If you are signed in to Game Center on your device, the app reports scores for leaderboards and unlocked achievements to Apple's Game Center. You control what is visible there in your device's Game Center settings; Apple (Apple Distribution International Ltd., Hollyhill Industrial Estate, Cork, Ireland) is responsible for Game Center. I receive no information about you through it. Without a Game Center sign-in nothing is reported."}
      </p>

      <p>
        {de
          ? "Das Verzeichnis der Anlagen und die Anzeigen der Anlagen lädt die App von dieser Website; dabei wird nichts über deine Runden übertragen. Damit eine Anlage weiß, wie oft ihre Anzeige gesehen und angetippt wurde, meldet die App gebündelt die Kennung der Anzeige, die Art des Ereignisses und die Anzahl zurück – ohne Gerätekennung und ohne Profilbildung."
          : "The app loads the venue directory and the venues' ads from this website; nothing about your rounds is transmitted. So that a venue knows how often its ad was seen and tapped, the app reports back the ad's identifier, the type of event and a count, in batches – with no device identifier and no profiling."}
      </p>

      <h2>{de ? "Mit Freunden spielen (Lobby)" : "Playing with friends (lobby)"}</h2>
      <p>
        {de
          ? "Nur wenn du eine Lobby anlegst oder mit einem Code beitrittst, überträgt die App an diesen Server: den Namen, den du in der App eingetragen hast, deine Schläge, Putts und Schläger je Loch, das aktuelle Loch und – nur wenn in der Lobby „Gegenseitig orten“ an ist und du „Meinen Standort teilen“ nicht ausgeschaltet hast – während der Runde etwa alle zehn Sekunden deinen Standort. Sehen können das ausschließlich die Mitspieler derselben Lobby. Gespeichert wird jeweils nur der letzte Stand; ein Standort, der älter als 15 Minuten ist, wird nicht mehr angezeigt. Verlässt du die Lobby, werden deine Angaben gelöscht; löst der Gastgeber sie auf oder gibt es einen Tag lang kein Lebenszeichen, wird die ganze Lobby mit allen Angaben gelöscht. Rechtsgrundlage ist die Durchführung der von dir gewünschten Funktion (Art. 6 Abs. 1 lit. b DSGVO)."
          : "Only if you create a lobby or join one with a code does the app send this server: the name you entered in the app, your strokes, putts and clubs per hole, the current hole and – only if “Locate each other” is on in the lobby and you have not switched off “Share my location” – your location roughly every ten seconds during the round. Only the players in the same lobby can see this. Only the latest state is stored; a location older than 15 minutes is no longer shown. If you leave the lobby, your data is deleted; if the host closes it or there is no sign of activity for a day, the whole lobby is deleted with all data. The legal basis is providing the feature you asked for (Art. 6(1)(b) GDPR)."}
      </p>

      <h2>{de ? "Platzpositionen teilen" : "Sharing course positions"}</h2>
      <p>
        {de
          ? "Nur wenn du in der App „Positionen mit allen teilen“ eingeschaltet hast (Einwilligung, Art. 6 Abs. 1 lit. a DSGVO und § 25 Abs. 1 TDDDG), schickt die App nach einer Runde mit Laufspur die daraus abgeleiteten Abschlag- und Grünpunkte je Loch an diesen Server: Platz, Lochnummer, gespielte Abschlagfarbe, Koordinate auf etwa einen Meter gerundet und ein Wert, wie sicher die App sich ist. Die Laufspur selbst, Uhrzeiten, dein Name, eine Geräte- oder Rundenkennung werden nicht übertragen; gespeichert wird zu jedem Punkt nur der Tag. Die Netzadresse wird für diese Anfragen nicht protokolliert und nur flüchtig im Arbeitsspeicher gezählt, um Missbrauch zu bremsen. Sobald mindestens fünf Beiträge zu einem Loch übereinstimmen, wird der Punkt in die Platzdaten übernommen und ist für alle sichtbar. Je Punkt bleiben höchstens die 30 jüngsten Beiträge gespeichert, keiner länger als ein Jahr. Weil ein Beitrag keinen Bezug zu dir hat, kann ich ihn nachträglich nicht dir zuordnen und deshalb auch nicht gezielt löschen. Die Einwilligung kannst du jederzeit in der App unter Einstellungen › Positions-Tracking widerrufen; danach wird nichts mehr gesendet."
          : "Only if you have switched on “Share positions with everyone” in the app (consent, Art. 6(1)(a) GDPR and Section 25(1) TDDDG) does the app send this server, after a round with a walking path, the tee and green points derived from it for each hole: course, hole number, the tee colour played, the coordinate rounded to about one metre and a value for how sure the app is. The walking path itself, times, your name and any device or round identifier are not transmitted; for each point only the day is stored. The network address is not logged for these requests and is only counted briefly in memory to curb abuse. As soon as at least five contributions for a hole agree, the point is added to the course data and visible to everyone. At most the 30 most recent contributions per point are kept, none longer than a year. Because a contribution has no link to you, I cannot attribute it to you afterwards and therefore cannot delete it specifically. You can withdraw your consent at any time in the app under Settings › Position tracking; after that nothing more is sent."}
      </p>

      <h2>{de ? "Anonyme Rundenstatistik für Anlagen" : "Anonymous round statistics for courses"}</h2>
      <p>
        {de
          ? "Nur wenn du es erlaubst – in der App unter Einstellungen › Datenschutz bzw. bei der Frage am Ende einer Runde, im App Clip mit dem Schalter „Ergebnis anonym an die Anlage melden“, in der Zählkarte im Browser bei der Frage vor der ersten Bahn oder mit dem Knopf „Anonym an die Anlage melden“ am Ende (Einwilligung, Art. 6 Abs. 1 lit. a DSGVO und § 25 Abs. 1 TDDDG) –, schickt das Gerät nach einer Runde auf einer Anlage aus dem Verzeichnis eine Zusammenfassung an diesen Server: Anlage, Golf oder Minigolf, Spieltag, Wochentag, Tagesabschnitt (vormittags, mittags, nachmittags oder abends), Spieldauer auf 15 Minuten gerundet, Zahl der Spieler, Schläge je Loch bzw. Bahn und Spieler, bei Golf in der App außerdem Putts je Loch und die gespielte Abschlagfarbe, und ob die Runde aus der App, dem App Clip oder dem Browser kam. Namen, Uhrzeiten, Standort oder Laufspur, Schläger, eine Geräte- oder Rundenkennung werden nicht übertragen; auch der Zeitpunkt des Eingangs wird nicht gespeichert. Die Netzadresse wird für diese Anfragen nicht protokolliert und nur flüchtig im Arbeitsspeicher gezählt, um Missbrauch zu bremsen. Zweck ist eine Auswertung für die Betreiber der jeweiligen Anlage (etwa Auslastung, Spieldauer und Schwierigkeit einzelner Bahnen); sie erhalten ausschließlich zusammengefasste Werte aus mindestens zehn Runden, nie einzelne Runden. Die Einträge werden nach spätestens 400 Tagen gelöscht. Weil ein Eintrag keinen Bezug zu dir hat, kann ich ihn nachträglich nicht dir zuordnen und deshalb auch nicht gezielt löschen. Die Einwilligung kannst du jederzeit an derselben Stelle widerrufen; danach wird nichts mehr gesendet."
          : "Only if you allow it – in the app under Settings › Privacy or when asked at the end of a round, in the App Clip with the switch “Report anonymously to the course”, in the browser scorecard when asked before the first hole or with the button “Report anonymously to the course” at the end (consent, Art. 6(1)(a) GDPR and Section 25(1) TDDDG) – does the device send this server a summary after a round at a course from the directory: course, golf or mini golf, day played, weekday, part of the day (morning, midday, afternoon or evening), duration rounded to 15 minutes, number of players, strokes per hole and player, for golf in the app also putts per hole and the tee colour played, and whether the round came from the app, the App Clip or the browser. Names, times of day, location or walking path, clubs and any device or round identifier are not transmitted; the time of receipt is not stored either. The network address is not logged for these requests and is only counted briefly in memory to curb abuse. The purpose is an evaluation for the operators of the respective course (such as how busy it is, how long rounds take and how hard individual holes are); they only receive aggregated figures from at least ten rounds, never individual rounds. Entries are deleted after 400 days at the latest. Because an entry has no link to you, I cannot attribute it to you afterwards and therefore cannot delete it specifically. You can withdraw your consent at any time in the same place; after that nothing more is sent."}
      </p>

      <h2>{de ? "Freunde einladen" : "Inviting friends"}</h2>
      <p>
        {de
          ? "Für die Weiterempfehlung (fünf Freunde einladen, zwei Wochen GolfTrack Pro erhalten) erzeugt die App eine zufällige Gerätekennung, die nichts über dich verrät und in deinem Schlüsselbund bleibt. Ruft die App ihren Einladungscode ab oder löst sie einen Code ein, überträgt sie diese Kennung an diesen Server; gespeichert wird sie nur als Hash. Gespeichert werden außerdem dein Einladungscode, welche Geräte (als Hash) über deinen Code gezählt wurden, wann das war und – sobald du fünf Freunde zusammen hast – welcher Apple-Einmalcode dir zugeteilt wurde. Name, E-Mail-Adresse oder Apple-ID werden nicht übertragen. Rechtsgrundlage ist die Durchführung der Aktion, an der du teilnimmst (Art. 6 Abs. 1 lit. b DSGVO). Die Einträge werden gelöscht, wenn die Aktion endet."
          : "For the referral programme (invite five friends, get two weeks of GolfTrack Pro) the app creates a random device identifier that reveals nothing about you and stays in your keychain. When the app fetches its invite code or redeems a code, it sends this identifier to this server, where it is only stored as a hash. Also stored are your invite code, which devices (as a hash) were counted via your code and when, and – once you have five friends – which Apple one-time code was assigned to you. No name, email address or Apple ID is transmitted. The legal basis is carrying out the programme you take part in (Art. 6(1)(b) GDPR). The entries are deleted when the programme ends."}
      </p>

      <h2>{de ? "Deine Rechte" : "Your rights"}</h2>
      <p>
        {de
          ? "Du hast das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung der Verarbeitung, Datenübertragbarkeit und Widerspruch sowie das Recht, eine erteilte Einwilligung jederzeit mit Wirkung für die Zukunft zu widerrufen. Eine formlose E-Mail genügt. Außerdem kannst du dich bei einer Datenschutz-Aufsichtsbehörde beschweren, zum Beispiel beim Bayerischen Landesamt für Datenschutzaufsicht (Promenade 18, 91522 Ansbach, lda.bayern.de)."
          : "You have the right to access, rectification, erasure, restriction of processing, data portability and objection, and you may withdraw consent at any time with effect for the future. An informal email is enough. You may also lodge a complaint with a data protection authority, for example the Bavarian Data Protection Authority (Bayerisches Landesamt für Datenschutzaufsicht, Promenade 18, 91522 Ansbach, Germany, lda.bayern.de)."}
      </p>
    </LegalShell>
  );
}

/**
 * Bedingungen für Werbeplätze in der App. Nur deutsch: gebucht wird über das
 * deutschsprachige Formular auf /werbung, und nur von Unternehmern.
 */
export function AdTerms() {
  return (
    <LegalShell lang="de" title="Bedingungen für Werbekunden" route="terms">
      <h2>1. Geltungsbereich</h2>
      <p>
        Diese Bedingungen gelten für die Buchung von Werbeplätzen in der App GolfTrack bei {site.operator},{" "}
        <Placeholder value={site.street} />, <Placeholder value={site.city} /> („Anbieter“). Werbeplätze werden
        ausschließlich an Unternehmer im Sinne von § 14 BGB vergeben, also an Personen und Firmen, die bei der
        Buchung in gewerblicher oder selbständiger beruflicher Tätigkeit handeln – etwa Golf- und Minigolfanlagen,
        Vereine, Gastronomie und Handel. Allgemeine Geschäftsbedingungen des Werbekunden gelten nur, wenn der
        Anbieter ihnen ausdrücklich in Textform zustimmt.
      </p>

      <h2>2. Anfrage und Vertragsschluss</h2>
      <p>
        Das Formular auf golftrack.app/werbung ist eine unverbindliche Anfrage; der dort angezeigte Preis ist ein
        Richtpreis. Der Vertrag kommt erst zustande, wenn der Anbieter Anzeigentext, Umkreis, Laufzeit und Preis
        per E-Mail bestätigt. Der Anbieter kann Anfragen ohne Angabe von Gründen ablehnen.
      </p>

      <h2>3. Leistung</h2>
      <p>
        Der Anbieter zeigt die Anzeige während der vereinbarten Laufzeit auf der Zählkarte der App bei den Anlagen
        im gebuchten Umkreis. Anlagen außerhalb jedes gebuchten Umkreises können zusätzlich die Anzeige des
        nächstgelegenen Werbekunden zeigen; ein Anspruch darauf besteht nicht. Eine bestimmte Zahl an Einblendungen,
        Klicks oder Besuchern ist nicht geschuldet – sie hängt davon ab, wie viele Menschen die App auf den
        betreffenden Anlagen nutzen. Die Statistik zu Einblendungen und Klicks wird nach bestem Wissen bereitgestellt
        und ist keine Abrechnungsgrundlage. Kurze Unterbrechungen durch Wartung, Updates oder Störungen, die der
        Anbieter nicht zu vertreten hat, sind kein Mangel; fällt die Anzeige insgesamt mehr als sieben Tage am Stück
        aus, verlängert sich die Laufzeit entsprechend.
      </p>

      <h2>4. Inhalte der Anzeige</h2>
      <p>
        Für Text, Bilder, Logos und das Ziel eines Links ist allein der Werbekunde verantwortlich. Er sichert zu, dass
        er die nötigen Rechte daran hat und dass die Anzeige nicht gegen geltendes Recht, insbesondere Wettbewerbs-,
        Marken-, Urheber- und Jugendschutzrecht, oder gegen die Richtlinien des Apple App Store verstößt. Der Anbieter
        darf Anzeigen ablehnen, kürzen oder anpassen, wenn das für die Darstellung in der App nötig ist, und Anzeigen
        sperren, die gegen diese Regeln verstoßen. Der Werbekunde stellt den Anbieter von Ansprüchen Dritter frei, die
        auf dem Inhalt seiner Anzeige beruhen, einschließlich angemessener Kosten der Rechtsverteidigung.
      </p>

      <h2>5. Preise und Zahlung</h2>
      <p>
        Alle Preise verstehen sich netto zuzüglich der gesetzlichen Umsatzsteuer. Maßgeblich ist der in der
        Bestätigung genannte Preis. Der Anbieter stellt den Betrag für die gesamte Laufzeit zu deren Beginn in
        Rechnung; die Rechnung ist innerhalb von 14 Tagen ohne Abzug zu zahlen. Bei Zahlungsverzug darf der Anbieter
        die Anzeige bis zum Zahlungseingang aussetzen.
      </p>

      <h2>6. Laufzeit und Kündigung</h2>
      <p>
        Die Laufzeit ist fest vereinbart und endet automatisch, ohne dass es einer Kündigung bedarf; sie verlängert
        sich nicht stillschweigend. Eine ordentliche Kündigung während der Laufzeit ist ausgeschlossen. Das Recht
        beider Seiten zur Kündigung aus wichtigem Grund bleibt unberührt; ein wichtiger Grund für den Anbieter ist
        insbesondere ein schwerer oder trotz Hinweis wiederholter Verstoß gegen Nummer 4. Wird eine Anzeige deshalb
        gesperrt oder gekündigt, besteht kein Anspruch auf Erstattung.
      </p>

      <h2>7. Haftung</h2>
      <p>
        Der Anbieter haftet unbeschränkt bei Vorsatz und grober Fahrlässigkeit, bei Verletzung von Leben, Körper oder
        Gesundheit sowie nach dem Produkthaftungsgesetz. Bei leichter Fahrlässigkeit haftet er nur für die Verletzung
        einer wesentlichen Vertragspflicht, deren Erfüllung die ordnungsgemäße Durchführung des Vertrags überhaupt erst
        ermöglicht und auf deren Einhaltung der Werbekunde regelmäßig vertrauen darf, und zwar begrenzt auf den
        vertragstypischen, vorhersehbaren Schaden, höchstens auf den Auftragswert. Im Übrigen ist die Haftung
        ausgeschlossen.
      </p>

      <h2>8. Schlussbestimmungen</h2>
      <p>
        Es gilt das Recht der Bundesrepublik Deutschland unter Ausschluss des UN-Kaufrechts. Ist der Werbekunde
        Kaufmann, juristische Person des öffentlichen Rechts oder öffentlich-rechtliches Sondervermögen, ist
        Gerichtsstand der Sitz des Anbieters. Änderungen und Ergänzungen bedürfen der Textform (E-Mail genügt). Ist
        eine Bestimmung unwirksam, bleiben die übrigen wirksam.
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
  route: "imprint" | "privacy" | "terms";
  children: React.ReactNode;
}) {
  const copy = t(lang);
  return (
    <>
      <Header lang={lang} />
      <PageHeader index={route === "imprint" ? "14 — Recht" : route === "privacy" ? "15 — Recht" : "16 — Recht"} title={title} />
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
