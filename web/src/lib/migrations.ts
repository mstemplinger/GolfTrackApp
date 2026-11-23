import "server-only";
import { query } from "./db";

/**
 * Schema-Definition. Alle Anweisungen sind idempotent und laufen beim ersten
 * Datenbankzugriff eines Prozesses – so braucht das Deployment keinen
 * separaten Migrationsschritt.
 */
const STATEMENTS = [
  `CREATE TABLE IF NOT EXISTS courses (
     id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
     slug            text UNIQUE NOT NULL,
     kind            text NOT NULL CHECK (kind IN ('golf', 'minigolf')),
     status          text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
     name            text NOT NULL,
     location        text NOT NULL DEFAULT '',
     country         text NOT NULL DEFAULT 'DE',
     holes           integer NOT NULL,
     latitude        double precision,
     longitude       double precision,
     first_tee_lat   double precision,
     first_tee_lon   double precision,
     course_rating   double precision,
     slope_rating    integer,
     hole_data       jsonb NOT NULL DEFAULT '[]'::jsonb,
     facility_notes  text NOT NULL DEFAULT '',
     facility_hints  jsonb NOT NULL DEFAULT '[]'::jsonb,
     welcome         text NOT NULL DEFAULT '',
     website         text NOT NULL DEFAULT '',
     phone           text NOT NULL DEFAULT '',
     public_email    text NOT NULL DEFAULT '',
     submitter_name  text NOT NULL DEFAULT '',
     submitter_email text NOT NULL DEFAULT '',
     submitter_role  text NOT NULL DEFAULT '',
     admin_notes     text NOT NULL DEFAULT '',
     source          text NOT NULL DEFAULT 'form',
     created_at      timestamptz NOT NULL DEFAULT now(),
     updated_at      timestamptz NOT NULL DEFAULT now(),
     reviewed_at     timestamptz,
     published_at    timestamptz
   )`,
  // Nachgereicht – siehe die Anmerkung bei `ads`: eine bestehende Tabelle
  // bekommt neue Spalten nur über ein eigenes ALTER.
  `ALTER TABLE courses ADD COLUMN IF NOT EXISTS facility_hints jsonb NOT NULL DEFAULT '[]'::jsonb`,
  // Abschläge nach Farbe (nur Golf). Längen und Positionen je Loch stehen
  // in `hole_data`, hier nur Farbe und Wertung.
  `ALTER TABLE courses ADD COLUMN IF NOT EXISTS tees jsonb NOT NULL DEFAULT '[]'::jsonb`,
  `ALTER TABLE courses ADD COLUMN IF NOT EXISTS first_tee_lat  double precision`,
  `ALTER TABLE courses ADD COLUMN IF NOT EXISTS first_tee_lon  double precision`,
  // Wo die Lochdaten den Abschlag von Loch 1 schon kennen, ihn übernehmen –
  // sonst bliebe das Feld leer, obwohl die Angabe längst im Haus ist. Läuft
  // nur über Plätze ohne eigenen Eintrag, überschreibt also nie eine Angabe
  // des Betreibers.
  //
  // Korrelierte Unterabfragen im SET, **kein** LATERAL im FROM: Postgres
  // lässt die Zieltabelle eines UPDATE dort nicht referenzieren
  // („invalid reference to FROM-clause entry").
  `UPDATE courses c
      SET first_tee_lat = (SELECT (e->>'teeLat')::double precision
                             FROM jsonb_array_elements(c.hole_data) e
                            WHERE jsonb_typeof(e->'number') = 'number'
                              AND (e->>'number')::int = 1
                              AND jsonb_typeof(e->'teeLat') = 'number'
                            LIMIT 1),
          first_tee_lon = (SELECT (e->>'teeLon')::double precision
                             FROM jsonb_array_elements(c.hole_data) e
                            WHERE jsonb_typeof(e->'number') = 'number'
                              AND (e->>'number')::int = 1
                              AND jsonb_typeof(e->'teeLon') = 'number'
                            LIMIT 1)
    WHERE c.first_tee_lat IS NULL
      AND jsonb_typeof(c.hole_data) = 'array'
      AND EXISTS (SELECT 1 FROM jsonb_array_elements(c.hole_data) e
                   WHERE jsonb_typeof(e->'number') = 'number'
                     AND (e->>'number')::int = 1
                     AND jsonb_typeof(e->'teeLat') = 'number'
                     AND jsonb_typeof(e->'teeLon') = 'number')`,
  `CREATE INDEX IF NOT EXISTS courses_status_kind_idx ON courses (status, kind)`,
  `CREATE INDEX IF NOT EXISTS courses_updated_at_idx ON courses (updated_at DESC)`,
  // Altbestand geradeziehen: bis zum 11.09.2026 wurden jsonb-Spalten doppelt
  // kodiert geschrieben (JSON.stringify vor dem Treiber), sie liegen deshalb
  // als JSON-Zeichenkette statt als Array in der Tabelle. Der Ausdruck
  // `#>> '{}'` holt den Text aus dem Skalar; die WHERE-Klausel macht die
  // Anweisung idempotent.
  `UPDATE courses SET hole_data = (hole_data #>> '{}')::jsonb WHERE jsonb_typeof(hole_data) = 'string'`,
  `UPDATE courses SET facility_hints = (facility_hints #>> '{}')::jsonb WHERE jsonb_typeof(facility_hints) = 'string'`,
  `CREATE TABLE IF NOT EXISTS submission_attempts (
     id         bigserial PRIMARY KEY,
     ip_hash    text NOT NULL,
     created_at timestamptz NOT NULL DEFAULT now()
   )`,
  `CREATE INDEX IF NOT EXISTS submission_attempts_idx ON submission_attempts (ip_hash, created_at DESC)`,
  `CREATE TABLE IF NOT EXISTS ads (
     id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
     status       text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused')),
     placement    text NOT NULL DEFAULT 'minigolf_scoring',
     course_slug  text NOT NULL DEFAULT '',
     title        text NOT NULL,
     subtitle     text NOT NULL DEFAULT '',
     image_url    text NOT NULL DEFAULT '',
     link_url     text NOT NULL DEFAULT '',
     advertiser   text NOT NULL DEFAULT '',
     weight       integer NOT NULL DEFAULT 1 CHECK (weight BETWEEN 1 AND 100),
     starts_on    date,
     ends_on      date,
     admin_notes  text NOT NULL DEFAULT '',
     -- Kam der Eintrag über das Formular auf /werbung, steht hier, wer ihn
     -- geschickt hat. Von Hand angelegte Anzeigen lassen die Felder leer.
     source          text NOT NULL DEFAULT 'admin',
     submitter_name  text NOT NULL DEFAULT '',
     submitter_email text NOT NULL DEFAULT '',
     submitter_phone text NOT NULL DEFAULT '',
     request_note    text NOT NULL DEFAULT '',
     created_at   timestamptz NOT NULL DEFAULT now(),
     updated_at   timestamptz NOT NULL DEFAULT now()
   )`,
  // Nachgereichte Spalten. `CREATE TABLE IF NOT EXISTS` fasst eine bestehende
  // Tabelle nicht mehr an – neue Felder brauchen deshalb immer ein eigenes
  // ALTER, sonst fehlen sie überall dort, wo die Tabelle schon steht.
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS source          text NOT NULL DEFAULT 'admin'`,
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS submitter_name  text NOT NULL DEFAULT ''`,
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS submitter_email text NOT NULL DEFAULT ''`,
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS submitter_phone text NOT NULL DEFAULT ''`,
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS request_note    text NOT NULL DEFAULT ''`,
  // Umkreis statt einzelner Platz: Der Werbende gibt an, wo er sitzt und wie
  // weit die Anzeige reichen soll. Welche Plätze das trifft, rechnet das
  // Gerät aus – es kennt die Koordinaten des Platzes, auf dem gespielt wird.
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS latitude        double precision`,
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS longitude       double precision`,
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS radius_km       integer`,
  // Was der Werbende sich gewünscht hat. Die tatsächliche Laufzeit setzt das
  // Adminpanel in starts_on/ends_on – erst nach Rückfrage und Preis.
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS requested_months integer`,
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS place_name      text NOT NULL DEFAULT ''`,
  // Richtpreis, den das Formular beim Absenden genannt hat (netto, Cent) – für
  // die ganze Anfrage, steht deshalb bei beiden Entwürfen derselbe Betrag.
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS quoted_monthly_cents integer`,
  `ALTER TABLE ads ADD COLUMN IF NOT EXISTS quoted_total_cents   integer`,
  `CREATE INDEX IF NOT EXISTS ads_status_placement_idx ON ads (status, placement)`,
  `CREATE INDEX IF NOT EXISTS ads_course_slug_idx ON ads (course_slug)`,
  // Reichweite pro Anzeige und Tag. Bewusst nur Zähler – keine Gerätekennung,
  // keine Adresse, nichts, was auf eine Person zurückführt.
  `CREATE TABLE IF NOT EXISTS ad_stats (
     ad_id       uuid NOT NULL REFERENCES ads(id) ON DELETE CASCADE,
     day         date NOT NULL,
     impressions bigint NOT NULL DEFAULT 0,
     clicks      bigint NOT NULL DEFAULT 0,
     PRIMARY KEY (ad_id, day)
   )`,
  // Wer erfahren will, wann die Android-App im Play Store steht. Erst nach
  // Eingabe des per Mail geschickten Codes gilt eine Adresse als bestätigt –
  // nur an bestätigte geht später die Nachricht. Der Code liegt nur gehasht hier.
  `CREATE TABLE IF NOT EXISTS android_waitlist (
     id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
     email             text NOT NULL UNIQUE,
     lang              text NOT NULL DEFAULT 'de',
     code_hash         text,
     code_expires_at   timestamptz,
     code_attempts     integer NOT NULL DEFAULT 0,
     codes_sent        integer NOT NULL DEFAULT 0,
     confirmed_at      timestamptz,
     notified_at       timestamptz,
     unsubscribe_token text NOT NULL,
     created_at        timestamptz NOT NULL DEFAULT now()
   )`,
  // Sperrfrist zwischen zwei Code-Mails an dieselbe Adresse.
  `ALTER TABLE android_waitlist ADD COLUMN IF NOT EXISTS last_code_sent_at timestamptz`,
  // Freiwillige Einwilligung in Neuigkeiten und Angebote per Mail. Gilt erst
  // mit der Bestätigung durch den Code (dann steht der Zeitpunkt hier).
  `ALTER TABLE android_waitlist ADD COLUMN IF NOT EXISTS marketing_consent boolean NOT NULL DEFAULT false`,
  `ALTER TABLE android_waitlist ADD COLUMN IF NOT EXISTS marketing_consent_at timestamptz`,
  // Update-Hinweise: neue APK-Fassung per Mail. Teil des Zwecks, für den man
  // sich einträgt; die zuletzt gemeldete Fassung verhindert doppelte Mails.
  `ALTER TABLE android_waitlist ADD COLUMN IF NOT EXISTS apk_updates boolean NOT NULL DEFAULT true`,
  `ALTER TABLE android_waitlist ADD COLUMN IF NOT EXISTS last_update_version integer NOT NULL DEFAULT 0`,
  // Lobby: Freunde spielen jeder auf dem eigenen iPhone und sehen sich
  // gegenseitig Schläge und – wenn eingeschaltet – den Standort. Kurzlebig:
  // `lib/lobby.ts` räumt Lobbys nach einem Tag ohne Lebenszeichen weg.
  `CREATE TABLE IF NOT EXISTS lobbies (
     code         text PRIMARY KEY,
     course_name  text NOT NULL DEFAULT '',
     course_slug  text NOT NULL DEFAULT '',
     holes        integer NOT NULL DEFAULT 18,
     tracking     boolean NOT NULL DEFAULT true,
     created_at   timestamptz NOT NULL DEFAULT now(),
     updated_at   timestamptz NOT NULL DEFAULT now()
   )`,
  // Das Zugangs-Token liegt nur gehasht hier. Standort nur, solange die
  // Lobby besteht – mit ihr wird er gelöscht.
  `CREATE TABLE IF NOT EXISTS lobby_members (
     id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
     code           text NOT NULL REFERENCES lobbies(code) ON DELETE CASCADE,
     token_hash     text NOT NULL UNIQUE,
     name           text NOT NULL,
     is_host        boolean NOT NULL DEFAULT false,
     current_hole   integer NOT NULL DEFAULT 0,
     scores         jsonb NOT NULL DEFAULT '[]'::jsonb,
     share_location boolean NOT NULL DEFAULT true,
     latitude       double precision,
     longitude      double precision,
     accuracy       double precision,
     location_at    timestamptz,
     joined_at      timestamptz NOT NULL DEFAULT now(),
     seen_at        timestamptz NOT NULL DEFAULT now()
   )`,
  `CREATE INDEX IF NOT EXISTS lobby_members_code_idx ON lobby_members (code)`,
  // Weiterempfehlung (`lib/referral.ts`): je Gerät ein Einladungscode; jedes
  // eingeladene Gerät zählt genau einmal. Gerätekennungen nur gehasht.
  `CREATE TABLE IF NOT EXISTS referrers (
     code         text PRIMARY KEY,
     device_hash  text NOT NULL UNIQUE,
     reward_code  text,
     reward_at    timestamptz,
     created_at   timestamptz NOT NULL DEFAULT now()
   )`,
  `CREATE TABLE IF NOT EXISTS referral_claims (
     device_hash   text PRIMARY KEY,
     referrer_code text NOT NULL REFERENCES referrers(code) ON DELETE CASCADE,
     created_at    timestamptz NOT NULL DEFAULT now()
   )`,
  `CREATE INDEX IF NOT EXISTS referral_claims_referrer_idx ON referral_claims (referrer_code)`,
  // Vorrat an Apple-Einmalcodes „2 Wochen Pro“, geladen per deploy/referral-codes.sh.
  `CREATE TABLE IF NOT EXISTS referral_reward_codes (
     code         text PRIMARY KEY,
     assigned_to  text REFERENCES referrers(code) ON DELETE SET NULL,
     assigned_at  timestamptz
   )`,
  // Fehlermeldungen zu einem Platz („Fehler melden“ auf Liste und Platzseite).
  // Jede Meldung geht zusätzlich per Mail raus; die Tabelle hält sie fest,
  // falls der Versand scheitert.
  `CREATE TABLE IF NOT EXISTS course_reports (
     id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
     course_slug    text NOT NULL,
     course_name    text NOT NULL DEFAULT '',
     category       text NOT NULL,
     message        text NOT NULL,
     reporter_name  text NOT NULL DEFAULT '',
     reporter_email text NOT NULL DEFAULT '',
     reporter_role  text NOT NULL DEFAULT '',
     mailed         boolean NOT NULL DEFAULT false,
     created_at     timestamptz NOT NULL DEFAULT now()
   )`,
  `CREATE INDEX IF NOT EXISTS course_reports_created_idx ON course_reports (created_at DESC)`,
  // Crowd-Positionen (`lib/courseGeometry.ts`): Abschlag und Grün je Loch,
  // aus den Runden der Spieler abgeleitet, die das in der App erlaubt haben.
  // Bewusst ohne Geräte-, Runden- oder Netzkennung und nur mit dem Tag –
  // ein Beitrag ist ein Punkt auf dem Platz, nichts, was auf jemanden
  // zurückführt. Je Punkt bleiben nur die jüngsten 30, keiner länger als ein Jahr.
  `CREATE TABLE IF NOT EXISTS geometry_contributions (
     id             bigserial PRIMARY KEY,
     course_slug    text NOT NULL,
     hole           integer NOT NULL,
     kind           text NOT NULL CHECK (kind IN ('tee', 'green')),
     tee_color      text NOT NULL DEFAULT '',
     latitude       double precision NOT NULL,
     longitude      double precision NOT NULL,
     contributed_on date NOT NULL DEFAULT current_date
   )`,
  `CREATE INDEX IF NOT EXISTS geometry_contributions_point_idx
     ON geometry_contributions (course_slug, hole, kind, tee_color, id DESC)`,
  // Das Ergebnis je Punkt und was daraus wurde. `applied_*` ist der Wert, den
  // die Crowd zuletzt in `hole_data` geschrieben (oder bestätigt) hat – steht
  // dort noch genau das, darf sie ihn weiter verbessern; hat ihn jemand von
  // Hand geändert, gilt er als geprüft. `previous_*` hält fest, was vor dem
  // ersten Eintrag dort stand.
  `CREATE TABLE IF NOT EXISTS course_geometry (
     course_slug   text NOT NULL,
     hole          integer NOT NULL,
     kind          text NOT NULL CHECK (kind IN ('tee', 'green')),
     tee_color     text NOT NULL DEFAULT '',
     latitude      double precision NOT NULL,
     longitude     double precision NOT NULL,
     contributors  integer NOT NULL,
     spread_m      double precision NOT NULL,
     status        text NOT NULL CHECK (status IN ('applied', 'kept', 'conflict')),
     applied_lat   double precision,
     applied_lon   double precision,
     previous_lat  double precision,
     previous_lon  double precision,
     updated_at    timestamptz NOT NULL DEFAULT now(),
     PRIMARY KEY (course_slug, hole, kind, tee_color)
   )`,
  // Anonyme Rundenstatistik für Platzbetreiber (`lib/roundStats.ts`), nur mit
  // Einwilligung des Spielers. Bewusst ohne Geräte-, Runden- oder Netzkennung,
  // ohne Namen und ohne Eingangszeitpunkt – nur Spieltag und Tagesabschnitt.
  // Rohzeilen bleiben gut ein Jahr; angezeigt wird nur als Summe ab 10 Runden.
  `CREATE TABLE IF NOT EXISTS round_stats (
     id            bigserial PRIMARY KEY,
     course_slug   text NOT NULL,
     kind          text NOT NULL CHECK (kind IN ('golf', 'minigolf')),
     played_on     date NOT NULL,
     slot          text NOT NULL CHECK (slot IN ('morning', 'midday', 'afternoon', 'evening')),
     weekday       smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7),
     holes_played  smallint NOT NULL,
     duration_min  smallint,
     tee_color     text NOT NULL DEFAULT '',
     players       smallint NOT NULL,
     strokes       jsonb NOT NULL,
     putts         jsonb,
     source        text NOT NULL CHECK (source IN ('app', 'clip', 'web'))
   )`,
  `CREATE INDEX IF NOT EXISTS round_stats_course_idx ON round_stats (course_slug, played_on)`,
  // Betreiberkonten (`lib/operators.ts`): Zugang zu operator.golftrack.app.
  // Das Passwort liegt nur als scrypt-Hash hier. `permissions` sagt, welche
  // Bausteine der Statistik das Konto sieht (siehe OPERATOR_SECTIONS).
  `CREATE TABLE IF NOT EXISTS operators (
     id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
     name                text NOT NULL,
     email               text NOT NULL UNIQUE,
     password_hash       text NOT NULL,
     permissions         text[] NOT NULL DEFAULT '{}',
     active              boolean NOT NULL DEFAULT true,
     notes               text NOT NULL DEFAULT '',
     created_at          timestamptz NOT NULL DEFAULT now(),
     password_changed_at timestamptz NOT NULL DEFAULT now(),
     last_login_at       timestamptz
   )`,
  // Welche Plätze ein Betreiber sieht – beliebig viele je Konto.
  `CREATE TABLE IF NOT EXISTS operator_courses (
     operator_id  uuid NOT NULL REFERENCES operators(id) ON DELETE CASCADE,
     course_slug  text NOT NULL,
     PRIMARY KEY (operator_id, course_slug)
   )`,
  `CREATE INDEX IF NOT EXISTS operator_courses_slug_idx ON operator_courses (course_slug)`,
];

let ready: Promise<void> | null = null;

export function ensureSchema(): Promise<void> {
  ready ??= (async () => {
    for (const statement of STATEMENTS) {
      await query(statement);
    }
  })();
  return ready;
}
