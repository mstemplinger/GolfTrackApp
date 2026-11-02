# Release Notes 2.6 – Einstieg mit Berechtigungen, Tipp-Grafiken, Trinkerinnerung

Für App Store Connect → „Neue Funktionen dieser Version". Pro Sprache einfügen.
Grenze: 4.000 Zeichen, alle Fassungen liegen weit darunter.

Geschrieben wird das über `asc-fill-metadata.py --version 2.6`; die Abschnitte
unten sind genau so aufgebaut, wie das Skript sie erwartet (Sprachkürzel in
Klammern in der Überschrift, Review-Notizen als Blockquote unter „Einreichung").

---

## Deutsch (de)

Neuer Einstieg

• Nach deinem Namen fragt GolfTrack der Reihe nach, ob es dir Mitteilungen schicken und deinen Standort nutzen darf, und bietet dann das Positions-Tracking an. Vorher erscheint keine Rückfrage mehr.
• Auch beim Minigolf legst du zu Beginn deinen Namen fest.
• „Tutorial neu starten“ im Profil bringt dich danach auf die Startseite.

Tipps mit Grafiken

• 20 Tipps zu Grundlagen, Technik, Mental Game und Strategie zeigen jetzt eine animierte Grafik: Griff, Stand, Hüftdrehung, Schwungbahn, Wind, Risiko und mehr.

Trinkerinnerung

• Während der Runde erinnert dich GolfTrack alle 30 Minuten ans Trinken. Den Abstand (20 bis 60 Minuten) änderst oder die Erinnerung abschaltest du unter Einstellungen → Mitteilungen.

Außerdem: Anzeigen auf der Zählkarte lassen sich immer antippen und erklären, warum sie dort stehen.

---

## English (en)

New first steps

• After your name, GolfTrack asks one after the other whether it may send you notifications and use your location, then offers position tracking. No more prompts before that.
• Minigolf players set their name at the start, too.
• “Restart tutorial” in your profile takes you to the home screen afterwards.

Tips with graphics

• 20 tips on basics, technique, mental game and strategy now come with an animated graphic: grip, stance, hip turn, swing path, wind, risk and more.

Drink reminder

• During a round, GolfTrack reminds you to drink every 30 minutes. Change the interval (20 to 60 minutes) or turn it off under Settings → Notifications.

Also: ads on the scorecard can always be tapped and explain why they are shown there.

---

## Français (fr)

Nouveaux premiers pas

• Après ton prénom, GolfTrack demande l’une après l’autre s’il peut t’envoyer des notifications et utiliser ta position, puis propose le suivi de position. Plus aucune demande avant cela.
• En minigolf aussi, tu indiques ton prénom au départ.
• « Relancer le tutoriel » dans le profil te ramène ensuite à l’écran d’accueil.

Conseils illustrés

• 20 conseils sur les bases, la technique, le mental et la stratégie s’accompagnent d’une animation : grip, posture, rotation des hanches, trajectoire du swing, vent, prise de risque et plus.

Rappel pour boire

• Pendant la partie, GolfTrack te rappelle de boire toutes les 30 minutes. Modifie l’intervalle (20 à 60 minutes) ou désactive le rappel dans Réglages → Notifications.

Aussi : les annonces sur la carte de score sont toujours cliquables et expliquent pourquoi elles y figurent.

---

## Italiano (it)

Nuovi primi passi

• Dopo il tuo nome, GolfTrack chiede una dopo l’altra se può inviarti notifiche e usare la tua posizione, poi propone il tracciamento della posizione. Prima non compare più nessuna richiesta.
• Anche nel minigolf inserisci il tuo nome all’inizio.
• «Riavvia tutorial» nel profilo ti riporta poi alla schermata iniziale.

Consigli con grafiche

• 20 consigli su basi, tecnica, mental game e strategia ora hanno una grafica animata: impugnatura, posizione, rotazione dei fianchi, traiettoria dello swing, vento, rischio e altro.

Promemoria per bere

• Durante il giro, GolfTrack ti ricorda di bere ogni 30 minuti. Puoi cambiare l’intervallo (da 20 a 60 minuti) o disattivarlo in Impostazioni → Notifiche.

Inoltre: gli annunci sulla scorecard si possono sempre toccare e spiegano perché compaiono lì.

---

## Español (es)

Nuevos primeros pasos

• Después de tu nombre, GolfTrack pregunta uno tras otro si puede enviarte notificaciones y usar tu ubicación, y luego ofrece el seguimiento de posición. Ya no aparece ninguna solicitud antes.
• En minigolf también indicas tu nombre al empezar.
• «Reiniciar tutorial» en el perfil te lleva después a la pantalla de inicio.

Consejos con gráficos

• 20 consejos de fundamentos, técnica, juego mental y estrategia muestran ahora un gráfico animado: grip, postura, giro de cadera, trayectoria del swing, viento, riesgo y más.

Recordatorio para beber

• Durante la ronda, GolfTrack te recuerda beber cada 30 minutos. Cambia el intervalo (de 20 a 60 minutos) o desactívalo en Ajustes → Notificaciones.

Además: los anuncios en la tarjeta siempre se pueden tocar y explican por qué aparecen ahí.

---

## Hinweise für die Einreichung

**Review-Notizen.** Hintergrund-Standort und Anzeigen wie in 2.5; neu ist, dass das
Onboarding nach Zustimmung zum Tracking „Immer“ erfragt.

> During a golf round the app can, if the user turns it on, record positions to derive tee and green positions and show the distance to the flag. A round takes four to five hours with the display mostly locked, which is why the location background mode is needed. Recording is off by default, runs only during a round and ends with it. The data does not leave the device.
> New in 2.6: the first-launch introduction asks for permissions only after the user has entered a name – first notifications, then location “While Using”. It then asks in the app whether to turn on position tracking. Only if the user taps “Aufzeichnung einschalten” does the app request “Always” location, with an explanation on screen beforehand; “Später entscheiden” skips it. “Always” is also used by the optional “Platz in der Nähe” notification (off by default). Declining any of these leaves the app fully usable.
> Drink reminder: Settings → Mitteilungen → “Trinkerinnerung”. On by default (every 30 minutes, adjustable 20–60 or off). Local notifications are scheduled when a scorecard is opened and removed when the round is finished; the series ends after six hours at the latest.
> The ads on the scorecard do not come from an ad network: venue operators book them directly with the developer and the app loads them as a plain list from golftrack.app. No ad SDK, no device identifier, no IDFA, no profiling. Only ad ID, event type (impression or tap) and a count are reported, aggregated and not linked to a user. Any subscription or the one-time purchase “Werbefrei” removes them.
> No new in-app purchases in this version.
