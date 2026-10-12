import type { Metadata } from "next";
import { ShortImprint } from "@/views/ComingSoon";

export const metadata: Metadata = { title: "Impressum · GolfTrack" };

export default function Page() {
  return <ShortImprint />;
}
