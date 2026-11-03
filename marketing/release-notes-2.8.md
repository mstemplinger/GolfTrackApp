# Release Notes 2.8 – Freunde einladen, Tipps in Pro, Testphase

Für App Store Connect → „Neue Funktionen dieser Version". Pro Sprache einfügen.
Grenze: 4.000 Zeichen, alle Fassungen liegen weit darunter.

Geschrieben wird das über `asc-fill-metadata.py --version 2.8`; die Abschnitte
unten sind genau so aufgebaut, wie das Skript sie erwartet (Sprachkürzel in
Klammern in der Überschrift, Review-Notizen als Blockquote unter „Einreichung").

---

## Deutsch (de)

Freunde einladen

• Im Profil findest du deinen eigenen Einladungslink. Haben fünf Freunde GolfTrack darüber geöffnet, bekommst du zwei Wochen GolfTrack Pro geschenkt.

GolfTrack Pro

• Drei Tage kostenlos testen – monatlich oder jährlich.
• Die Tipps in Anfänger, Technik, Mental Game und Strategie samt Grafiken gehören jetzt zu Pro.
• Wer zurückkommt, bekommt Pro günstiger.

Kleinigkeiten

• Schläge lassen sich wieder bis auf 0 zurücknehmen.
• Ein Putt zählt jetzt direkt als Schlag, und unter der Schlagzahl steht der zuletzt benutzte Schläger.
• Im Profil zeigen zwei Knöpfe Bestenliste und Erfolge.

---

## English (en)

Invite friends

• Your profile has your personal invite link. Once five friends have opened GolfTrack through it, you get two weeks of GolfTrack Pro for free.

GolfTrack Pro

• Try it free for three days – monthly or yearly.
• The tips in Beginner, Technique, Mental Game and Strategy, illustrations included, are now part of Pro.
• Coming back? Pro is cheaper for returning subscribers.

Small things

• Strokes can be taken back all the way to 0 again.
• A putt now counts as a stroke right away, and the last club used is shown under the stroke count.
• Two buttons in your profile open the leaderboard and achievements.

---

## Français (fr)

Inviter des amis

• Ton profil contient ton lien d’invitation personnel. Dès que cinq amis ont ouvert GolfTrack avec ce lien, tu reçois deux semaines de GolfTrack Pro offertes.

GolfTrack Pro

• Essai gratuit de trois jours – mensuel ou annuel.
• Les conseils Débutant, Technique, Mental et Stratégie, illustrations comprises, font désormais partie de Pro.
• Tu reviens ? Pro est moins cher pour les anciens abonnés.

Petites choses

• Les coups peuvent de nouveau être retirés jusqu’à 0.
• Un putt compte désormais directement comme un coup, et le dernier club utilisé s’affiche sous le nombre de coups.
• Deux boutons dans le profil ouvrent le classement et les succès.

---

## Italiano (it)

Invita amici

• Nel profilo trovi il tuo link di invito personale. Quando cinque amici hanno aperto GolfTrack con quel link, ricevi due settimane di GolfTrack Pro in regalo.

GolfTrack Pro

• Prova gratuita di tre giorni – mensile o annuale.
• I consigli Principianti, Tecnica, Mental Game e Strategia, grafiche comprese, ora fanno parte di Pro.
• Torni da noi? Pro costa meno per chi si riabbona.

Piccole cose

• I colpi si possono di nuovo togliere fino a 0.
• Un putt ora conta subito come colpo e sotto il numero di colpi compare l’ultimo bastone usato.
• Nel profilo due pulsanti aprono la classifica e gli obiettivi.

---

## Español (es)

Invitar amigos

• En tu perfil tienes tu enlace de invitación personal. Cuando cinco amigos hayan abierto GolfTrack con él, recibes dos semanas de GolfTrack Pro gratis.

GolfTrack Pro

• Prueba gratuita de tres días – mensual o anual.
• Los consejos de Principiante, Técnica, Juego mental y Estrategia, con gráficos, ahora forman parte de Pro.
• ¿Vuelves? Pro sale más barato para quienes se suscriben de nuevo.

Pequeños detalles

• Los golpes se pueden volver a quitar hasta 0.
• Un putt cuenta ahora directamente como golpe y bajo el número de golpes aparece el último palo usado.
• En el perfil, dos botones abren la clasificación y los logros.

---

## Hinweise für die Einreichung

**Review-Notizen.** Hintergrund-Standort und Anzeigen wie bisher; neu sind die
Weiterempfehlung, die Testphase, die Win-back-Angebote und die Pro-Tipps.

> During a golf round the app can, if the user turns it on, record positions to derive tee and green positions and show the distance to the flag. A round takes four to five hours with the display mostly locked, which is why the location background mode is needed. Recording is off by default, runs only during a round and ends with it. The track stays on the device; only when the user joins a "play with friends" lobby and turns on location sharing is the current position sent to golftrack.app for the other players of that lobby.
> New in 2.8 – Invite friends: Profile → "Freunde einladen". Each install gets a six-character invite code and a link golftrack.app/einladen/<code> to share. A friend counts once their app redeems the code (by opening the link, or by typing the code into the same card under "Von einem Freund eingeladen?"). Each device counts only once and never for its own code; the device is identified by a random ID the app generates and keeps in the keychain, not by any hardware or advertising identifier. After five friends the server hands out one App Store one-time offer code (subscription offer code on GolfTrackPro_abo: 2 weeks free, auto-renew off), redeemed through Apple's standard redemption page. Sharing is optional and nothing is unlocked by sharing alone.
> GolfTrack Pro now includes the tips in the Tips tab categories (Anfänger, Technik, Mental Game, Strategie): without Pro each tip shows one line and opens the purchase screen. The daily tip, the golf guide and statistics stay free. Pro has a 3-day free trial on the monthly and yearly subscription and win-back offers for lapsed paying subscribers; the purchase screen shows the win-back price when StoreKit reports the customer as eligible.
> The ads on the scorecard do not come from an ad network: venue operators book them directly with the developer and the app loads them as a plain list from golftrack.app. No ad SDK, no IDFA, no profiling. Only ad ID, event type (impression or tap) and a count are reported, aggregated and not linked to a user. GolfTrack Pro removes them.
