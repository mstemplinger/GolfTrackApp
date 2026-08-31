import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { ApiDocs } from "@/views/ApiDocs";

export const metadata: Metadata = pageMetadata("de", "api", {
  title: `${t("de").api.title} · GolfTrack`,
  description: t("de").api.lead,
});

export default function Page() {
  return <ApiDocs lang="de" />;
}
