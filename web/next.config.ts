import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Hinter nginx: die echten Besucheradressen kommen aus X-Forwarded-For.
  poweredByHeader: false,
  images: {
    // Bildschirmfotos aus der App: feine Schrift und Farbflächen, dafür lohnt
    // etwas mehr Qualität als der Standard. Die Uhr wird klein dargestellt
    // und verträgt am wenigsten Kompression.
    qualities: [75, 82, 88],
    formats: ["image/avif", "image/webp"],
  },
};

export default nextConfig;
