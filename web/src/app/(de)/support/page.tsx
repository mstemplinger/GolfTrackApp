import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { Support } from "@/views/Support";

export const metadata: Metadata = pageMetadata("de", "support", {
  title: `${t("de").support.title} · GolfTrack`,
  description: t("de").support.lead,
});

export default function Page() {
  return <Support lang="de" />;
}
