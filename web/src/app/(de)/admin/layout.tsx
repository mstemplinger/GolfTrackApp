import { isAuthenticated } from "@/lib/auth";
import { AdminSidebar } from "./AdminSidebar";
import { logout } from "./actions";
import { Icon } from "./ui";

/**
 * Rahmen des Adminpanels: Seitenleiste links, Inhalt rechts. Ohne Anmeldung
 * nur der Inhalt – dann zeigt `/admin` das Anmeldeformular und alle anderen
 * Seiten leiten selbst dorthin um.
 */
export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  if (!(await isAuthenticated())) return children;

  return (
    <div className="min-h-screen bg-night">
      <AdminSidebar
        footer={
          <form action={logout}>
            <button
              type="submit"
              className="flex w-full items-center gap-3 rounded-lg px-3.5 py-2.5 text-sm text-cream/65 transition-colors hover:bg-white/[0.04] hover:text-cream"
            >
              <Icon name="logout" className="h-[18px] w-[18px]" />
              Abmelden
            </button>
          </form>
        }
      />
      <main className="lg:pl-64">{children}</main>
    </div>
  );
}
