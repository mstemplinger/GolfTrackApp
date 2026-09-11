import { HINT_EMOJI } from "./HintsEditor";
import type { CourseHint } from "@/lib/schema";

/**
 * Die Hinweise der Anlage, wie sie auf der QR-Landeseite erscheinen –
 * dasselbe, was der App Clip während der Runde zeigt.
 */
export function CourseHintList({ hints }: { hints: CourseHint[] }) {
  if (!hints.length) return null;

  return (
    <ul className="mx-auto mt-10 max-w-lg space-y-px overflow-hidden rounded-sm border rule bg-brass/15 text-left">
      {hints.map((hint, index) => (
        <li key={index} className="flex items-start gap-3 bg-night/85 px-5 py-3.5">
          <span aria-hidden className="text-lg leading-6">
            {HINT_EMOJI[hint.kind] ?? HINT_EMOJI.info}
          </span>
          <span className="text-sm leading-6 text-cream/75">{hint.text}</span>
        </li>
      ))}
    </ul>
  );
}
