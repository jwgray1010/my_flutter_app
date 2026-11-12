import { NextResponse } from "next/server";
import { getRecognitionJob } from "@/lib/server/recognition-jobs";

export const runtime = "nodejs";

export async function GET(
  _request: Request,
  context: { params: Promise<{ jobId: string }> }
) {
  const { jobId } = await context.params;
  if (!/^[0-9a-f-]{36}$/i.test(jobId)) {
    return NextResponse.json({ message: "Recognition job not found." }, { status: 404 });
  }
  const job = getRecognitionJob(jobId);
  if (!job) {
    return NextResponse.json(
      { message: "Recognition job not found. It may have finished before this page could check it. Look in My Music." },
      { status: 404 }
    );
  }
  return NextResponse.json(
    {
      jobId: job.id,
      status: job.status,
      message: job.message,
      result: job.status === "running" ? undefined : job.body,
    },
    {
      status: 200,
      headers: { "cache-control": "no-store" },
    }
  );
}
