// Prüft die Rechenlogik der Crowd-Positionen ohne Datenbank.
// Aufruf aus web/:  node deploy/check-geometry-consensus.mjs
import assert from "node:assert/strict";
import {
  CONFLICT_METERS,
  MIN_CONTRIBUTORS,
  consensus,
  decide,
  distanceMeters,
} from "../src/lib/geometryConsensus.ts";

const base = { lat: 48.83215, lon: 13.37012 };
/** Punkt `north` Meter nördlich und `east` Meter östlich von `base`. */
const at = (north, east) => ({
  lat: base.lat + north / 111_320,
  lon: base.lon + east / (111_320 * Math.cos((base.lat * Math.PI) / 180)),
});

// 1) Zu wenige Beiträge → kein Ergebnis.
assert.equal(consensus([at(0, 0), at(1, 1), at(2, 0), at(0, 2)], "tee"), null);

// 2) Fünf enge Beiträge → Ergebnis nahe am wahren Punkt.
const tight = [at(0, 0), at(2, 1), at(-1, 2), at(1, -2), at(-2, -1)];
const ok = consensus(tight, "tee");
assert.ok(ok, "enge Beiträge ergeben einen Wert");
assert.equal(ok.contributors, MIN_CONTRIBUTORS);
assert.ok(distanceMeters(ok.point, base) < 2, "Median liegt am Punkt");

// 3) Zwei Ausreißer (Vandalismus, 300 m daneben) ändern nichts.
const withJunk = [...tight, at(300, 0), at(300, 1)];
const robust = consensus(withJunk, "tee");
assert.ok(robust);
assert.equal(robust.contributors, 5, "Ausreißer zählen nicht mit");
assert.ok(distanceMeters(robust.point, base) < 2);

// 4) Gleich viele Unsinnsbeiträge wie echte → der Median kippt nicht unbemerkt:
//    ohne Mehrheit am selben Ort bleibt es bei null.
const split = [at(0, 0), at(1, 0), at(0, 1), at(200, 0), at(201, 0), at(200, 1)];
assert.equal(consensus(split, "tee"), null);

// 5) Weit gestreute Beiträge (kein gemeinsamer Ort) → null.
const scattered = [at(0, 0), at(20, 0), at(-20, 0), at(0, 20), at(0, -20), at(14, 14)];
assert.equal(consensus(scattered, "tee"), null);
// … für ein Grün ist dieselbe Streuung noch zu groß? 20 m Median-Abstand > 15 m
assert.equal(consensus(scattered, "green"), null);

// 6) Entscheidungen.
const next = base;
const far = at(40, 0);
const near = at(5, 0);
assert.equal(decide({ consensus: next, current: null, lastApplied: null, seenBefore: false, operatorProvided: true }), "apply", "leeres Feld wird gefüllt");
assert.equal(decide({ consensus: next, current: at(1, 0), lastApplied: null, seenBefore: false, operatorProvided: true }), "unchanged");
assert.equal(decide({ consensus: next, current: far, lastApplied: null, seenBefore: false, operatorProvided: false }), "apply", "ungeprüfter Importwert wird ersetzt");
assert.equal(decide({ consensus: next, current: far, lastApplied: null, seenBefore: false, operatorProvided: true }), "conflict", "Betreiberwert bleibt, Widerspruch vermerkt");
assert.equal(decide({ consensus: next, current: near, lastApplied: null, seenBefore: false, operatorProvided: true }), "kept", "Betreiberwert, grob gleich");
assert.equal(decide({ consensus: next, current: far, lastApplied: far, seenBefore: true, operatorProvided: true }), "apply", "eigener Crowd-Wert darf nachziehen");
assert.equal(decide({ consensus: next, current: far, lastApplied: at(80, 0), seenBefore: true, operatorProvided: false }), "conflict", "von Hand geändert → gilt als geprüft");
assert.ok(distanceMeters(far, next) > CONFLICT_METERS);

console.log("geometryConsensus: alle Prüfungen bestanden");
