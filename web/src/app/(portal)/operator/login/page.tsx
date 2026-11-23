import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { currentOperator } from "@/lib/operatorAuth";
import { operatorT } from "@/lib/operatorLang";
import { LoginForm } from "./LoginForm";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await operatorT();
  return { title: t.titleLogin, robots: { index: false, follow: false } };
}

export default async function OperatorLoginPage() {
  if (await currentOperator()) redirect("/");
  const { t } = await operatorT();

  return (
    <div className="grid min-h-[calc(100vh-4rem)] place-items-center px-5 py-12">
      <div className="w-full max-w-sm">
        <p className="flex items-center gap-2 text-xs font-medium uppercase tracking-[0.18em] text-brass">
          <span className="h-1.5 w-1.5 rounded-full bg-brass" />
          {t.forOperators}
        </p>
        <h1 className="mt-2 font-display text-3xl tracking-tight">{t.signIn}</h1>
        <p className="mt-2 text-sm leading-relaxed text-cream/60">{t.signInIntro}</p>
        <div className="mt-8">
          <LoginForm
            t={{
              email: t.email,
              password: t.password,
              signIn: t.signIn,
              signingIn: t.signingIn,
              wrongCredentials: t.wrongCredentials,
              locked: t.locked,
            }}
          />
        </div>
        <p className="mt-8 text-xs leading-relaxed text-cream/45">
          {t.noAccess}{" "}
          <a href="mailto:contact@golftrack.app" className="text-brass hover:underline">
            contact@golftrack.app
          </a>
          .
        </p>
      </div>
    </div>
  );
}
