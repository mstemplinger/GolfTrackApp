import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { t } from "@/i18n/content";
import { Directory } from "@/views/Directory";

export const metadata: Metadata = pageMetadata("de", "directory", {
  title: `${t("de").directory.title} · GolfTrack`,
  description: t("de").directory.lead,
});

/** Die Liste kommt aus der Datenbank: hoechstens eine Minute alt ausliefern,
 *  bei einer Freigabe im Adminpanel sofort erneuern. */
export const revalidate = 60;

export default function Page() {
  return <Directory lang="de" />;
}
