import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { Submit } from "@/views/Submit";

export const metadata: Metadata = pageMetadata("de", "submit", {
  title: `${t("de").submit.title} · GolfTrack`,
  description: t("de").submit.lead,
});

export default function Page() {
  return <Submit lang="de" />;
}
