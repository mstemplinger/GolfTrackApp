import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { Privacy } from "@/views/Legal";

export const metadata: Metadata = pageMetadata("de", "privacy", {
  title: `${t("de").legal.privacyTitle} · GolfTrack`,
});

export default function Page() {
  return <Privacy lang="de" />;
}
