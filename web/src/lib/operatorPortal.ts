/**
 * Wo das Betreiber-Portal erreichbar ist. Auf dem Server die Subdomain,
 * lokal `operator.localhost` (Browser lösen *.localhost von selbst auf).
 * Abweichend über OPERATOR_PORTAL_URL einstellbar.
 */
export const OPERATOR_HOSTS = new Set(["operator.golftrack.app", "operator.localhost"]);

export function operatorPortalUrl(): string {
  if (process.env.OPERATOR_PORTAL_URL) return process.env.OPERATOR_PORTAL_URL.replace(/\/$/, "");
  return process.env.NODE_ENV === "production"
    ? "https://operator.golftrack.app"
    : `http://operator.localhost:${process.env.PORT ?? "3000"}`;
}
