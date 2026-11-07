import { JsonLd, appSchema, organizationSchema } from "@/components/JsonLd";
import { Home } from "@/views/Home";

export default function Page() {
  return (
    <>
      <JsonLd data={[organizationSchema(), appSchema("de")]} />
      <Home lang="de" />
    </>
  );
}
