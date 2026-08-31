import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { Home } from "@/views/Home";

export const metadata: Metadata = pageMetadata("en", "home");

export default function Page() {
  return <Home lang="en" />;
}
