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
          <Link href="/" className="flex items-baseline gap-2">
            <span className="font-display text-xl font-semibold tracking-tight">
              Golf<span className="text-brass">Track</span>
            </span>
            <span className="text-xs uppercase tracking-[0.2em] text-cream/45">{t.portal}</span>
          </Link>
          <div className="flex items-center gap-3 text-sm">
            {op ? <span className="hidden truncate text-cream/60 sm:block">{op.name}</span> : null}
            <LangSwitch lang={lang} />
            {op ? <LogoutButton label={t.signOut} /> : null}
          </div>
        </div>
      </header>
      <main>{children}</main>
    </div>
  );
}
