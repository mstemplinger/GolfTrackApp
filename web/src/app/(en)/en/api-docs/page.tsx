import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { ApiDocs } from "@/views/ApiDocs";

export const metadata: Metadata = pageMetadata("en", "api", {
  title: `${t("en").api.title} · GolfTrack`,
  description: t("en").api.lead,
});

export default function Page() {
  return <ApiDocs lang="en" />;
}
