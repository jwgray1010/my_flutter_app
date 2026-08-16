import type { OMRService } from "@/lib/server/omr/provider";
import { AudiverisOMRService } from "@/lib/server/omr/audiveris-provider";

export function buildOcrService(): OMRService {
  return new AudiverisOMRService();
}

