import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Allow the local dev server's JS bundles/HMR socket to load when the app
  // is accessed through a public tunnel (e.g. a Cloudflare Quick Tunnel)
  // instead of localhost directly. Without this, Next.js blocks cross-origin
  // requests to dev resources and the page loads but never hydrates.
  allowedDevOrigins: ["*.trycloudflare.com"],
};

export default nextConfig;
