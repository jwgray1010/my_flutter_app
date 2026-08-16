import type { OMRProvider } from "@/lib/server/omr/provider";
import { HomrOcrProvider } from "@/lib/server/omr/homr-provider";

export function buildOcrProvider(): OMRProvider {
  return new HomrOcrProvider();
}

