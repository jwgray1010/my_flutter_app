import type { OMRDiagnostics } from "@/lib/score-types";

export interface OMRInput {
  filePath: string;
  mimeType: string;
  originalFileName: string;
}

export interface OMRResult {
  musicXml: string;
  diagnostics: OMRDiagnostics;
  provider: string;
}

export interface OMRProvider {
  recognize(input: OMRInput, diagnostics: OMRDiagnostics): Promise<OMRResult>;
}

