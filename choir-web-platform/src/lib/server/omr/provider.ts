import type { OMRDiagnostics } from "@/lib/score-types";

export interface OMRProcessOptions {
  outputDir: string;
  pageNumbers?: number[];
}

export interface OMRArtifacts {
  audiverisOmrPath: string | null;
  audiverisMxlPath: string | null;
  audiverisMusicXmlPath: string | null;
}

export interface OMRResult {
  musicXml: string;
  diagnostics: OMRDiagnostics;
  provider: string;
  warnings: string[];
  artifacts: OMRArtifacts;
  recognitionLog: string;
}

export interface OMRService {
  processScore(inputFiles: string[], options: OMRProcessOptions): Promise<OMRResult>;
}

