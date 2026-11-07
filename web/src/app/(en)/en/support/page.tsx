import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { JsonLd, faqSchema } from "@/components/JsonLd";
import { Support } from "@/views/Support";

export const metadata: Metadata = pageMetadata("en", "support", {
  title: `${t("en").support.title} · GolfTrack`,
  description: t("en").support.lead,
});

export default function Page() {
  return (
    <>
      <JsonLd data={faqSchema("en")} />
      <Support lang="en" />
    </>
  );
}
