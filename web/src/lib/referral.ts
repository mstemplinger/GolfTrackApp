import "server-only";
import { createHash, randomInt } from "node:crypto";
import { z } from "zod";
import { query, queryOne } from "./db";
import { ensureSchema } from "./migrations";

/**
 * Weiterempfehlung: Wer die App fünf Freunden empfiehlt, bekommt zwei Wochen
 * GolfTrack Pro geschenkt.
 *
 * Jede App holt sich einen sechsstelligen Einladungscode und teilt den Link
 * `golftrack.app/einladen/<code>`. Ein Freund zählt erst, wenn seine App den
 * Code einlöst – über den Universal Link oder von Hand eingegeben. Jedes Gerät
 * zählt nur ein einziges Mal (bei wem auch immer) und nie für sich selbst.
 * Das Gerät weist sich mit einer zufälligen Kennung aus, die die App im
 * Schlüsselbund aufhebt (übersteht Neuinstallation); hier liegt sie nur gehasht.
 *
 * Die Belohnung ist ein Apple-Einmalcode (2 Wochen gratis, ohne Verlängerung),
 * vorab in `referral_reward_codes` geladen – siehe
 * `marketing/asc-referral-codes.py` und `deploy/referral-codes.sh`.
 */

export const FRIENDS_NEEDED = 5;
/** Apple-ID der App für den Einlöse-Link. */
const APP_STORE_ID = "6767996957";
/** Ohne verwechselbare Zeichen (0/O, 1/I/L) – wird auch von Hand abgetippt. */
const ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

export const referralCodeSchema = z.string().regex(/^[A-HJ-NP-Z2-9]{6}$/);

const deviceSchema = z.string().uuid();

export const statusSchema = z.object({ device: deviceSchema });
export const claimSchema = z.object({ device: deviceSchema });

export interface ReferralStatus {
  code: string;
  friends: number;
  needed: number;
  /** Einmalcode, sobald fünf Freunde dabei sind; `null` solange nicht. */
  rewardCode: string | null;
  rewardUrl: string | null;
  /** Kein Code mehr im Vorrat – die App sagt dann „kommt bald“. */
  rewardPending: boolean;
}

function hashDevice(device: string): string {
  return createHash("sha256").update(`referral:${device.toLowerCase()}`).digest("hex");
}

function newCode(): string {
  let out = "";
  for (let i = 0; i < 6; i++) out += ALPHABET[randomInt(ALPHABET.length)];
  return out;
}

function redeemUrl(code: string): string {
  return `https://apps.apple.com/redeem?ctx=offercodes&id=${APP_STORE_ID}&code=${encodeURIComponent(code)}`;
}

async function referrerFor(deviceHash: string): Promise<{ code: string; reward_code: string | null }> {
  const existing = await queryOne<{ code: string; reward_code: string | null }>(
    `SELECT code, reward_code FROM referrers WHERE device_hash = $1`,
    [deviceHash],
  );
  if (existing) return existing;
  for (let attempt = 0; attempt < 20; attempt++) {
    const created = await queryOne<{ code: string; reward_code: string | null }>(
      `INSERT INTO referrers (code, device_hash) VALUES ($1, $2)
       ON CONFLICT DO NOTHING
       RETURNING code, reward_code`,
      [newCode(), deviceHash],
    );
    if (created) return created;
    // Gleichzeitig angelegt? Dann steht er jetzt da.
    const raced = await queryOne<{ code: string; reward_code: string | null }>(
      `SELECT code, reward_code FROM referrers WHERE device_hash = $1`,
      [deviceHash],
    );
    if (raced) return raced;
  }
  throw new Error("Kein freier Einladungscode gefunden");
}

