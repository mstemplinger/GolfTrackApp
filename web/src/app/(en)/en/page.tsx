import type { Metadata } from "next";
import { pageMetadata } from "@/components/Shell";
import { JsonLd, appSchema, organizationSchema } from "@/components/JsonLd";
import { Home } from "@/views/Home";

export const metadata: Metadata = pageMetadata("en", "home");

export default function Page() {
  return (
    <>
      <JsonLd data={[organizationSchema(), appSchema("en")]} />
      <Home lang="en" />
    </>
  );
}
