import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { Privacy } from "@/views/Legal";

export const metadata: Metadata = pageMetadata("en", "privacy", {
  title: `${t("en").legal.privacyTitle} · GolfTrack`,
});

export default function Page() {
  return <Privacy lang="en" />;
}
