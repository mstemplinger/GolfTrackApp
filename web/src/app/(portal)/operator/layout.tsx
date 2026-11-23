import Link from "next/link";
import { currentOperator } from "@/lib/operatorAuth";
import { operatorT } from "@/lib/operatorLang";
import { LangSwitch } from "./LangSwitch";
import { LogoutButton } from "./LogoutButton";

/**
 * Rahmen des Betreiber-Portals (operator.golftrack.app). Links ohne
 * /operator-Vorsilbe – der Proxy schreibt sie auf der Subdomain um.
 */
export default async function OperatorLayout({ children }: { children: React.ReactNode }) {
  const [op, { lang, t }] = await Promise.all([currentOperator(), operatorT()]);

  return (
    <div className="min-h-screen bg-night text-cream">
      <header className="sticky top-0 z-20 border-b border-white/10 bg-night/95 backdrop-blur">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-5 sm:px-8">
          <Link href="/" className="flex min-w-0 items-baseline gap-2">
            <span className="font-display text-xl font-semibold tracking-tight">
              Golf<span className="text-brass">Track</span>
            </span>
            {/* Am schmalen Handy fehlt der Platz – dort sagen Reiter und „Meine Plätze“, wo man ist. */}
            <span className="hidden text-xs uppercase tracking-[0.2em] text-cream/45 min-[400px]:inline">{t.portal}</span>
          </Link>
          <div className="flex shrink-0 items-center gap-2 text-sm sm:gap-3">
            {op ? (
              <Link
                href="/account"
                className="hidden max-w-48 truncate text-cream/70 transition-colors hover:text-brass sm:block"
                title={t.account.nav}
              >
                {op.name}
              </Link>
            ) : null}
            {op ? (
              <Link
                href="/account"
                aria-label={t.account.nav}
                title={t.account.nav}
                className="grid size-11 place-items-center rounded-lg text-cream/70 transition-colors hover:text-brass sm:hidden"
              >
                <svg aria-hidden viewBox="0 0 20 20" className="size-5" fill="none" stroke="currentColor" strokeWidth="1.6">
                  <circle cx="10" cy="7" r="3.25" />
                  <path d="M3.75 16.5c.9-3 3.3-4.5 6.25-4.5s5.35 1.5 6.25 4.5" strokeLinecap="round" />
                </svg>
              </Link>
            ) : null}
            <LangSwitch lang={lang} />
            {op ? <LogoutButton label={t.signOut} /> : null}
          </div>
        </div>
      </header>
      <main>{children}</main>
    </div>
  );
}
