import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { Android } from "@/views/Android";

export const metadata: Metadata = pageMetadata("en", "android", {
  title: `${t("en").android.title} · GolfTrack`,
  description: t("en").android.lead,
});

export default function Page() {
  return <Android lang="en" />;
}