/** Eigener Code, Zahl der Freunde und – ab fünf – der Geschenkcode. */
export async function referralStatus(device: string): Promise<ReferralStatus> {
  await ensureSchema();
  const referrer = await referrerFor(hashDevice(device));
  const counted = await queryOne<{ n: number }>(
    `SELECT count(*)::int AS n FROM referral_claims WHERE referrer_code = $1`,
    [referrer.code],
  );
  const friends = counted?.n ?? 0;

  let rewardCode = referrer.reward_code;
  if (!rewardCode && friends >= FRIENDS_NEEDED) {
    // Einen Code aus dem Vorrat fest zuteilen – genau einmal je Einladendem.
    const assigned = await queryOne<{ code: string }>(
      `WITH pick AS (
         SELECT code FROM referral_reward_codes
          WHERE assigned_to IS NULL
          ORDER BY code
          LIMIT 1
          FOR UPDATE SKIP LOCKED
       )
       UPDATE referral_reward_codes r
          SET assigned_to = $1, assigned_at = now()
         FROM pick
        WHERE r.code = pick.code
      RETURNING r.code`,
      [referrer.code],
    );
    if (assigned) {
      const stored = await queryOne<{ reward_code: string }>(
        `UPDATE referrers SET reward_code = $2, reward_at = now()
          WHERE code = $1 AND reward_code IS NULL
        RETURNING reward_code`,
        [referrer.code, assigned.code],
      );
      if (stored) {
        rewardCode = stored.reward_code;
      } else {
        // Ein paralleler Aufruf war schneller – den eben gezogenen Code zurücklegen.
        await query(`UPDATE referral_reward_codes SET assigned_to = NULL, assigned_at = NULL WHERE code = $1`, [
          assigned.code,
        ]);
        rewardCode =
          (await queryOne<{ reward_code: string | null }>(`SELECT reward_code FROM referrers WHERE code = $1`, [
            referrer.code,
          ]))?.reward_code ?? null;
      }
    }
  }

  return {
    code: referrer.code,
    friends,
    needed: FRIENDS_NEEDED,
    rewardCode,
    rewardUrl: rewardCode ? redeemUrl(rewardCode) : null,
    rewardPending: !rewardCode && friends >= FRIENDS_NEEDED,
  };
}

export type ClaimResult =
  | { ok: true }
  | { ok: false; error: "not_found" | "own_code" | "already_counted" };

/** Ein Freund löst den Einladungscode ein. */
export async function claimReferral(code: string, device: string): Promise<ClaimResult> {
  await ensureSchema();
  const deviceHash = hashDevice(device);
  const referrer = await queryOne<{ device_hash: string }>(`SELECT device_hash FROM referrers WHERE code = $1`, [code]);
  if (!referrer) return { ok: false, error: "not_found" };
  if (referrer.device_hash === deviceHash) return { ok: false, error: "own_code" };
  const inserted = await queryOne<{ referrer_code: string }>(
    `INSERT INTO referral_claims (device_hash, referrer_code) VALUES ($1, $2)
     ON CONFLICT (device_hash) DO NOTHING
     RETURNING referrer_code`,
    [deviceHash, code],
  );
  return inserted ? { ok: true } : { ok: false, error: "already_counted" };
}

/**
 * Bremse gegen massenhaftes Einlösen mit erfundenen Gerätekennungen. Je Prozess
 * im Speicher, wie bei der Lobby: höchstens 10 Einlösungen je IP und Tag.
 * Genug für eine Gruppe am selben Clubhaus-WLAN.
 */
const claims = new Map<string, { count: number; resetAt: number }>();

export function claimAllowed(request: Request): boolean {
  const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "local";
  const now = Date.now();
  const entry = claims.get(ip);
  if (!entry || entry.resetAt < now) {
    claims.set(ip, { count: 1, resetAt: now + 24 * 60 * 60_000 });
    if (claims.size > 5000) {
      for (const [key, value] of claims) if (value.resetAt < now) claims.delete(key);
    }
    return true;
  }
  entry.count += 1;
  return entry.count <= 10;
}
