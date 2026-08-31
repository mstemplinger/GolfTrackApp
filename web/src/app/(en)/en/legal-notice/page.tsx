import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { Imprint } from "@/views/Legal";

export const metadata: Metadata = pageMetadata("en", "imprint", {
  title: `${t("en").legal.imprintTitle} · GolfTrack`,
});

export default function Page() {
  return <Imprint lang="en" />;
}
