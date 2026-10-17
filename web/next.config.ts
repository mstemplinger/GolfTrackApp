import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Hinter nginx: die echte Besucheradresse kommt aus X-Real-IP (siehe lib/auth.ts).
  poweredByHeader: false,
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          // Ohne includeSubDomains: nicht jede Subdomain ist sicher auf HTTPS.
          { key: "Strict-Transport-Security", value: "max-age=31536000" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          // Nur das Einbetten in fremde Seiten verbieten; eine volle CSP
          // bräuchte Nonces für die Inline-Skripte von Next.js.
          { key: "Content-Security-Policy", value: "frame-ancestors 'none'" },
          { key: "X-Frame-Options", value: "DENY" },
        ],
      },
    ];
  },
  images: {
    // Bildschirmfotos aus der App: feine Schrift und Farbflächen, dafür lohnt
    // etwas mehr Qualität als der Standard. Die Uhr wird klein dargestellt
    // und verträgt am wenigsten Kompression.
    qualities: [75, 82, 88],
    formats: ["image/avif", "image/webp"],
  },
};

export default nextConfig;
