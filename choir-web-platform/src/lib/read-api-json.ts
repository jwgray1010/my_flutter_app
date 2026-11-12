export async function readApiJson<T>(response: Response): Promise<T> {
  const text = await response.text();
  const trimmed = text.trimStart();
  if (!trimmed) {
    throw new Error(
      response.ok
        ? "The server returned an empty response."
        : `The server failed before it could return a result (HTTP ${response.status}).`
    );
  }
  if (trimmed.startsWith("<")) {
    const timedOut = response.status === 408 || response.status === 502 || response.status === 503 || response.status === 504 || response.status === 524;
    throw new Error(
      timedOut
        ? "The connection closed before recognition finished. Check My Music in a minute; a long score can still be saving."
        : `The server sent a web page instead of recognition data (HTTP ${response.status}).`
    );
  }
  try {
    return JSON.parse(text) as T;
  } catch {
    throw new Error("The server returned a result that could not be read.");
  }
}

type RunningJob = {
  jobId?: string;
  status?: string;
  message?: string;
  result?: unknown;
};

export async function resolveRecognitionResult<T>(response: Response): Promise<T> {
  const body = await readApiJson<T & RunningJob>(response);
  if (body.jobId && body.status === "running") {
    return waitForRecognitionJob<T>(body.jobId);
  }
  return body;
}

export async function waitForRecognitionJob<T>(jobId: string): Promise<T> {
  const deadline = Date.now() + 30 * 60 * 1000;
  let delayMs = 800;
  while (Date.now() < deadline) {
    await new Promise((resolve) => setTimeout(resolve, delayMs));
    delayMs = 2000;
    const response = await fetch(`/api/my-music/jobs/${encodeURIComponent(jobId)}`, {
      cache: "no-store",
    });
    const body = await readApiJson<RunningJob>(response);
    if (!response.ok) {
      throw new Error(body.message ?? "Recognition status could not be read.");
    }
    if (body.status === "failed") {
      throw new Error(body.message ?? "Recognition failed.");
    }
    if (body.status === "succeeded") {
      if (body.result == null) {
        throw new Error("Recognition finished without a result.");
      }
      return body.result as T;
    }
  }
  throw new Error("Recognition is still running. Check My Music in a few minutes.");
}
