import type { Metadata, Viewport } from "next";
import { Document, pageMetadata } from "@/components/Shell";

export const metadata: Metadata = pageMetadata("en", "home");
export const viewport: Viewport = { themeColor: "#08180f" };

export default function EnglishRootLayout({ children }: { children: React.ReactNode }) {
  return <Document lang="en">{children}</Document>;
}
