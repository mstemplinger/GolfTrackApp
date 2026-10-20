import "server-only";

/**
 * HTML-Gerüst für die Mails von golftrack.app.
 *
 * Tabellen-Layout mit Inline-Styles, weil Mailprogramme (Outlook, Gmail)
 * kaum CSS können. Das Logo hängt als eingebettetes Bild an (`cid:logo`) –
 * entfernte Bilder blenden viele Programme erst nach Rückfrage ein.
 * Farben wie auf der Website: Nachtgrün, Messing, Creme.
 */

export const LOGO_CID = "logo@golftrack.app";

const NIGHT = "#0e2718";
const CARD = "#163421";
const BRASS = "#c9a035";
const CREAM = "#f2ede3";
const MUTED = "#9fb3a6";

function esc(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

export type EmailContent = {
  lang: "de" | "en";
  /** Vorschauzeile im Posteingang. */
  preheader: string;
  title: string;
  paragraphs: string[];
  /** Sechsstelliger Code, groß hervorgehoben. */
  code?: string;
  codeHint?: string;
  button?: { label: string; url: string };
  /** Kleiner Hinweis unter dem Hauptteil. */
  note?: string;
  unsubscribeUrl: string;
};

export function renderEmail(c: EmailContent): string {
  const de = c.lang === "de";
  const codeBlock = c.code
    ? `<tr><td style="padding:8px 40px 4px">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${NIGHT};border:1px solid ${BRASS}55;border-radius:14px">
          <tr><td align="center" style="padding:22px 12px 6px;font-family:'SF Mono',Menlo,Consolas,monospace;font-size:36px;font-weight:700;letter-spacing:12px;color:${BRASS}">${esc(c.code)}</td></tr>
          ${c.codeHint ? `<tr><td align="center" style="padding:0 12px 18px;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:13px;color:${MUTED}">${esc(c.codeHint)}</td></tr>` : ""}
        </table>
      </td></tr>`
    : "";
  const button = c.button
    ? `<tr><td align="center" style="padding:16px 40px 8px">
        <a href="${esc(c.button.url)}" style="display:inline-block;background:${BRASS};color:${NIGHT};font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:16px;font-weight:700;text-decoration:none;padding:14px 28px;border-radius:999px">${esc(c.button.label)}</a>
      </td></tr>`
    : "";
  const paragraphs = c.paragraphs
    .map(
      (p) =>
        `<tr><td style="padding:0 40px 14px;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:16px;line-height:1.55;color:${CREAM}">${esc(p)}</td></tr>`,
    )
    .join("");
  const note = c.note
    ? `<tr><td style="padding:14px 40px 0;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:13px;line-height:1.5;color:${MUTED}">${esc(c.note)}</td></tr>`
    : "";

  return `<!doctype html>
<html lang="${c.lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="dark light">
<meta name="supported-color-schemes" content="dark light">
<title>${esc(c.title)}</title>
</head>
<body style="margin:0;padding:0;background:${NIGHT}">
<div style="display:none;max-height:0;overflow:hidden;opacity:0">${esc(c.preheader)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${NIGHT}">
  <tr><td align="center" style="padding:32px 16px">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px">
      <tr><td align="center" style="padding:0 0 24px">
        <table role="presentation" cellpadding="0" cellspacing="0"><tr>
          <td style="padding-right:12px"><img src="cid:${LOGO_CID}" width="44" height="44" alt="" style="display:block;border-radius:11px"></td>
          <td style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:24px;font-weight:800;letter-spacing:-0.5px;color:${CREAM}">Golf<span style="color:${BRASS}">Track</span></td>
        </tr></table>
      </td></tr>
      <tr><td style="background:${CARD};border-radius:20px;border-top:3px solid ${BRASS}">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
          <tr><td style="padding:36px 40px 16px;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:24px;line-height:1.25;font-weight:700;color:${CREAM}">${esc(c.title)}</td></tr>
          ${paragraphs}
          ${codeBlock}
          ${button}
          ${note}
          <tr><td style="padding:32px 0 0"></td></tr>
        </table>
      </td></tr>
      <tr><td align="center" style="padding:24px 24px 0;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:12px;line-height:1.6;color:${MUTED}">
        GolfTrack · <a href="https://golftrack.app" style="color:${MUTED}">golftrack.app</a><br>
        ${de ? "Scorekarte, Handicap und Laufspur für iPhone und Android." : "Scorecard, handicap and walking track for iPhone and Android."}<br>
        <a href="${esc(c.unsubscribeUrl)}" style="color:${BRASS}">${de ? "Abmelden" : "Unsubscribe"}</a>
        · <a href="https://golftrack.app/${de ? "impressum" : "en/legal-notice"}" style="color:${MUTED}">${de ? "Impressum" : "Legal notice"}</a>
        · <a href="https://golftrack.app/${de ? "datenschutz" : "en/privacy"}" style="color:${MUTED}">${de ? "Datenschutz" : "Privacy"}</a>
      </td></tr>
    </table>
  </td></tr>
</table>
</body>
</html>`;
}
