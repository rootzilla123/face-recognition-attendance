import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  // Allow NEXT_PUBLIC_* vars to be overridden at runtime via env
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8001",
    NEXT_PUBLIC_PB_URL: process.env.NEXT_PUBLIC_PB_URL ?? "http://localhost:8090",
  },
};

export default nextConfig;
