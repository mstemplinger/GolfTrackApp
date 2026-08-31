import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { Submit } from "@/views/Submit";

export const metadata: Metadata = pageMetadata("en", "submit", {
  title: `${t("en").submit.title} · GolfTrack`,
  description: t("en").submit.lead,
});

export default function Page() {
  return <Submit lang="en" />;
}
