import type { ChatMessage } from "./types";

// iOS:     [15/01/2023, 9:42:13 PM] John: Hey
// Android: 15/01/2023, 21:42 - John: Hey
const IOS = /^‎?\[(\d{1,2}[/.]\d{1,2}[/.]\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?)\s*([AaPp][Mm])?\]\s*([^:]+?):\s?(.*)$/;
const ANDROID = /^(\d{1,2}[/.]\d{1,2}[/.]\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?)\s*([AaPp][Mm])?\s*-\s+([^:]+?):\s?(.*)$/;
const ANDROID_SYS = /^(\d{1,2}[/.]\d{1,2}[/.]\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?)\s*([AaPp][Mm])?\s*-\s+(.*)$/;

const MEDIA = /<Media omitted>|<attached:|image omitted|video omitted|audio omitted|sticker omitted|GIF omitted|document omitted|\.vcf \(file attached\)/i;
// Invisible bidi / zero-width marks WhatsApp injects.
const FORMAT_MARKS = /[​‎‏‪-‮⁦-⁩﻿]/g;

function isSystemContent(text: string): boolean {
  if (!text) return true;
  const t = text.trim().toLowerCase();
  const startsWith = [
    "messages and calls are end-to-end encrypted",
    "messages to this chat and calls are now secured",
    "this business uses a secure service from meta",
    "this business works with",
    "you blocked this business",
    "you unblocked this business",
    "waiting for this message",
    "you turned on disappearing messages",
    "you turned off disappearing messages",
    "disappearing messages were turned",
    "this message was deleted",
    "you deleted this message",
    "missed voice call",
    "missed video call",
    "missed group voice call",
    "missed group video call",
  ];
  if (startsWith.some((s) => t.startsWith(s))) return true;
  const contains = [
    "security code with",
    "changed their phone number",
    "changed to a new number",
    "you're now an admin",
    "tap to learn more",
  ];
  if (contains.some((c) => t.includes(c))) return true;
  if (t.endsWith("is a contact") || t.endsWith("is a contact.")) return true;
  return false;
}

function buildDate(date: string, time: string, ampm?: string): Date {
  const dp = date.split(/[/.]/).map((x) => parseInt(x, 10));
  let [a, b, year] = dp;
  if (year < 100) year += 2000;
  let day: number, month: number;
  if (a > 12) { day = a; month = b; }
  else if (b > 12) { month = a; day = b; }
  else { day = a; month = b; }
  const tp = time.split(":").map((x) => parseInt(x, 10));
  let hour = tp[0];
  const minute = tp[1];
  const second = tp[2] ?? 0;
  if (ampm) {
    const pm = ampm.toLowerCase() === "pm";
    if (pm && hour < 12) hour += 12;
    if (!pm && hour === 12) hour = 0;
  }
  return new Date(year, month - 1, day, hour, minute, second);
}

function countWords(text: string): number {
  const t = text.trim();
  return t ? t.split(/\s+/).length : 0;
}

export function contactNameFromFileName(fileName: string): string | null {
  let n = fileName;
  const slash = n.lastIndexOf("/");
  if (slash !== -1) n = n.slice(slash + 1);
  n = n.replace(/\.(txt|zip)$/i, "");
  n = n.replace(/^tikboo_\d+_/, "");
  const m = n.match(/whatsapp chat (?:with|-)\s*(.+)$/i);
  if (!m) return null;
  let name = m[1].trim().replace(/\s*\(\d+\)$/, "").trim();
  if (!name || name.toLowerCase() === "_chat") return null;
  return name;
}

export function resolveOtherPerson(
  participants: string[],
  fileName?: string
): string {
  if (participants.length === 0) return "them";
  if (participants.length === 1) return participants[0];
  const contact = fileName ? contactNameFromFileName(fileName) : null;
  if (contact) {
    const c = contact.toLowerCase();
    for (const p of participants) {
      const pl = p.toLowerCase();
      if (pl === c || pl.includes(c) || c.includes(pl)) return p;
    }
  }
  return participants[0];
}

export function parseChat(raw: string): ChatMessage[] {
  const lines = raw.split(/\r?\n/);
  const messages: ChatMessage[] = [];
  let curTime: Date | null = null;
  let curSender: string | null = null;
  let curIsSystem = false;
  let buffer: string[] = [];

  const flush = () => {
    if (!curTime) return;
    const text = buffer.join("\n").replace(FORMAT_MARKS, "").trim();
    const isMedia = MEDIA.test(text);
    messages.push({
      timestamp: curTime,
      sender: curSender ?? "System",
      text: isMedia ? "" : text,
      isMedia,
      isSystem: curIsSystem || curSender === null || isSystemContent(text),
      wordCount: isMedia ? 0 : countWords(text),
    });
  };

  for (const line of lines) {
    const ios = IOS.exec(line);
    const android = ios ? null : ANDROID.exec(line);
    const match = ios ?? android;
    if (match) {
      flush();
      buffer = [];
      curTime = buildDate(match[1], match[2], match[3]);
      curSender = match[4].trim();
      curIsSystem = false;
      buffer.push(match[5] ?? "");
    } else {
      const sys = ANDROID_SYS.exec(line);
      if (sys && !ios) {
        flush();
        buffer = [];
        curTime = buildDate(sys[1], sys[2], sys[3]);
        curSender = null;
        curIsSystem = true;
        buffer.push(sys[4] ?? "");
      } else if (curTime) {
        buffer.push(line);
      }
    }
  }
  flush();
  return messages;
}

export function extractTextFromFile(
  buf: ArrayBuffer,
  fileName: string,
  unzip: (buf: ArrayBuffer) => Promise<string>
): Promise<string> | string {
  if (fileName.toLowerCase().endsWith(".zip")) {
    return unzip(buf);
  }
  return new TextDecoder("utf-8").decode(buf);
}
