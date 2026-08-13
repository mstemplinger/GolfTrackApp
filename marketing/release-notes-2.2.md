# Release Notes 2.2 – Positions-Tracking

Für App Store Connect → „Neue Funktionen dieser Version". Pro Sprache einfügen.
Grenze: 4.000 Zeichen, alle Fassungen liegen weit darunter.

---

## Deutsch (de)

Neu: Dein Weg über den Platz

GolfTrack kann jetzt aufzeichnen, wo du während der Runde unterwegs warst – und daraus lernen, wie die Löcher liegen.

• Laufspur: Nach der Runde siehst du deinen Weg über den Platz auf der Karte, Loch für Loch.
• Abschlag und Grün automatisch: Aus deinen Runden schätzt die App, wo Abschlag und Fahne jedes Lochs liegen. Danach steht die Entfernung zur Fahne da, ohne dass du den Pin selbst setzen musst.
• Fairway-Verlauf: Nach ein paar Runden zeichnet die App, wo das Fairway ungefähr verläuft – Doglegs inklusive. Je mehr Runden, desto genauer.

Das Tracking ist standardmäßig aus. Du schaltest es in Profil → Positions-Tracking ein, es läuft nur während einer Runde, die Daten bleiben auf deinem iPhone und du kannst sie dort jederzeit löschen.

Außerdem: Pluralformen und Beschriftungen in Englisch, Französisch, Italienisch und Spanisch korrigiert.

---

## English (en)

New: Your path around the course

GolfTrack can now record where you walked during a round – and learn from it how the holes are laid out.

• Walking path: After the round you can see your route across the course on the map, hole by hole.
• Tee and green automatically: From your rounds the app estimates where the tee and the pin of each hole are. After that the distance to the pin is simply there, without you setting the pin yourself.
• Fairway shape: After a few rounds the app draws roughly where the fairway runs – doglegs included. The more rounds, the more accurate.

Tracking is off by default. You turn it on in Profile → Position tracking, it only runs during a round, the data stays on your iPhone and you can delete it there at any time.

Also: fixed plural forms and labels in English, French, Italian and Spanish.

---

## Français (fr)

Nouveau : ton parcours sur le terrain

GolfTrack peut désormais enregistrer où tu es passé pendant une partie – et en déduire la disposition des trous.

• Tracé : après la partie, tu vois ton itinéraire sur la carte, trou par trou.
• Départ et green automatiquement : à partir de tes parties, l'app estime où se trouvent le départ et le drapeau de chaque trou. La distance au drapeau s'affiche ensuite sans que tu aies à le placer toi-même.
• Tracé du fairway : après quelques parties, l'app dessine approximativement le tracé du fairway, doglegs compris. Plus il y a de parties, plus c'est précis.

Le suivi est désactivé par défaut. Tu l'actives dans Profil → Suivi de position, il ne fonctionne que pendant une partie, les données restent sur ton iPhone et tu peux les supprimer à tout moment.

Par ailleurs : correction des pluriels et des libellés en anglais, français, italien et espagnol.

---

## Italiano (it)

Novità: il tuo percorso sul campo

GolfTrack ora può registrare dove ti sei mosso durante un giro – e capirne la disposizione delle buche.

• Tracciato: dopo il giro vedi il tuo percorso sulla mappa, buca per buca.
• Tee e green automaticamente: dai tuoi giri l'app stima dove si trovano il tee e la bandiera di ogni buca. Dopodiché la distanza dalla bandiera compare da sola, senza che tu debba impostarla.
• Andamento del fairway: dopo qualche giro l'app disegna all'incirca dove passa il fairway, dogleg inclusi. Più giri, più è precisa.

Il tracciamento è disattivato di default. Lo attivi in Profilo → Tracciamento posizione, funziona solo durante un giro, i dati restano sul tuo iPhone e puoi eliminarli lì in qualsiasi momento.

Inoltre: corretti plurali ed etichette in inglese, francese, italiano e spagnolo.

---

## Español (es)

Novedad: tu recorrido por el campo

GolfTrack ahora puede grabar por dónde has ido durante una vuelta y deducir de ello cómo están dispuestos los hoyos.

• Trazado: después de la vuelta puedes ver tu recorrido por el campo en el mapa, hoyo por hoyo.
• Tee y green automáticamente: a partir de tus vueltas, la app estima dónde están el tee y la bandera de cada hoyo. Después la distancia a la bandera aparece sola, sin que tengas que colocarla tú.
• Trazado del fairway: tras unas cuantas vueltas la app dibuja por dónde va aproximadamente el fairway, doglegs incluidos. Cuantas más vueltas, más preciso.

El seguimiento está desactivado por defecto. Lo activas en Perfil → Seguimiento de posición, solo funciona durante una vuelta, los datos permanecen en tu iPhone y puedes borrarlos allí en cualquier momento.

Además: corregidos los plurales y las etiquetas en inglés, francés, italiano y español.

---

## Hinweise für die Einreichung

**Hintergrund-Standort im Review.** Die App nutzt jetzt `UIBackgroundModes: location`. Apple fragt bei solchen Apps regelmäßig nach, warum das nötig ist. Vorbereitete Antwort für „App Review Information → Notes":

> Während einer laufenden Golfrunde zeichnet die App auf Wunsch des Nutzers die Positionen auf, um daraus Abschlag- und Grünpositionen der Löcher abzuleiten und die Entfernung zur Fahne anzuzeigen. Eine Runde dauert vier bis fünf Stunden, das Display ist dabei meist gesperrt – deshalb wird der Background-Mode benötigt. Die Aufzeichnung ist standardmäßig deaktiviert, wird ausschließlich vom Nutzer in den Einstellungen aktiviert, läuft nur während einer Runde und endet mit deren Abschluss. Die Daten verlassen das Gerät nicht.

**App-Datenschutz.** Bleibt unverändert: Die Positionsdaten werden ausschließlich lokal verarbeitet und nicht übertragen, daher keine neue Datenerhebung im Sinne der App-Datenschutzangaben. `PrivacyInfo.xcprivacy` ist bewusst nicht angepasst. Sobald Daten hochgeladen werden (geplante Crowd-Aggregation), muss dort `NSPrivacyCollectedDataTypePreciseLocation` ergänzt und die Angabe im Store aktualisiert werden.

**Screenshots.** Optional. Für die neuen Funktionen gibt es noch keine Store-Screenshots; die bestehenden bleiben gültig.
