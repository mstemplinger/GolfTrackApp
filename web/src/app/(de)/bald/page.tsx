import type { Metadata } from "next";
import { connection } from "next/server";
import { redirect } from "next/navigation";
import { launched } from "@/lib/launch";
import { ComingSoon } from "@/views/ComingSoon";

export const metadata: Metadata = {
  title: "GolfTrack · Bald verfügbar",
  description: "Die neue Website von GolfTrack startet am 1. November 2026. Die App gibt es schon jetzt im App Store.",
};

export default async function Page() {
  // Bei jedem Aufruf neu: der Zähler startet mit der Uhrzeit des Servers.
  await connection();
  const now = Date.now();
  if (launched(now)) redirect("/");
  return <ComingSoon lang="de" now={now} />;
}
