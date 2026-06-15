import { NextRequest, NextResponse } from "next/server";

export const runtime = "nodejs";
export const maxDuration = 60;

const ENDPOINT = "https://openrouter.ai/api/v1/chat/completions";
const DEFAULT_MODEL = "openai/gpt-oss-120b:free";

const SYSTEM = `You are tikboo — a witty genz best friend who reads group chats and DMs for the vibe.
You get a JSON digest of chat statistics PLUS "message_samples" (a sample of real lines as "Sender: text"). Read between the numbers AND quote the receipts.
The digest may include "person_being_analyzed" (the person the app user wants read) and "you_the_app_user" (the app user themselves) — address the app user as "you" and focus the juicy read on the other person.
The digest may include "they_are" (the other person's gender) and "relationship" (e.g. Crush, Situationship, Ex). TAILOR the read to that relationship — a Crush read should hunt for interest signals and rizz; an Ex read should be about closure and patterns; a Friend read should be about loyalty and chaos.
Tone: playful, hype, lightly roasting but NEVER cruel, inclusive. Use genz slang naturally (lowkey, no cap, rizz, the math is mathing, ick, green/beige/red flag) but don't overdo it.
Refer to people by their actual names from the digest.
Return STRICT JSON only, no markdown, matching this exact shape:
{
  "vibe_title": "short punchy 2-4 word title",
  "vibe_emoji": "one emoji",
  "summary": "1-2 sentences reading the dynamic, referencing the relationship type",
  "roast": "2-3 sentences of loving roast based on the stats",
  "energy_match": "1 sentence on who brings more energy",
  "who_texts_first": "1 sentence on who starts convos / double texts, with numbers",
  "attachment_style": "1-2 sentences reading each person's texting attachment style from reply speed + who initiates",
  "first_text_read": "1 witty sentence reacting to who broke the ice and what the first message was",
  "green_flags": [{"flag":"short positive observation","quote":"a REAL message from message_samples, copied exactly","sender":"who said it"}],
  "red_flags": [{"flag":"short cheeky red flag (light)","quote":"a REAL message from message_samples, copied exactly","sender":"who said it"}],
  "superlatives": [{"emoji":"🏆","title":"award name","person":"name","reason":"why, short"}],
  "vibe_score": 0-100
}
CRITICAL: Both green AND red flags must be about "person_being_analyzed" ONLY — every flag's "sender" MUST be person_being_analyzed and every "quote" a message THEY sent. Never flag or quote "you_the_app_user".
Give 3 green flags and 2-3 red flags, each with a verbatim quote from message_samples (under ~120 chars) or "" if none fits. Give 3-4 superlatives. Keep strings tight and screenshot-able.`;

function extractJson(raw: string): any {
  let s = raw.trim();
  s = s.replace(/^```(json)?/gm, "").replace(/```/g, "");
  const start = s.indexOf("{");
  const end = s.lastIndexOf("}");
  if (start !== -1 && end !== -1 && end > start) s = s.slice(start, end + 1);
  s = s.replace(/,\s*([}\]])/g, "$1");
  return JSON.parse(s);
}

function flagList(v: any): any[] {
  if (!Array.isArray(v)) return [];
  return v.map((e) =>
    typeof e === "string"
      ? { flag: e, quote: "", sender: "" }
      : { flag: String(e.flag ?? e.text ?? ""), quote: String(e.quote ?? ""), sender: String(e.sender ?? "") }
  );
}

function dropUserFlags(arr: any[], you?: string) {
  if (!you) return arr;
  const yl = you.toLowerCase().trim();
  const kept = arr.filter((f) => (f.sender ?? "").toLowerCase().trim() !== yl);
  return kept.length ? kept : arr;
}

export async function POST(req: NextRequest) {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) {
    return NextResponse.json({ error: "Server is missing OPENROUTER_API_KEY." }, { status: 500 });
  }
  const { digest, model, you } = await req.json();
  const payload = JSON.stringify({
    model: model || process.env.OPENROUTER_MODEL || DEFAULT_MODEL,
    temperature: 0.9,
    response_format: { type: "json_object" },
    messages: [
      { role: "system", content: SYSTEM },
      { role: "user", content: `Analyze and return JSON.\n\n${JSON.stringify(digest, null, 2)}` },
    ],
  });

  let lastErr = "Could not get a clean read.";
  for (let attempt = 1; attempt <= 4; attempt++) {
    try {
      const res = await fetch(ENDPOINT, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://tikboo.app",
          "X-Title": "tikboo",
        },
        body: payload,
      });
      if (res.status === 429) {
        lastErr = "Rate limited — free models are popular. Try again.";
        await new Promise((r) => setTimeout(r, 1200 * attempt));
        continue;
      }
      if (!res.ok) {
        const code = res.status;
        const msg =
          code === 401 ? "AI key rejected."
          : code === 402 ? "This model needs credits — pick a free one."
          : `OpenRouter error (${code}).`;
        return NextResponse.json({ error: msg }, { status: 502 });
      }
      const body = await res.json();
      const content = body?.choices?.[0]?.message?.content;
      if (!content) { lastErr = "Empty response."; continue; }
      const parsed = extractJson(content);
      parsed.red_flags = dropUserFlags(flagList(parsed.red_flags), you);
      parsed.green_flags = dropUserFlags(flagList(parsed.green_flags), you);

      const analysis = {
        vibeTitle: String(parsed.vibe_title ?? "Certified Chat"),
        vibeEmoji: String(parsed.vibe_emoji ?? "✨"),
        summary: String(parsed.summary ?? ""),
        roast: String(parsed.roast ?? ""),
        energyMatch: String(parsed.energy_match ?? ""),
        whoTextsFirst: String(parsed.who_texts_first ?? ""),
        attachmentStyle: String(parsed.attachment_style ?? ""),
        firstTextRead: String(parsed.first_text_read ?? ""),
        greenFlags: parsed.green_flags,
        redFlags: parsed.red_flags,
        superlatives: Array.isArray(parsed.superlatives)
          ? parsed.superlatives.map((s: any) => ({
              emoji: String(s.emoji ?? "🏆"), title: String(s.title ?? ""),
              person: String(s.person ?? ""), reason: String(s.reason ?? ""),
            }))
          : [],
        vibeScore: typeof parsed.vibe_score === "number"
          ? Math.max(0, Math.min(100, Math.round(parsed.vibe_score))) : 72,
      };
      return NextResponse.json({ analysis });
    } catch (e: any) {
      lastErr = e?.message ?? "Network error.";
      await new Promise((r) => setTimeout(r, 400 * attempt));
    }
  }
  return NextResponse.json({ error: lastErr }, { status: 502 });
}
