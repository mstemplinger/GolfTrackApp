import Link from "next/link";
import type { NameRequest } from "@/lib/courseNameRequests";
import { decideName } from "./nameRequestActions";

/**
 * Offene Namenswünsche von Betreibern – mit Freigeben/Ablehnen. Bei Golf der
 * Hinweis, dass die App gespielte Plätze über den Namen zuordnet.
 */
export function NameRequestList({ requests, showCourse = true }: { requests: NameRequest[]; showCourse?: boolean }) {
  if (!requests.length) return <p className="px-5 py-6 text-sm text-cream/55">Keine offenen Wünsche.</p>;
  return (
    <ul className="divide-y divide-white/[0.07]">
      {requests.map((r) => (
        <li key={r.id} className="px-5 py-4">
          {showCourse ? (
            <Link href={`/admin/${r.courseSlug}`} className="text-xs text-cream/50 hover:text-brass">
              {r.courseName}
            </Link>
          ) : null}
          <p className="mt-1 text-sm">
            <span className="text-cream/55 line-through decoration-cream/30">{r.courseName}</span>{" "}
            <span className="text-cream/45">→</span> <strong className="text-cream">{r.requestedName}</strong>
          </p>
          <p className="mt-1 text-xs text-cream/45">
            von {r.operatorName || "Betreiber"} · {new Date(r.createdAt).toLocaleDateString("de-DE")}
          </p>
          {r.courseKind === "golf" ? (
            <p className="mt-2 text-xs leading-relaxed text-[#e0c583]">
              Golfplatz: Die iOS-App ordnet schon gespielte Plätze über den Namen zu. Nach der Änderung finden Spieler
              mit dem alten Namen den Platz im Verzeichnis nicht mehr wieder (keine Rundenstatistik/Crowd-Punkte mehr
              von ihnen).
            </p>
          ) : null}
          <form action={decideName} className="mt-3 flex gap-2">
            <input type="hidden" name="id" value={r.id} />
            <button
              type="submit"
              name="decision"
              value="approve"
              className="rounded-lg bg-brass px-3.5 py-1.5 text-sm font-semibold text-night transition-colors hover:bg-brass-soft"
            >
              Freigeben
            </button>
            <button
              type="submit"
              name="decision"
              value="reject"
              className="rounded-lg border border-white/15 px-3.5 py-1.5 text-sm text-cream/75 transition-colors hover:border-[#e07a63]/60 hover:text-[#e07a63]"
            >
              Ablehnen
            </button>
          </form>
        </li>
      ))}
    </ul>
  );
}
