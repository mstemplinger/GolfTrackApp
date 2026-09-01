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
     course_rating   double precision,
     slope_rating    integer,
     hole_data       jsonb NOT NULL DEFAULT '[]'::jsonb,
     facility_notes  text NOT NULL DEFAULT '',
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
  `CREATE INDEX IF NOT EXISTS courses_status_kind_idx ON courses (status, kind)`,
  `CREATE INDEX IF NOT EXISTS courses_updated_at_idx ON courses (updated_at DESC)`,
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
