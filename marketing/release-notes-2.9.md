# Release Notes 2.9 – Platzdaten gemeinsam verbessern, schlankere App

Für App Store Connect → „Neue Funktionen dieser Version". Pro Sprache einfügen.
Grenze: 4.000 Zeichen, alle Fassungen liegen weit darunter.

Geschrieben wird das über `asc-fill-metadata.py --version 2.9`; die Abschnitte
unten sind genau so aufgebaut, wie das Skript sie erwartet (Sprachkürzel in
Klammern in der Überschrift, Review-Notizen als Blockquote unter „Einreichung").

---

## Deutsch (de)

Richtige Entfernungen für alle

• Mit eingeschalteter Laufspur erkennt GolfTrack nach der Runde, wo Abschlag und Grün jedes Lochs liegen.
• Wenn du möchtest, teilst du diese Punkte. Sobald fünf Spieler übereinstimmen, gilt die Position für alle auf dem Platz.
• Verbesserte Positionen kommen von selbst in deine App – auch auf Plätzen, die du zum ersten Mal spielst.
• Geteilt werden nur die Punkte: keine Laufspur, kein Name, keine Geräte-ID. Ein- und ausschalten unter Einstellungen › Positions-Tracking.

Kleinere App

• Die Audio-Lektionen werden jetzt nach der Installation geladen. Die App ist dadurch deutlich kleiner und schneller installiert – auch mit schwachem Netz auf dem Platz.
• Einmal geladen, laufen die Lektionen offline.

Kleinigkeiten

• Aktualisierte Platzdaten für viele Golfplätze.

---

## English (en)

Accurate distances for everyone

• With your track turned on, GolfTrack works out where the tee and green of each hole are after the round.
• If you like, share these points. Once five players agree, the position applies to everyone on that course.
• Improved positions arrive in your app automatically – even on courses you play for the first time.
• Only the points are shared: no track, no name, no device ID. Turn it on or off under Settings › Position tracking.

Smaller app

• Audio lessons are now downloaded after installing. The app is much smaller and installs faster – even with weak signal on the course.
• Once downloaded, lessons play offline.

Small things

• Updated course data for many golf courses.

---

## Français (fr)

Des distances justes pour tous

• Avec le tracé activé, GolfTrack repère après la partie où se trouvent le départ et le green de chaque trou.
• Si tu le souhaites, tu partages ces points. Dès que cinq joueurs concordent, la position vaut pour tous sur ce parcours.
• Les positions améliorées arrivent automatiquement dans ton app – même sur des parcours que tu joues pour la première fois.
• Seuls les points sont partagés : pas de tracé, pas de nom, pas d’identifiant d’appareil. À activer ou désactiver dans Réglages › Suivi de position.

Une app plus légère

• Les leçons audio sont désormais téléchargées après l’installation. L’app est bien plus légère et s’installe plus vite – même avec un réseau faible sur le parcours.
• Une fois téléchargées, les leçons fonctionnent hors ligne.

Petites choses

• Données mises à jour pour de nombreux parcours.

---

## Italiano (it)

Distanze corrette per tutti

• Con il tracciato attivo, GolfTrack riconosce dopo il giro dove si trovano partenza e green di ogni buca.
• Se vuoi, condividi questi punti. Quando cinque giocatori concordano, la posizione vale per tutti sul percorso.
• Le posizioni migliorate arrivano da sole nella tua app – anche sui percorsi che giochi per la prima volta.
• Si condividono solo i punti: nessun tracciato, nessun nome, nessun ID del dispositivo. Attiva o disattiva in Impostazioni › Tracciamento posizione.

App più leggera

• Le lezioni audio ora si scaricano dopo l’installazione. L’app è molto più leggera e si installa più in fretta – anche con poco segnale sul campo.
• Una volta scaricate, le lezioni funzionano offline.

Piccole cose

• Dati aggiornati per molti campi da golf.

---

## Español (es)

Distancias correctas para todos

• Con el recorrido activado, GolfTrack reconoce tras la vuelta dónde están la salida y el green de cada hoyo.
• Si quieres, compartes esos puntos. Cuando cinco jugadores coinciden, la posición vale para todos en ese campo.
• Las posiciones mejoradas llegan solas a tu app, incluso en campos que juegas por primera vez.
• Solo se comparten los puntos: sin recorrido, sin nombre, sin ID del dispositivo. Actívalo o desactívalo en Ajustes › Seguimiento de posición.

App más ligera

• Las lecciones de audio se descargan ahora después de instalar. La app es mucho más ligera y se instala más rápido, incluso con poca cobertura en el campo.
• Una vez descargadas, las lecciones funcionan sin conexión.

Pequeños detalles

• Datos actualizados de muchos campos de golf.

---

## Hinweise für die Einreichung

**Review-Notizen.** Hintergrund-Standort, Lobby, Weiterempfehlung und Anzeigen wie
bisher; neu sind die geteilten Platzpositionen und das Nachladen der Audio-Lektionen.

> During a golf round the app can, if the user turns it on, record positions to derive tee and green positions and show the distance to the flag. A round takes four to five hours with the display mostly locked, which is why the location background mode is needed. Recording is off by default, runs only during a round and ends with it. The track stays on the device; only when the user joins a "play with friends" lobby and turns on location sharing is the current position sent to golftrack.app for the other players of that lobby.
> New in 2.9 – Shared course positions: after a round with tracking on, the app asks once whether it may send the derived tee and green points per hole to golftrack.app ("Platzdaten für alle verbessern?" – Teilen / Nicht teilen). It can be changed any time under Settings › Positions-Tracking › "Positionen mit allen teilen". Only the derived points (one coordinate per tee and per green) and the course are sent – no track, no name, no account, no device ID. Once five independent submissions agree within a few metres, the server publishes the point for that course and all apps pick it up. Off by default; nothing is sent without consent. Declared in the privacy manifest as precise location, not linked, app functionality.
> Audio lessons: only lesson 1 ships in the app bundle; lessons 2–17 are downloaded from golftrack.app after install (Wi-Fi only in the background, any network when the user taps a lesson). They are plain audio files, no executable code.
> Invite friends (since 2.8): Profile → "Freunde einladen". After five friends the server hands out one App Store one-time offer code (2 weeks of GolfTrack Pro). The device is identified by a random ID kept in the keychain, not by any hardware or advertising identifier.
> The ads on the scorecard do not come from an ad network: venue operators book them directly with the developer and the app loads them as a plain list from golftrack.app. No ad SDK, no IDFA, no profiling. Only ad ID, event type (impression or tap) and a count are reported, aggregated and not linked to a user. GolfTrack Pro removes them.
