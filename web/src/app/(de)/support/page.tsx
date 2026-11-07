import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { JsonLd, faqSchema } from "@/components/JsonLd";
import { Support } from "@/views/Support";

export const metadata: Metadata = pageMetadata("de", "support", {
  title: `${t("de").support.title} · GolfTrack`,
  description: t("de").support.lead,
});

export default function Page() {
  return (
    <>
      <JsonLd data={faqSchema("de")} />
      <Support lang="de" />
    </>
  );
}
