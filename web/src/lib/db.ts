import "server-only";

/**
 * Duenner Datenbank-Layer ueber Postgres.
 *
 * Die Adresse steht in `DATABASE_URL`. Auf dem Server liegt sie in
 * `/var/www/golftrack/.env.production`, lokal in `.env.local`.
 */

type Row = Record<string, unknown>;

interface Driver {
  query<T extends Row>(text: string, params?: unknown[]): Promise<T[]>;
}

let driverPromise: Promise<Driver> | null = null;

async function createDriver(): Promise<Driver> {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error(
      "DATABASE_URL fehlt. Ohne Datenbank kann die Seite keine Plaetze lesen oder schreiben.",
    );
  }

  const { default: postgres } = await import("postgres");
  const isLocal = url.includes("localhost") || url.includes("127.0.0.1");
  const sql = postgres(url, {
    // Die Datenbank liegt auf derselben Maschine – dort ist TLS unnoetig.
    ssl: isLocal ? false : "require",
    max: 5,
    idle_timeout: 20,
    connect_timeout: 10,
  });

  return {
    async query<T extends Row>(text: string, params: unknown[] = []) {
      const rows = await sql.unsafe(text, params as never);
      return rows as unknown as T[];
    },
  };
}

function driver(): Promise<Driver> {
  driverPromise ??= createDriver();
  return driverPromise;
}

export async function query<T extends Row>(text: string, params: unknown[] = []): Promise<T[]> {
  const d = await driver();
  return d.query<T>(text, params);
}

export async function queryOne<T extends Row>(text: string, params: unknown[] = []): Promise<T | null> {
  const rows = await query<T>(text, params);
  return rows[0] ?? null;
}
