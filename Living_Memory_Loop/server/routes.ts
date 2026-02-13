import type { Express, Request, Response } from "express";
import { createServer, type Server } from "node:http";
import express from "express";
import OpenAI, { toFile } from "openai";
import { detectAudioFormat, ensureCompatibleFormat } from "./replit_integrations/audio/client";

const openai = new OpenAI({
  apiKey: process.env.AI_INTEGRATIONS_OPENAI_API_KEY ?? process.env.OPENAI_API_KEY,
  baseURL: process.env.AI_INTEGRATIONS_OPENAI_BASE_URL ?? process.env.OPENAI_BASE_URL,
});

const audioBodyParser = express.json({ limit: "50mb" });
const transcriptionModelCandidates = [
  process.env.MEMORY_TRANSCRIPTION_MODEL,
  "gpt-4o-mini-transcribe",
  "whisper-1",
].filter((model, index, list): model is string => Boolean(model?.trim()) && list.indexOf(model) === index);
const structuringModelCandidates = [
  process.env.MEMORY_STRUCTURING_MODEL,
  "gpt-5-mini",
  "gpt-4o-mini",
].filter((model, index, list): model is string => Boolean(model?.trim()) && list.indexOf(model) === index);

const memoryStructuringPrompt = `You are an intelligent memory structuring assistant. Your job is to take a raw voice transcript-often messy, casual, full of filler words, hesitations, repetitions, and background noise artifacts-and extract clean, structured, useful information.

Clean and structure this casual voice ramble into concise, useful output. Ignore ums, ahs, likes, you knows, repetitions, and stutters. Focus on key ideas, tasks, people, and references mentioned.

You must respond with ONLY valid JSON in this exact format:
{
  "title": "a short, poetic 2-5 word summary that captures the essence",
  "category": "one of: Shopping, Learning, Meeting, Personal, Ideas, Health, Work, Travel, Other",
  "action_items": ["array of specific, actionable tasks extracted from the speech"],
  "mood": "a single sentiment word like: reflective, excited, urgent, calm, curious, grateful, determined, nostalgic, creative, neutral"
}

Rules:
- Title should be evocative and concise, not a dry summary
- Category should be auto-detected from context
- Action items should be specific and actionable, not vague
- If no clear action items, return an empty array
- Mood should combine basic sentiment analysis with contextual flavor
- Handle noisy transcripts gracefully - extract intent even from messy speech
- Never include filler words or repetitions in your output`;

function errorStatus(error: unknown): number | undefined {
  if (typeof error !== "object" || error === null) {
    return undefined;
  }
  if ("status" in error && typeof error.status === "number") {
    return error.status;
  }
  return undefined;
}

function errorMessage(error: unknown): string {
  if (typeof error === "object" && error !== null) {
    if (
      "error" in error &&
      typeof error.error === "object" &&
      error.error !== null &&
      "message" in error.error &&
      typeof error.error.message === "string"
    ) {
      return error.error.message;
    }

    if ("message" in error && typeof error.message === "string") {
      return error.message;
    }
  }

  if (error instanceof Error) {
    return error.message;
  }

  return "Unknown error";
}

function isModelUnavailableError(error: unknown): boolean {
  const status = errorStatus(error);
  const message = errorMessage(error).toLowerCase();
  const isModelIssue =
    message.includes("model") &&
    (
      message.includes("not found") ||
      message.includes("does not exist") ||
      message.includes("not available") ||
      message.includes("unsupported") ||
      message.includes("access") ||
      message.includes("permission")
    );

  return isModelIssue && (status === 400 || status === 403 || status === 404);
}

async function structureTranscript(transcript: string): Promise<string> {
  let lastModelError: unknown;

  for (const model of structuringModelCandidates) {
    try {
      const structureResponse = await openai.chat.completions.create({
        model,
        messages: [
          {
            role: "system",
            content: memoryStructuringPrompt,
          },
          {
            role: "user",
            content: transcript,
          },
        ],
        response_format: { type: "json_object" },
        max_completion_tokens: 1024,
      });

      return structureResponse.choices[0]?.message?.content || "{}";
    } catch (error) {
      if (isModelUnavailableError(error)) {
        console.warn(`Model unavailable for structuring: ${model}. Trying fallback.`);
        lastModelError = error;
        continue;
      }
      throw error;
    }
  }

  throw lastModelError ?? new Error("No available structuring model.");
}

