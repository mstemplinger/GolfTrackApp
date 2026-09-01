import type { AdStatus } from "@/lib/schema";

const LABEL: Record<AdStatus, string> = {
  draft: "Entwurf",
  active: "aktiv",
  paused: "pausiert",
};

const STYLE: Record<AdStatus, string> = {
  draft: "border-cream/20 text-cream/65",
  active: "border-fairway/60 text-[#5fbe86]",
  paused: "border-brass/50 text-brass",
};

export function AdStatusPill({ status }: { status: AdStatus }) {
  return (
    <span
      className={`rounded-full border px-2.5 py-0.5 font-mono text-[0.65rem] uppercase tracking-[0.12em] ${STYLE[status]}`}
    >
      {LABEL[status]}
    </span>
  );
}
