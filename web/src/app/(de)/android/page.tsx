import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { Android } from "@/views/Android";

export const metadata: Metadata = pageMetadata("de", "android", {
  title: `${t("de").android.title} · GolfTrack`,
  description: t("de").android.lead,
});

export default function Page() {
  return <Android lang="de" />;
}
