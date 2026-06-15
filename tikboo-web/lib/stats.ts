import type { ChatMessage, ChatStats, PersonStats } from "./types";

const EMOJI = /\p{Extended_Pictographic}/gu;
const LAUGH = /(haha|hehe|lol|lmao|lmfao|rofl|💀|😂|🤣)/i;
const STOP = new Set([
  "the","a","an","and","or","but","is","are","was","were","i","you","u","me",
  "my","we","to","of","in","on","it","so","for","that","this","with","at","be",
  "have","do","just","not","no","yes","ok","okay","yeah","ya","im","its","he",
  "she","they","will","can","if","as","too","get","got","up","out","now","omg",
  "like","know","what","how","when","why","all","about",
]);

function dayKey(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(
    d.getDate()
  ).padStart(2, "0")}`;
}

const MONTHS = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
function pretty(d: Date): string {
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
}

export function computeStats(all: ChatMessage[]): ChatStats {
  const msgs = all
    .filter((m) => !m.isSystem)
    .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
  if (msgs.length === 0) {
    throw new Error(
      "Couldn't find any messages. Make sure it's a WhatsApp .txt/.zip export."
    );
  }

  const names = Array.from(new Set(msgs.map((m) => m.sender)));
  const isGroup = names.length > 2;

  const stat: Record<string, PersonStats> = {};
  const emojiTally: Record<string, Record<string, number>> = {};
  const wordTally: Record<string, Record<string, number>> = {};
  for (const n of names) {
    stat[n] = { name: n, messages: 0, words: 0, emojis: 0, media: 0,
      questions: 0, laughs: 0, conversationsStarted: 0, topEmojis: [],
      topWords: [], avgReplyMinutes: null };
    emojiTally[n] = {};
    wordTally[n] = {};
  }

  const emojiOverall: Record<string, number> = {};
  const byHour: Record<number, number> = {};
  const byDay: Record<string, number> = {};
  const activeDates = new Set<string>();
  let totalEmojis = 0, totalMedia = 0;

  const replyTotal: Record<string, number> = {};
  const replyCount: Record<string, number> = {};
  for (const n of names) { replyTotal[n] = 0; replyCount[n] = 0; }

  const GAP = 6 * 3600 * 1000; // 6h
  const firstText =
    msgs.find((m) => !m.isMedia && m.text.trim() !== "") ?? msgs[0];
  let longest = msgs[0];
  let prev: ChatMessage | null = null;

  for (const m of msgs) {
    const s = stat[m.sender];
    s.messages++;
    byHour[m.timestamp.getHours()] = (byHour[m.timestamp.getHours()] ?? 0) + 1;
    const dk = dayKey(m.timestamp);
    byDay[dk] = (byDay[dk] ?? 0) + 1;
    activeDates.add(dk);

    if (m.isMedia) { s.media++; totalMedia++; prev = m; continue; }

    s.words += m.wordCount;
    if (m.wordCount > longest.wordCount) longest = m;
    if (m.text.includes("?")) s.questions++;
    if (LAUGH.test(m.text)) s.laughs++;

    const emojis = m.text.match(EMOJI) ?? [];
    for (const e of emojis) {
      emojiTally[m.sender][e] = (emojiTally[m.sender][e] ?? 0) + 1;
      emojiOverall[e] = (emojiOverall[e] ?? 0) + 1;
      s.emojis++; totalEmojis++;
    }
    for (const w of m.text.toLowerCase().split(/[^a-z0-9]+/)) {
      if (w.length < 3 || STOP.has(w)) continue;
      wordTally[m.sender][w] = (wordTally[m.sender][w] ?? 0) + 1;
    }

    if (!prev || m.timestamp.getTime() - prev.timestamp.getTime() > GAP) {
      s.conversationsStarted++;
    } else if (prev.sender !== m.sender) {
      const d = m.timestamp.getTime() - prev.timestamp.getTime();
      if (d < 3 * 3600 * 1000) {
        replyTotal[m.sender] += d;
        replyCount[m.sender] += 1;
      }
    }
    prev = m;
  }

  for (const n of names) {
    const s = stat[n];
    s.topEmojis = Object.entries(emojiTally[n]).sort((a, b) => b[1] - a[1]).slice(0, 5);
    s.topWords = Object.entries(wordTally[n]).sort((a, b) => b[1] - a[1]).slice(0, 8).map((e) => e[0]);
    if (replyCount[n] > 0) s.avgReplyMinutes = Math.round(replyTotal[n] / replyCount[n] / 60000);
  }

  const people = Object.values(stat).sort((a, b) => b.messages - a.messages);

  const sortedDates = Array.from(activeDates).sort();
  let streak = sortedDates.length ? 1 : 0;
  let best = streak;
  for (let i = 1; i < sortedDates.length; i++) {
    const prevD = new Date(sortedDates[i - 1]);
    const curD = new Date(sortedDates[i]);
    if ((curD.getTime() - prevD.getTime()) / 86400000 === 1) {
      streak++; if (streak > best) best = streak;
    } else streak = 1;
  }

  const topEmojiOverall =
    Object.entries(emojiOverall).sort((a, b) => b[1] - a[1])[0]?.[0] ?? "🤐";
  const peakHour = Object.entries(byHour).sort((a, b) => b[1] - a[1])[0];
  const busiest = Object.entries(byDay).sort((a, b) => b[1] - a[1])[0];

  const spanDays =
    Math.floor(
      (msgs[msgs.length - 1].timestamp.getTime() - msgs[0].timestamp.getTime()) /
        86400000
    ) + 1;

  // representative sample for the AI to quote (evenly spaced, capped)
  const textMsgs = msgs.filter((m) => !m.isMedia && m.text.trim() !== "");
  const MAX = 220;
  const step = textMsgs.length <= MAX ? 1 : Math.ceil(textMsgs.length / MAX);
  const sampleLines: string[] = [];
  for (let i = 0; i < textMsgs.length; i += step) {
    const t = textMsgs[i].text.trim().replace(/\n/g, " ");
    sampleLines.push(`${textMsgs[i].sender}: ${t.length > 200 ? t.slice(0, 200) + "…" : t}`);
  }

  return {
    isGroup,
    people,
    totalMessages: msgs.length,
    spanDays,
    activeDays: activeDates.size,
    longestStreakDays: best,
    peakHour: peakHour ? parseInt(peakHour[0], 10) : 0,
    topEmojiOverall,
    totalEmojis,
    totalMedia,
    busiestDayLabel: busiest ? pretty(new Date(busiest[0])) : "—",
    firstSender: firstText.sender,
    firstText: firstText.text,
    firstDateTime: firstText.timestamp.toISOString(),
    longestSender: longest.sender,
    longestText: longest.text,
    longestWords: longest.wordCount,
    sampleLines,
  };
}

export function buildDigest(stats: ChatStats, ctx: { subjectLabel: string; relationship: string; otherName: string }) {
  let you: string | undefined;
  if (ctx.otherName && !stats.isGroup) {
    you = stats.people.map((p) => p.name).find((n) => n !== ctx.otherName);
  }
  return {
    they_are: ctx.subjectLabel,
    relationship: ctx.relationship,
    person_being_analyzed: ctx.otherName || undefined,
    you_the_app_user: you,
    is_group: stats.isGroup,
    total_messages: stats.totalMessages,
    span_days: stats.spanDays,
    active_days: stats.activeDays,
    longest_streak_days: stats.longestStreakDays,
    peak_hour: stats.peakHour,
    top_emoji: stats.topEmojiOverall,
    total_media: stats.totalMedia,
    first_message: { sender: stats.firstSender, text: stats.firstText.slice(0, 120) },
    longest_message: { sender: stats.longestSender, words: stats.longestWords },
    people: stats.people.map((p) => ({
      name: p.name,
      messages: p.messages,
      words: p.words,
      avg_words_per_msg: p.messages ? +(p.words / p.messages).toFixed(1) : 0,
      emojis: p.emojis,
      questions: p.questions,
      laughs: p.laughs,
      conversations_started: p.conversationsStarted,
      avg_reply_minutes: p.avgReplyMinutes,
      top_emojis: p.topEmojis.slice(0, 5).map(([e, c]) => `${e}:${c}`),
      top_words: p.topWords.slice(0, 8),
    })),
    message_samples: stats.sampleLines,
  };
}
