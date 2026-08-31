import { Footer, Header, PageHeader } from "@/components/Chrome";
import { SubmitForm } from "@/views/SubmitForm";
import { t } from "@/i18n/content";
import type { Lang } from "@/i18n/routes";

export function Submit({ lang }: { lang: Lang }) {
  const copy = t(lang).submit;
  return (
    <>
      <Header lang={lang} current="submit" />
      <PageHeader index="11 — Formular" title={copy.title} lead={copy.lead} />
      <main className="mx-auto max-w-6xl px-5 py-14 sm:px-8 sm:py-16">
        <SubmitForm lang={lang} />
      </main>
      <Footer lang={lang} />
    </>
  );
}