function mapProcessingError(error: unknown): { status: number; message: string } {
  const status = errorStatus(error);
  const message = errorMessage(error);
  const lowered = message.toLowerCase();

  if (
    status === 401 ||
    lowered.includes("missing api key") ||
    lowered.includes("incorrect api key") ||
    lowered.includes("invalid api key")
  ) {
    return {
      status: 500,
      message: "Server OpenAI API key is missing or invalid. Set OPENAI_API_KEY (or AI_INTEGRATIONS_OPENAI_API_KEY) and restart the server.",
    };
  }

  if (status === 429 || lowered.includes("rate limit")) {
    return {
      status: 503,
      message: "OpenAI rate limit reached. Please try again in a moment.",
    };
  }

  if (lowered.includes("insufficient_quota") || lowered.includes("quota")) {
    return {
      status: 503,
      message: "OpenAI quota exceeded for this key. Add billing/credits or use a different key.",
    };
  }

  if (
    lowered.includes("ffmpeg") ||
    lowered.includes("exited with code") ||
    lowered.includes("enoent")
  ) {
    return {
      status: 500,
      message: "Audio conversion failed on the server. Install ffmpeg or use wav/mp3/webm/mp4/m4a audio.",
    };
  }

  if (status === 400 && (lowered.includes("audio") || lowered.includes("transcrib"))) {
    return {
      status: 400,
      message: "Could not transcribe audio. Please try again.",
    };
  }

  if (
    lowered.includes("fetch failed") ||
    lowered.includes("enotfound") ||
    lowered.includes("econnrefused") ||
    lowered.includes("etimedout") ||
    lowered.includes("network")
  ) {
    return {
      status: 503,
      message: "Backend could not reach OpenAI. Check internet connectivity and firewall/proxy settings.",
    };
  }

  return {
    status: 500,
    message: `Failed to process memory. ${message}`,
  };
}

async function transcribeAudio(file: any): Promise<string> {
  let lastError: unknown;

  for (const model of transcriptionModelCandidates) {
    try {
      const transcription = await openai.audio.transcriptions.create({
        file,
        model,
      });

      return transcription.text;
    } catch (error) {
      if (isModelUnavailableError(error)) {
        console.warn(`Model unavailable for transcription: ${model}. Trying fallback.`);
        lastError = error;
        continue;
      }
      throw error;
    }
  }

  throw lastError ?? new Error("No available transcription model.");
}

export async function registerRoutes(app: Express): Promise<Server> {
  app.post("/api/process-memory", audioBodyParser, async (req: Request, res: Response) => {
    try {
      const { audio } = req.body;

      if (!process.env.AI_INTEGRATIONS_OPENAI_API_KEY && !process.env.OPENAI_API_KEY) {
        return res.status(500).json({
          error:
            "Server is missing OpenAI credentials. Set OPENAI_API_KEY (or AI_INTEGRATIONS_OPENAI_API_KEY) and restart.",
        });
      }

      if (typeof audio !== "string" || audio.length === 0) {
        return res.status(400).json({ error: "Audio data (base64) is required" });
      }

      const rawBuffer = Buffer.from(audio, "base64");
      if (rawBuffer.length === 0) {
        return res.status(400).json({ error: "Invalid audio data. Could not decode base64 payload." });
      }

      const rawSizeKB = Math.round(rawBuffer.length / 1024);
      const detectedFormat = detectAudioFormat(rawBuffer);
      console.log(`Received audio: ${rawSizeKB} KB (${detectedFormat})`);

      if (rawBuffer.length > 25 * 1024 * 1024) {
        return res.status(413).json({
          error: "Recording is too large. Please keep recordings under 60 seconds."
        });
      }

      const { buffer: audioBuffer, format: inputFormat } = await ensureCompatibleFormat(rawBuffer);

      const compressedSizeKB = Math.round(audioBuffer.length / 1024);
      console.log(`After compatibility step: ${compressedSizeKB} KB (${inputFormat})`);

      const file = await toFile(audioBuffer, `audio.${inputFormat}`);
      const transcript = await transcribeAudio(file);

      if (!transcript || transcript.trim().length === 0) {
        return res.status(400).json({ error: "Could not transcribe audio. Please try again." });
      }

      const structuredContent = await structureTranscript(transcript);
      let structured;
      try {
        structured = JSON.parse(structuredContent);
      } catch {
        structured = {
          title: "Untitled Memory",
          category: "Other",
          action_items: [],
          mood: "neutral"
        };
      }

      if (!structured.title) structured.title = "Untitled Memory";
      if (!structured.category) structured.category = "Other";
      if (!Array.isArray(structured.action_items)) structured.action_items = [];
      if (!structured.mood) structured.mood = "neutral";

      res.json({
        transcript,
        ...structured,
      });
    } catch (error) {
      console.error("Error processing memory:", error);
      const mapped = mapProcessingError(error);
      res.status(mapped.status).json({ error: mapped.message });
    }
  });

  const httpServer = createServer(app);
  return httpServer;
}
