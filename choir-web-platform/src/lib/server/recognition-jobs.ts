import { randomUUID } from "node:crypto";

export type RecognitionJobResult = {
  status: number;
  body: unknown;
};

type RecognitionJob = {
  id: string;
  status: "running" | "succeeded" | "failed";
  httpStatus: number;
  body?: unknown;
  message?: string;
  updatedAt: number;
};

type JobStore = Map<string, RecognitionJob>;

function jobStore(): JobStore {
  const globalStore = globalThis as typeof globalThis & { __recognitionJobs?: JobStore };
  if (!globalStore.__recognitionJobs) {
    globalStore.__recognitionJobs = new Map();
  }
  return globalStore.__recognitionJobs;
}

function messageFrom(body: unknown) {
  if (body && typeof body === "object" && "message" in body && typeof body.message === "string") {
    return body.message;
  }
  return undefined;
}

export function startRecognitionJob(run: () => Promise<RecognitionJobResult>) {
  const jobs = jobStore();
  const cutoff = Date.now() - 2 * 60 * 60 * 1000;
  for (const [id, job] of jobs) {
    if (job.updatedAt < cutoff) {
      jobs.delete(id);
    }
  }

  const id = randomUUID();
  jobs.set(id, {
    id,
    status: "running",
    httpStatus: 202,
    updatedAt: Date.now(),
  });

  void run()
    .then((result) => {
      const failed = result.status >= 400;
      jobs.set(id, {
        id,
        status: failed ? "failed" : "succeeded",
        httpStatus: result.status,
        body: result.body,
        message: failed ? messageFrom(result.body) ?? "Recognition failed." : messageFrom(result.body),
        updatedAt: Date.now(),
      });
    })
    .catch((error: unknown) => {
      const message = error instanceof Error ? error.message : "Recognition failed.";
      console.error("[recognition-job] failed:", error);
      jobs.set(id, {
        id,
        status: "failed",
        httpStatus: 500,
        body: { message },
        message,
        updatedAt: Date.now(),
      });
    });

  return id;
}

export function getRecognitionJob(id: string) {
  return jobStore().get(id) ?? null;
}
