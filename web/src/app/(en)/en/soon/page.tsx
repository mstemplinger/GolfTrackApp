import type { Metadata } from "next";
import { connection } from "next/server";
import { redirect } from "next/navigation";
import { launched } from "@/lib/launch";
import { ComingSoon } from "@/views/ComingSoon";

export const metadata: Metadata = {
  title: "GolfTrack · Coming soon",
  description: "The new GolfTrack website launches on 1 November 2026. The app is already on the App Store.",
};

export default async function Page() {
  await connection();
  const now = Date.now();
  if (launched(now)) redirect("/en");
  return <ComingSoon lang="en" now={now} />;
}
