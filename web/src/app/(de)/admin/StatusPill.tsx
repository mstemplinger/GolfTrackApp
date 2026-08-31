import type { CourseKind, CourseStatus } from "@/lib/schema";

const STATUS_LABEL: Record<CourseStatus, string> = {
  pending: "offen",
  approved: "freigegeben",
  rejected: "abgelehnt",
};

const STATUS_STYLE: Record<CourseStatus, string> = {
  pending: "border-brass/50 text-brass",
  approved: "border-fairway/60 text-[#5fbe86]",
  rejected: "border-cream/20 text-cream/65",
};

export function StatusPill({ status, kind }: { status: CourseStatus; kind?: CourseKind }) {
  return (
    <span className="flex items-center gap-2">
      {kind ? (
        <span className="rounded-full border border-cream/15 px-2.5 py-0.5 font-mono text-[0.65rem] uppercase tracking-[0.12em] text-cream/65">
          {kind === "golf" ? "Golf" : "Minigolf"}
        </span>
      ) : null}
      <span
        className={`rounded-full border px-2.5 py-0.5 font-mono text-[0.65rem] uppercase tracking-[0.12em] ${STATUS_STYLE[status]}`}
      >
        {STATUS_LABEL[status]}
      </span>
    </span>
  );
}
