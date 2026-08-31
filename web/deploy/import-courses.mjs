#!/usr/bin/env node
// Traegt die Plaetze aus deploy/courses-seed.json in die Datenbank ein –
// als freigegebene Eintraege, damit sie sofort im Feed /api/v1/courses stehen.
//
// Auf dem Server auszufuehren:
//   cd /var/www/golftrack && node deploy/import-courses.mjs --dry
//   cd /var/www/golftrack && node deploy/import-courses.mjs
//
// Der Lauf ist wiederholbar: bekannte Slugs werden aktualisiert, aber nur,
// wenn sie aus diesem Import stammen (source = 'bundled'). Eintraege aus dem
// oeffentlichen Formular bleiben unangetastet.

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import postgres from "postgres";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const dryRun = process.argv.includes("--dry");
const seedPath = process.argv.find((a) => a.endsWith(".json")) ?? join(here, "courses-seed.json");

/** Gleiche Regel wie src/lib/courses.ts – die Slugs muessen zusammenpassen. */
function slugify(input) {
  return input
    .toLowerCase()
    .replace(/ä/g, "ae")
    .replace(/ö/g, "oe")
    .replace(/ü/g, "ue")
    .replace(/ß/g, "ss")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60);
}

/** DATABASE_URL aus der Umgebung oder aus .env.production daneben. */
function databaseUrl() {
  if (process.env.DATABASE_URL) return process.env.DATABASE_URL;
  for (const name of [".env.production", ".env.local"]) {
    try {
      const text = readFileSync(join(root, name), "utf8");
      const match = text.match(/^\s*DATABASE_URL\s*=\s*(.+)$/m);
      if (match) return match[1].trim().replace(/^["']|["']$/g, "");
    } catch {
      // Datei gibt es nicht – naechste probieren.
    }
  }
  throw new Error("DATABASE_URL fehlt (weder in der Umgebung noch in .env.production).");
}

/**
 * Loecher als ein Datensatz pro Bahn. Eine Spalte wird nur uebernommen, wenn
 * fuer jedes Loch ein Wert vorliegt – halbe Reihen waeren in der App schlimmer
 * als gar keine.
 */
function holeData(course) {
  const n = course.holes;
  const column = (values) => (Array.isArray(values) && values.length === n ? values : null);
  const par = column(course.parValues);
  const hcp = column(course.hcpValues);
  const length = column(course.holeLengths);
  const teeLat = column(course.teeLatitudes);
  const teeLon = column(course.teeLongitudes);
  const flagLat = column(course.flagLatitudes);
  const flagLon = column(course.flagLongitudes);

  if (!par && !hcp && !length && !teeLat && !flagLat) return [];

  return Array.from({ length: n }, (_, i) => ({
    number: i + 1,
    par: par?.[i] ?? null,
    hcp: hcp?.[i] ?? null,
    length: length?.[i] ?? null,
    teeLat: teeLat?.[i] ?? null,
    teeLon: teeLon && teeLat ? (teeLon[i] ?? null) : null,
    flagLat: flagLat?.[i] ?? null,
    flagLon: flagLon && flagLat ? (flagLon[i] ?? null) : null,
  }));
}

/** Slugs vergeben: erst der Name, bei Doppelung Name + Ort, dann nummeriert. */
function assignSlugs(courses) {
  const taken = new Set();
  return courses.map((course) => {
    if (course.slug) {
      taken.add(course.slug);
      return { ...course, slug: course.slug };
    }
    const candidates = [slugify(course.name) || "platz", slugify(`${course.name} ${course.location}`)];
    let slug = candidates.find((c) => c && !taken.has(c));
    if (!slug) {
      const root = candidates[candidates.length - 1] || "platz";
      for (let i = 2; !slug && i < 60; i += 1) if (!taken.has(`${root}-${i}`)) slug = `${root}-${i}`;
    }
    taken.add(slug);
    return { ...course, slug };
  });
}

const courses = assignSlugs(JSON.parse(readFileSync(seedPath, "utf8")));
console.log(`${courses.length} Plaetze aus ${seedPath}`);

const sql = postgres(databaseUrl(), { ssl: false, max: 2, connect_timeout: 10 });

try {
  const created = [];
  const updated = [];
  const skipped = [];

  for (const course of courses) {
    const holes = holeData(course);
    const values = [
      course.slug,
      course.kind,
      course.name,
      course.location ?? "",
      course.country ?? "DE",
      course.holes,
      course.lat ?? null,
      course.lon ?? null,
      course.courseRating ?? null,
      course.slopeRating ?? null,
      JSON.stringify(holes),
      course.facilityNotes ?? "",
      course.welcome ?? "",
    ];

    if (dryRun) {
      const existing = await sql`SELECT source FROM courses WHERE slug = ${course.slug}`;
      if (!existing.length) created.push(course.slug);
      else if (existing[0].source === "bundled") updated.push(course.slug);
      else skipped.push(`${course.slug} (${existing[0].source})`);
      continue;
    }

    const rows = await sql.unsafe(
      `INSERT INTO courses (
         slug, kind, status, name, location, country, holes, latitude, longitude,
         course_rating, slope_rating, hole_data, facility_notes, welcome,
         source, reviewed_at, published_at
       ) VALUES ($1,$2,'approved',$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,$12,$13,'bundled',now(),now())
       ON CONFLICT (slug) DO UPDATE SET
         kind = EXCLUDED.kind,
         status = 'approved',
         name = EXCLUDED.name,
         location = EXCLUDED.location,
         country = EXCLUDED.country,
         holes = EXCLUDED.holes,
         latitude = EXCLUDED.latitude,
         longitude = EXCLUDED.longitude,
         course_rating = EXCLUDED.course_rating,
         slope_rating = EXCLUDED.slope_rating,
         hole_data = EXCLUDED.hole_data,
         facility_notes = EXCLUDED.facility_notes,
         welcome = EXCLUDED.welcome,
         updated_at = now()
       WHERE courses.source = 'bundled'
       RETURNING slug, (xmax = 0) AS inserted`,
      values,
    );

    if (!rows.length) skipped.push(course.slug);
    else if (rows[0].inserted) created.push(rows[0].slug);
    else updated.push(rows[0].slug);
  }

  console.log(`${dryRun ? "[Probelauf] " : ""}neu: ${created.length}, aktualisiert: ${updated.length}, uebersprungen: ${skipped.length}`);
  if (skipped.length) console.log("uebersprungen (fremde Quelle):", skipped.join(", "));

  const [{ count }] = await sql`SELECT count(*)::int AS count FROM courses WHERE status = 'approved'`;
  console.log(`freigegeben in der Datenbank: ${count}`);
} finally {
  await sql.end();
}
