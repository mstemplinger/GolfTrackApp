"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { Icon, type IconName } from "./ui";

const NAV: {
  href: string;
  label: string;
  icon: IconName;
  match: (p: string) => boolean;
}[] = [
  {
    href: "/admin",
    label: "Übersicht",
    icon: "home",
    match: (p) => p === "/admin",
  },
  {
    href: "/admin/anlagen",
    label: "Anlagen",
    icon: "flag",
    // Detailseiten einer Anlage liegen unter /admin/<id>.
    match: (p) => p.startsWith("/admin/anlagen") || /^\/admin\/(?!werbung|statistik|anlagen|betreiber)[^/]+$/.test(p),
  },
  {
    href: "/admin/werbung",
    label: "Werbung",
    icon: "megaphone",
    match: (p) => p.startsWith("/admin/werbung"),
  },
  {
    href: "/admin/statistik",
    label: "Statistik",
    icon: "chart",
    match: (p) => p.startsWith("/admin/statistik"),
  },
  {
    href: "/admin/betreiber",
    label: "Betreiber",
    icon: "users",
    match: (p) => p.startsWith("/admin/betreiber"),
  },
];

/**
 * Seitenleiste des Adminpanels. Ab `lg` fest links, darunter hinter einem
 * Menüknopf in der Kopfzeile – wie bei toob360. Der Abmelde-Knopf kommt als
 * Server-Formular von außen (`footer`).
 */
export function AdminSidebar({ footer }: { footer: React.ReactNode }) {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  const nav = (
    <div className="flex h-full flex-col">
      <div className="px-6 pb-6 pt-7">
        <Link href="/admin" className="block" onClick={() => setOpen(false)}>
          <span className="font-display text-2xl font-semibold tracking-tight">
            Golf<span className="text-brass">Track</span>
          </span>
          <span className="mt-1 block text-[11px] uppercase tracking-[0.22em] text-cream/45">Admin-Portal</span>
        </Link>
      </div>
      <nav className="flex-1 space-y-1 px-3" aria-label="Bereiche">
        {NAV.map((item) => {
          const active = item.match(pathname);
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setOpen(false)}
              aria-current={active ? "page" : undefined}
              className={`flex items-center gap-3 rounded-lg border px-3.5 py-2.5 text-[15px] transition-colors ${
                active
                  ? "border-brass/50 bg-brass/[0.09] text-brass"
                  : "border-transparent text-cream/75 hover:bg-white/[0.04] hover:text-cream"
              }`}
            >
              <Icon name={item.icon} className="h-[18px] w-[18px]" />
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="border-t border-white/10 px-3 py-4">
        <a
          href="/"
          target="_blank"
          rel="noreferrer"
          className="flex items-center gap-3 rounded-lg px-3.5 py-2.5 text-sm text-cream/65 transition-colors hover:bg-white/[0.04] hover:text-cream"
        >
          <Icon name="external" className="h-[18px] w-[18px]" />
          Zur Website
        </a>
        {footer}
      </div>
    </div>
  );

  return (
    <>
      {/* Breite Fenster: feste Leiste */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 border-r border-white/10 bg-[#0b1d12] lg:block">
        {nav}
      </aside>

      {/* Schmal: Kopfzeile mit Menüknopf, Leiste als Schublade */}
      <div className="sticky top-0 z-30 flex items-center gap-3 border-b border-white/10 bg-night/95 px-4 py-3 backdrop-blur lg:hidden">
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="rounded-lg p-2 text-cream/80 hover:bg-white/[0.06]"
          aria-label="Menü öffnen"
          aria-expanded={open}
        >
          <Icon name="menu" />
        </button>
        <span className="font-display text-lg font-semibold">
          Golf<span className="text-brass">Track</span> <span className="text-sm font-normal text-cream/45">Admin</span>
        </span>
      </div>
      {open ? (
        <div className="fixed inset-0 z-40 lg:hidden">
          <button
            type="button"
            className="absolute inset-0 bg-black/60"
            aria-label="Menü schließen"
            onClick={() => setOpen(false)}
          />
          <aside className="absolute inset-y-0 left-0 w-72 max-w-[85%] border-r border-white/10 bg-[#0b1d12] shadow-2xl">
            <button
              type="button"
              onClick={() => setOpen(false)}
              className="absolute right-3 top-6 rounded-lg p-2 text-cream/60 hover:bg-white/[0.06]"
              aria-label="Menü schließen"
            >
              <Icon name="close" />
            </button>
            {nav}
          </aside>
        </div>
      ) : null}
    </>
  );
}
