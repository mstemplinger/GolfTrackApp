import "server-only";
import { query, queryOne } from "./db";
import { ensureSchema } from "./migrations";
import type { AdInput, AdPlacement, AdRequestInput, AdStatus } from "./schema";

/**
 * Werbung für den freien Platz unter den Spielernamen in der Minigolfkarte.
 *
 * Ein Eintrag ist entweder an eine Anlage gebunden (`courseSlug`) oder gilt
 * überall. Die App lädt alle aktiven Anzeigen und sucht sich vor Ort die
 * passende – so funktioniert der Slot auch ohne Netz weiter.
 */

export interface AdRecord {
  id: string;
  status: AdStatus;
  placement: AdPlacement;
  courseSlug: string;
  title: string;
  subtitle: string;
  imageURL: string;
  linkURL: string;
  advertiser: string;
  weight: number;
  startsOn: string | null;
  endsOn: string | null;
  adminNotes: string;
  /** `admin` = von Hand angelegt, `form` = über /werbung eingegangen. */
  source: string;
  submitterName: string;
  submitterEmail: string;
  submitterPhone: string;
  requestNote: string;
  createdAt: string;
  updatedAt: string;
}

export interface AdWithReach extends AdRecord {
  impressions: number;
  clicks: number;
}

type DbRow = Record<string, unknown>;

const asString = (v: unknown) => (v == null ? "" : String(v));
/** Nur der Tag, ohne Zeitzonenrechnerei – `date` kommt je nach Treiber anders. */
const asDay = (v: unknown) => {
  if (v == null) return null;
  if (v instanceof Date) return v.toISOString().slice(0, 10);
  return String(v).slice(0, 10);
};

function mapRow(row: DbRow): AdRecord {
  return {
    id: asString(row.id),
    status: asString(row.status) as AdStatus,
    placement: asString(row.placement) as AdPlacement,
    courseSlug: asString(row.course_slug),
    title: asString(row.title),
    subtitle: asString(row.subtitle),
    imageURL: asString(row.image_url),
    linkURL: asString(row.link_url),
    advertiser: asString(row.advertiser),
    weight: Number(row.weight ?? 1),
    startsOn: asDay(row.starts_on),
    endsOn: asDay(row.ends_on),
    adminNotes: asString(row.admin_notes),
    source: asString(row.source),
    submitterName: asString(row.submitter_name),
    submitterEmail: asString(row.submitter_email),
    submitterPhone: asString(row.submitter_phone),
    requestNote: asString(row.request_note),
    createdAt: new Date(asString(row.created_at)).toISOString(),
    updatedAt: new Date(asString(row.updated_at)).toISOString(),
  };
}

function mapRowWithReach(row: DbRow): AdWithReach {
  return {
    ...mapRow(row),
    impressions: Number(row.impressions ?? 0),
    clicks: Number(row.clicks ?? 0),
  };
}

const VALUES = (input: AdInput): unknown[] => [
  input.status,
  input.placement,
  input.courseSlug,
  input.title,
  input.subtitle,
  input.imageURL,
  input.linkURL,
  input.advertiser,
  input.weight,
  input.startsOn,
  input.endsOn,
  input.adminNotes,
];

export async function createAd(input: AdInput): Promise<AdRecord> {
  await ensureSchema();
  const rows = await query<DbRow>(
    `INSERT INTO ads (
       status, placement, course_slug, title, subtitle, image_url, link_url,
       advertiser, weight, starts_on, ends_on, admin_notes
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
     RETURNING *`,
    VALUES(input),
  );
  return mapRow(rows[0]);
}

/**
 * Anfrage vom öffentlichen Formular. Sie landet als Entwurf – nichts geht
 * ungesehen in die App.
 */
export async function createAdRequest(input: AdRequestInput): Promise<AdRecord> {
  await ensureSchema();
  const rows = await query<DbRow>(
    `INSERT INTO ads (
       status, placement, course_slug, title, subtitle, image_url, link_url,
       advertiser, source, submitter_name, submitter_email, submitter_phone, request_note
     ) VALUES ('draft','minigolf_scoring',$1,$2,$3,$4,$5,$6,'form',$7,$8,$9,$10)
     RETURNING *`,
    [
      input.courseSlug,
      input.title,
      input.subtitle,
      input.imageURL,
      input.linkURL,
      input.advertiser,
      input.submitterName,
      input.submitterEmail,
      input.submitterPhone,
      input.requestNote,
    ],
  );
  return mapRow(rows[0]);
}

export async function updateAd(id: string, input: AdInput): Promise<AdRecord | null> {
  await ensureSchema();
  const rows = await query<DbRow>(
    `UPDATE ads SET
       status = $1, placement = $2, course_slug = $3, title = $4, subtitle = $5,
       image_url = $6, link_url = $7, advertiser = $8, weight = $9,
       starts_on = $10, ends_on = $11, admin_notes = $12, updated_at = now()
     WHERE id = $13
     RETURNING *`,
    [...VALUES(input), id],
  );
  return rows[0] ? mapRow(rows[0]) : null;
}

