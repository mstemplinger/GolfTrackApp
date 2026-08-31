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
