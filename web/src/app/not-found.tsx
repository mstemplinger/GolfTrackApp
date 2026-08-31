import Link from "next/link";
import { fontVariables } from "@/lib/fonts";
import "./globals.css";

/**
 * Eigenständige 404-Seite. Weil die Sprachfassungen je ein eigenes
 * Wurzel-Layout haben, bringt diese Seite ihr eigenes Grundgerüst mit.
 */
export default function NotFound() {
  return (
    <html lang="de" className={`${fontVariables} h-full`}>
      <body className="grain glow grid min-h-full place-items-center px-5 text-center">
        <div>
          <p className="marginal">404</p>
          <h1 className="mt-4 font-display text-4xl tracking-tight">Ins Aus geschlagen.</h1>
          <p className="mt-3 text-cream/60">Diese Seite gibt es nicht (mehr).</p>
          <Link href="/" className="btn-brass mt-8">
            Zurück zum Start
          </Link>
        </div>
      </body>
    </html>
  );
}