export async function setAdStatus(id: string, status: AdStatus): Promise<AdRecord | null> {
  await ensureSchema();
  const rows = await query<DbRow>(
    "UPDATE ads SET status = $1, updated_at = now() WHERE id = $2 RETURNING *",
    [status, id],
  );
  return rows[0] ? mapRow(rows[0]) : null;
}

export async function deleteAd(id: string): Promise<void> {
  await ensureSchema();
  await query("DELETE FROM ads WHERE id = $1", [id]);
}

export async function getAd(id: string): Promise<AdRecord | null> {
  await ensureSchema();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) return null;
  const row = await queryOne<DbRow>("SELECT * FROM ads WHERE id = $1", [id]);
  return row ? mapRow(row) : null;
}

/** Alle Anzeigen fürs Adminpanel, mit den Zählern der letzten 30 Tage. */
export async function listAds(): Promise<AdWithReach[]> {
  await ensureSchema();
  const rows = await query<DbRow>(
    `SELECT a.*,
            COALESCE(s.impressions, 0) AS impressions,
            COALESCE(s.clicks, 0)      AS clicks
       FROM ads a
       LEFT JOIN (
         SELECT ad_id,
                SUM(impressions) AS impressions,
                SUM(clicks)      AS clicks
           FROM ad_stats
          WHERE day > current_date - 30
          GROUP BY ad_id
       ) s ON s.ad_id = a.id
      ORDER BY
        CASE a.status WHEN 'active' THEN 0 WHEN 'draft' THEN 1 ELSE 2 END,
        a.created_at DESC
      LIMIT 500`,
  );
  return rows.map(mapRowWithReach);
}

/** Zähler einer einzelnen Anzeige, Tag für Tag – die Grundlage jeder Abrechnung. */
export async function adReach(
  id: string,
  days = 30,
): Promise<{ total: { impressions: number; clicks: number }; daily: { day: string; impressions: number; clicks: number }[] }> {
  await ensureSchema();
  const rows = await query<DbRow>(
    `SELECT day, impressions, clicks
       FROM ad_stats
      WHERE ad_id = $1 AND day > current_date - $2::integer
      ORDER BY day DESC`,
    [id, days],
  );
  const daily = rows.map((row) => ({
    day: asDay(row.day) ?? "",
    impressions: Number(row.impressions ?? 0),
    clicks: Number(row.clicks ?? 0),
  }));
  return {
    total: {
      impressions: daily.reduce((sum, entry) => sum + entry.impressions, 0),
      clicks: daily.reduce((sum, entry) => sum + entry.clicks, 0),
    },
    daily,
  };
}

/**
 * Was die App bekommt: aktive Anzeigen, deren Zeitraum heute läuft. Die
 * Auswahl der einzelnen Anzeige trifft das Gerät – es weiß, auf welcher
 * Anlage gerade gespielt wird, auch wenn es gerade kein Netz hat.
 */
export async function listDeliverableAds(placement?: AdPlacement): Promise<AdRecord[]> {
  await ensureSchema();
  const params: unknown[] = [];
  let placementFilter = "";
  if (placement) {
    params.push(placement);
    placementFilter = `AND placement = $${params.length}`;
  }
  const rows = await query<DbRow>(
    `SELECT * FROM ads
      WHERE status = 'active'
        ${placementFilter}
        AND (starts_on IS NULL OR starts_on <= current_date)
        AND (ends_on   IS NULL OR ends_on   >= current_date)
      ORDER BY course_slug DESC, weight DESC, created_at
      LIMIT 200`,
    params,
  );
  return rows.map(mapRow);
}

/**
 * Einbuchen der gemeldeten Zähler. Unbekannte Kennungen fallen still weg –
 * eine gelöschte Anzeige soll keine Fehlermeldung an das Gerät zurückgeben.
 */
export async function recordAdEvents(
  events: { id: string; type: "impression" | "click"; count: number }[],
): Promise<void> {
  await ensureSchema();
  for (const event of events) {
    const impressions = event.type === "impression" ? event.count : 0;
    const clicks = event.type === "click" ? event.count : 0;
    await query(
      `INSERT INTO ad_stats (ad_id, day, impressions, clicks)
       SELECT id, current_date, $2::bigint, $3::bigint FROM ads WHERE id = $1
       ON CONFLICT (ad_id, day) DO UPDATE
         SET impressions = ad_stats.impressions + EXCLUDED.impressions,
             clicks      = ad_stats.clicks      + EXCLUDED.clicks`,
      [event.id, impressions, clicks],
    );
  }
}
