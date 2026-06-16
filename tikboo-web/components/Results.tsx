"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import { motion } from "framer-motion";
import { toPng } from "html-to-image";
import { ACCENT_HEX, Body, ChunkyButton, Display, cx, onAccentText } from "./ui";
import { Paywall } from "./Paywall";
import { Credits } from "@/lib/credits";
import type { AiAnalysis, ChatStats, FlagItem } from "@/lib/types";

const compact = (n: number) =>
  n >= 1e6 ? (n / 1e6).toFixed(1) + "M" : n >= 1e3 ? (n / 1e3).toFixed(1) + "K" : "" + n;
const hourLabel = (h: number) => `${h % 12 === 0 ? 12 : h % 12} ${h < 12 ? "AM" : "PM"}`;

function CardShell({ accent, children }: { accent: string; children: React.ReactNode }) {
  const hex = ACCENT_HEX[accent];
  return (
    <div className="relative h-full w-full shrink-0 snap-center overflow-hidden"
      style={{ background: `linear-gradient(135deg, ${hex}38, #0B0B0F 55%, #0B0B0F)` }}>
      <div className="flex h-full flex-col px-7 pb-10 pt-20">{children}</div>
    </div>
  );
}

export function Results({
  stats, analysis, otherName, reportId, onRestart,
}: { stats: ChatStats; analysis: AiAnalysis; otherName: string; reportId: string; onRestart: () => void }) {
  const [unlocked, setUnlocked] = useState(false);
  const [showPaywall, setShowPaywall] = useState(false);
  const [index, setIndex] = useState(0);
  const scroller = useRef<HTMLDivElement>(null);

  useEffect(() => { setUnlocked(Credits.isUnlocked(reportId)); }, [reportId]);

  // Locked-card CTA: spend a credit if available, else open the paywall.
  const handleUnlock = () => {
    if (Credits.get() > 0) {
      Credits.unlock(reportId);
      setUnlocked(true);
    } else {
      setShowPaywall(true);
    }
  };

  const cards = useMemo(
    () => buildCards(stats, analysis, otherName, unlocked, handleUnlock, onRestart),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [stats, analysis, otherName, unlocked, onRestart]
  );

  const go = (dir: 1 | -1) => {
    const el = scroller.current; if (!el) return;
    el.scrollBy({ left: dir * el.clientWidth, behavior: "smooth" });
  };
  const onScroll = () => {
    const el = scroller.current; if (!el) return;
    setIndex(Math.round(el.scrollLeft / el.clientWidth));
  };

  return (
    <div className="relative mx-auto h-[100dvh] w-full max-w-[480px] overflow-hidden bg-ink">
      <div ref={scroller} onScroll={onScroll}
        className="no-scrollbar flex h-full snap-x snap-mandatory overflow-x-auto overflow-y-hidden scroll-smooth">
        {cards.map((c, i) => (<div key={i} className="h-full w-full shrink-0 snap-center">{c}</div>))}
      </div>

      {/* tap zones — stop ~180px above the bottom so they never cover the CTAs */}
      <button aria-label="prev" className="absolute left-0 top-16 w-[30%]" style={{ bottom: 180 }} onClick={() => go(-1)} />
      <button aria-label="next" className="absolute right-0 top-16 w-[45%]" style={{ bottom: 180 }} onClick={() => go(1)} />

      {/* progress */}
      <div className="pointer-events-none absolute left-0 right-0 top-3 flex gap-1.5 px-4">
        {cards.map((_, i) => (
          <div key={i} className="h-1 flex-1 rounded-full" style={{ background: i <= index ? "#F5F5F7" : "#F5F5F740" }} />
        ))}
      </div>
      <button onClick={onRestart} className="absolute right-3 top-6 z-20 p-2 text-textHi" aria-label="Close">✕</button>

      {showPaywall && (
        <Paywall
          report={{ stats, analysis, otherName, reportId }}
          onClose={() => setShowPaywall(false)}
        />
      )}
    </div>
  );
}

function buildCards(
  stats: ChatStats, ai: AiAnalysis, otherName: string,
  pro: boolean, openPaywall: () => void, onRestart: () => void
) {
  const hasAi = !!(ai.roast || ai.vibeScore || ai.summary);
  const cards: React.ReactNode[] = [];
  cards.push(<IntroCard stats={stats} otherName={otherName} />);
  cards.push(<FirstTextCard stats={stats} ai={ai} />);

  if (hasAi && !pro) { cards.push(<LockedCard ai={ai} onUnlock={openPaywall} />); return cards; }

  cards.push(<BigStat accent="lime" kicker="TOTAL DAMAGE" value={compact(stats.totalMessages)} label="messages sent" caption={`across ${stats.spanDays} days · ${stats.activeDays} active`} />);
  cards.push(<YapCard stats={stats} />);
  cards.push(<BigStat accent="violet" kicker="PRIME TIME" value={hourLabel(stats.peakHour)} label="is when it pops off" caption={stats.peakHour >= 23 || stats.peakHour <= 4 ? "certified night owls 🦉" : "peak chaos hours, locked in"} />);
  cards.push(<EmojiCard stats={stats} />);
  if (stats.longestWords > 5) cards.push(<LongestCard stats={stats} />);
  cards.push(<BigStat accent="cyan" kicker="NO DAYS OFF" value={`${stats.longestStreakDays}`} label="day streak" caption={stats.longestStreakDays >= 7 ? "texting every day. obsessed 🔥" : "longest you went without ghosting"} />);

  if (hasAi) {
    cards.push(<VibeCard ai={ai} />);
    if (ai.energyMatch || ai.whoTextsFirst) cards.push(<ReadCard ai={ai} />);
    if (ai.attachmentStyle) cards.push(<AttachmentCard ai={ai} />);
    if (ai.superlatives.length) cards.push(<SuperlativesCard ai={ai} />);
    if (ai.greenFlags.length) cards.push(<FlagsCard accent="lime" emoji="🟢" title="GREEN FLAGS" flags={ai.greenFlags} />);
    if (ai.redFlags.length) cards.push(<FlagsCard accent="pink" emoji="🚩" title="RED FLAGS" flags={ai.redFlags} />);
    if (ai.roast) cards.push(<RoastCard ai={ai} />);
  }
  cards.push(<ShareSlide stats={stats} analysis={ai} otherName={otherName} onRestart={onRestart} />);
  return cards;
}

/* ---- individual cards ---- */
function IntroCard({ stats, otherName }: { stats: ChatStats; otherName: string }) {
  const who = stats.isGroup ? `${stats.people.length} legends` : otherName || stats.people.map((p) => p.name).slice(0, 2).join(" & ");
  return (
    <CardShell accent="pink">
      <div className="flex flex-1 flex-col justify-center">
        <Display size={22} color="#AFAFC0">THE TEA ON</Display>
        <div className="mt-2"><Display size={40} color={ACCENT_HEX.pink} style={{ lineHeight: 1.05 }}>{who}</Display></div>
        <div className="mt-5"><Body size={18} color="#F5F5F7">is officially served. 🍵</Body></div>
        <div className="mt-8"><Body size={13}>tap to continue →</Body></div>
      </div>
    </CardShell>
  );
}

function BigStat({ accent, kicker, value, label, caption }: { accent: string; kicker: string; value: string; label: string; caption: string }) {
  return (
    <CardShell accent={accent}>
      <Display size={18} color={ACCENT_HEX[accent]}>{kicker}</Display>
      <div className="flex-1 flex flex-col justify-center">
        <Display size={92} style={{ lineHeight: 0.95 }}>{value}</Display>
        <div className="mt-2"><Display size={24}>{label}</Display></div>
      </div>
      <Body size={16}>{caption}</Body>
    </CardShell>
  );
}

function FirstTextCard({ stats, ai }: { stats: ChatStats; ai: AiAnalysis }) {
  const prev = stats.firstText.trim() || "(a media message)";
  const clip = prev.length > 140 ? prev.slice(0, 140) + "…" : prev;
  const d = new Date(stats.firstDateTime);
  return (
    <CardShell accent="cyan">
      <Display size={18} color={ACCENT_HEX.cyan}>WHO BROKE THE ICE</Display>
      <div className="flex-1 flex flex-col justify-center">
        <Display size={34}>{stats.firstSender}</Display>
        <div className="mt-4 rounded-[18px] rounded-tl-[4px] border border-stroke bg-inkCard p-4"><Body size={17} color="#F5F5F7">“{clip}”</Body></div>
        <div className="mt-2"><Body size={13} color="#6C6C7E">{d.toLocaleString()}</Body></div>
      </div>
      {ai.firstTextRead && <Body size={16}>{ai.firstTextRead}</Body>}
    </CardShell>
  );
}

function YapCard({ stats }: { stats: ChatStats }) {
  const top = stats.people.slice(0, stats.isGroup ? 4 : 2);
  const max = top[0]?.messages || 1;
  return (
    <CardShell accent="tangerine">
      <Display size={18} color={ACCENT_HEX.tangerine}>YAP RANKINGS</Display>
      <div className="mt-1"><Display size={30}>{stats.isGroup ? "who runs the group" : "who texts more"}</Display></div>
      <div className="flex-1 flex flex-col justify-center gap-4">
        {top.map((p, i) => {
          const hex = ["#CBFF4D", "#FF4D9D", "#8B5CFF", "#45E0FF"][i % 4];
          return (
            <div key={p.name}>
              <div className="flex justify-between"><Display size={18}>{p.name}</Display><Display size={18} color={hex}>{compact(p.messages)}</Display></div>
              <div className="mt-2 h-3.5 overflow-hidden rounded-lg bg-inkCard">
                <motion.div className="h-full rounded-lg" style={{ background: hex }} initial={{ width: 0 }} animate={{ width: `${Math.max((p.messages / max) * 100, 4)}%` }} transition={{ duration: 0.6 }} />
              </div>
            </div>
          );
        })}
      </div>
    </CardShell>
  );
}

function EmojiCard({ stats }: { stats: ChatStats }) {
  return (
    <CardShell accent="violet">
      <Display size={18} color={ACCENT_HEX.violet}>SIGNATURE EMOJI</Display>
      <div className="flex-1 flex flex-col items-center justify-center">
        <motion.div className="text-[120px] leading-none" animate={{ scale: [0.92, 1.08, 0.92] }} transition={{ repeat: Infinity, duration: 2.4 }}>{stats.topEmojiOverall}</motion.div>
      </div>
      <Display size={26}>{compact(stats.totalEmojis)} emojis total</Display>
      <div className="mt-2"><Body size={16}>this one carried the entire convo on its back.</Body></div>
    </CardShell>
  );
}

function LongestCard({ stats }: { stats: ChatStats }) {
  const t = stats.longestText.trim();
  const clip = t.length > 220 ? t.slice(0, 220) + "…" : t;
  return (
    <CardShell accent="tangerine">
      <Display size={18} color={ACCENT_HEX.tangerine}>THE ESSAY 📝</Display>
      <div className="mt-1"><Display size={26}>{stats.longestSender} typed {stats.longestWords} words in one go</Display></div>
      <div className="my-5 flex-1 overflow-y-auto rounded-[18px] border border-stroke bg-inkCard p-4"><Body size={16} color="#F5F5F7">“{clip}”</Body></div>
      <Body size={15}>no notes. a whole TED talk. 🎤</Body>
    </CardShell>
  );
}

function VibeCard({ ai }: { ai: AiAnalysis }) {
  return (
    <CardShell accent="lime">
      <Display size={18} color={ACCENT_HEX.lime}>THE VERDICT</Display>
      <div className="flex-1 flex flex-col justify-center">
        <div className="text-[72px] leading-none">{ai.vibeEmoji}</div>
        <div className="mt-3"><Display size={38} color={ACCENT_HEX.lime} style={{ lineHeight: 1.05 }}>{ai.vibeTitle}</Display></div>
        {ai.summary && <div className="mt-4"><Body size={17} color="#F5F5F7">{ai.summary}</Body></div>}
      </div>
      {ai.vibeScore > 0 && (
        <div>
          <div className="flex justify-between"><Display size={15} color="#AFAFC0">VIBE SCORE</Display><Display size={20} color={ACCENT_HEX.lime}>{ai.vibeScore}/100</Display></div>
          <div className="mt-2 h-4 overflow-hidden rounded-[10px] bg-inkCard">
            <motion.div className="h-full rounded-[10px]" style={{ background: "linear-gradient(90deg,#45E0FF,#CBFF4D)" }} initial={{ width: 0 }} animate={{ width: `${ai.vibeScore}%` }} transition={{ duration: 0.8 }} />
          </div>
        </div>
      )}
    </CardShell>
  );
}

function ReadCard({ ai }: { ai: AiAnalysis }) {
  return (
    <CardShell accent="cyan">
      <Display size={18} color={ACCENT_HEX.cyan}>THE DYNAMIC</Display>
      <div className="flex-1 flex flex-col justify-center gap-6">
        {ai.energyMatch && <div><Display size={20}>⚡ energy</Display><div className="mt-2"><Body size={17}>{ai.energyMatch}</Body></div></div>}
        {ai.whoTextsFirst && <div><Display size={20}>💬 first move</Display><div className="mt-2"><Body size={17}>{ai.whoTextsFirst}</Body></div></div>}
      </div>
    </CardShell>
  );
}

function AttachmentCard({ ai }: { ai: AiAnalysis }) {
  return (
    <CardShell accent="violet">
      <Display size={18} color={ACCENT_HEX.violet}>ATTACHMENT STYLE 🧠</Display>
      <div className="flex-1 flex flex-col justify-center">
        <Display size={30}>the texting tells</Display>
        <div className="mt-4"><Body size={18} color="#F5F5F7">{ai.attachmentStyle}</Body></div>
      </div>
    </CardShell>
  );
}

function SuperlativesCard({ ai }: { ai: AiAnalysis }) {
  return (
    <CardShell accent="tangerine">
      <Display size={18} color={ACCENT_HEX.tangerine}>THE AWARDS</Display>
      <div className="mt-1"><Display size={26}>hand them their trophies 🏆</Display></div>
      <div className="mt-5 flex-1 space-y-3 overflow-y-auto">
        {ai.superlatives.map((s, i) => (
          <div key={i} className="flex gap-3.5 rounded-[18px] border border-stroke bg-inkCard p-4">
            <span className="text-[30px]">{s.emoji}</span>
            <div>
              <Display size={15} color={ACCENT_HEX.tangerine}>{s.title}</Display>
              <div><Body size={14} weight={700} color="#F5F5F7">{s.person}</Body></div>
              {s.reason && <div className="mt-1"><Body size={13}>{s.reason}</Body></div>}
            </div>
          </div>
        ))}
      </div>
    </CardShell>
  );
}

function FlagsCard({ accent, emoji, title, flags }: { accent: string; emoji: string; title: string; flags: FlagItem[] }) {
  const hex = ACCENT_HEX[accent];
  return (
    <CardShell accent={accent}>
      <Display size={28} color={hex}>{title}</Display>
      <div className="mt-5 flex-1 space-y-4 overflow-y-auto">
        {flags.map((f, i) => (
          <div key={i}>
            <div className="flex items-start gap-2.5"><span className="text-[20px]">{emoji}</span><Display size={16}>{f.flag}</Display></div>
            {f.quote?.trim() && (
              <div className="ml-8 mt-2 rounded-[16px] rounded-tl-[4px] border bg-inkCard px-3.5 py-2.5" style={{ borderColor: `${hex}66` }}>
                {f.sender?.trim() && <div><Body size={11} weight={800} color={hex}>{f.sender}</Body></div>}
                <Body size={14} color="#F5F5F7">“{f.quote.trim()}”</Body>
              </div>
            )}
          </div>
        ))}
      </div>
    </CardShell>
  );
}

function RoastCard({ ai }: { ai: AiAnalysis }) {
  return (
    <CardShell accent="pink">
      <Display size={28} color={ACCENT_HEX.pink}>THE ROAST 🔥</Display>
      <div className="flex-1 flex flex-col justify-center">
        <Display size={22} style={{ lineHeight: 1.3 }}>“{ai.roast}”</Display>
      </div>
      <Body size={15}>— tikboo, with love</Body>
    </CardShell>
  );
}

function LockedCard({ ai, onUnlock }: { ai: AiAnalysis; onUnlock: () => void }) {
  const teasers = [["🧠", "Attachment style", "violet"], ["💞", `Vibe score: ${ai.vibeScore || 78}/100`, "lime"], ["🚩", "Red flags", "pink"], ["🔥", "The roast", "tangerine"]] as const;
  return (
    <CardShell accent="lime">
      <Display size={18} color={ACCENT_HEX.lime}>THE VERDICT IS IN</Display>
      <div className="mt-1"><Display size={32} style={{ lineHeight: 1.1 }}>Unlock your<br />full report 🔓</Display></div>
      <div className="relative my-5 flex-1 space-y-3 overflow-hidden">
        {teasers.map((t, i) => (
          <div key={i} className="flex items-center gap-3.5 rounded-[18px] px-4 py-4 border" style={{ background: `${ACCENT_HEX[t[2]]}24`, borderColor: `${ACCENT_HEX[t[2]]}66` }}>
            <span className="text-[22px]">{t[0]}</span><span className="flex-1"><Display size={16}>{t[1]}</Display></span><span className="text-textMid">🔒</span>
          </div>
        ))}
        <div className="pointer-events-none absolute inset-x-0 bottom-0 h-20" style={{ background: "linear-gradient(transparent,#0B0B0F)" }} />
      </div>
      <ChunkyButton label="UNLOCK FULL REPORT" onClick={onUnlock} />
      <div className="mt-2 text-center"><Body size={12} color="#6C6C7E">3-day free trial · cancel anytime</Body></div>
    </CardShell>
  );
}

/* ---- share slide + 9:16 card ---- */
function ShareSlide({ stats, analysis, otherName, onRestart }: { stats: ChatStats; analysis: AiAnalysis; otherName: string; onRestart: () => void }) {
  const cardRef = useRef<HTMLDivElement>(null);
  const [busy, setBusy] = useState(false);

  const share = async () => {
    if (!cardRef.current) return;
    setBusy(true);
    try {
      const dataUrl = await toPng(cardRef.current, { pixelRatio: 3, cacheBust: true });
      const blob = await (await fetch(dataUrl)).blob();
      const file = new File([blob], "tikboo-wrapped.png", { type: "image/png" });
      const navAny = navigator as any;
      if (navAny.canShare && navAny.canShare({ files: [file] })) {
        await navAny.share({ files: [file], text: "my chat, decoded 🍵 made with tikboo" });
      } else {
        const a = document.createElement("a");
        a.href = dataUrl; a.download = "tikboo-wrapped.png"; a.click();
      }
    } catch { /* user cancelled */ } finally { setBusy(false); }
  };

  return (
    <CardShell accent="lime">
      <div className="text-center"><Display size={28}>THAT&apos;S A WRAP</Display><div className="mt-1"><Body size={14}>share your verdict ✨</Body></div></div>
      <div className="my-4 flex flex-1 items-center justify-center overflow-hidden">
        <div className="origin-center" style={{ transform: "scale(0.62)" }}>
          <ShareCard ref={cardRef} stats={stats} analysis={analysis} otherName={otherName} />
        </div>
      </div>
      <ChunkyButton label={busy ? "CREATING…" : "SHARE TO STORY"} loading={busy} onClick={share} />
      <button onClick={onRestart} className="mt-3 text-center"><Body size={14} weight={700}>analyze another chat</Body></button>
    </CardShell>
  );
}

import { forwardRef } from "react";
const ShareCard = forwardRef<HTMLDivElement, { stats: ChatStats; analysis: AiAnalysis; otherName: string }>(
  function ShareCard({ stats, analysis, otherName }, ref) {
    const you = stats.people.map((p) => p.name).find((n) => n !== otherName) || "You";
    const names = stats.isGroup ? `${stats.people.length} legends` : `${you}  ×  ${otherName || stats.people[1]?.name || "them"}`;
    const stat = (v: string, l: string, c: string) => (
      <div className="flex-1"><Display size={22} color={c}>{v}</Display><div><Body size={11}>{l}</Body></div></div>
    );
    return (
      <div ref={ref} className="relative overflow-hidden bg-ink" style={{ width: 360, height: 640 }}>
        <div className="blob" style={{ top: -60, left: -40, width: 240, height: 240, background: "radial-gradient(circle,#8B5CFF99,transparent 70%)" }} />
        <div className="blob" style={{ bottom: -40, right: -50, width: 260, height: 260, background: "radial-gradient(circle,#FF4D9D99,transparent 70%)" }} />
        <div className="relative flex h-full flex-col p-7">
          <div className="flex items-center gap-1.5">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/logo.png" alt="" width={24} height={24} />
            <Display size={16}>tikboo</Display>
            <span className="flex-1" />
            <Display size={12} color="#AFAFC0">WRAPPED</Display>
          </div>
          <div className="flex-1 flex flex-col justify-center">
            <div className="text-[64px] leading-none">{analysis.vibeEmoji || "🍵"}</div>
            <div className="mt-2"><Display size={30} color={ACCENT_HEX.lime} style={{ lineHeight: 1.05 }}>{analysis.vibeTitle || "Certified Chat"}</Display></div>
            <div className="mt-2"><Display size={15}>{names}</Display></div>
            {analysis.summary && <div className="mt-3"><Body size={13}>{analysis.summary.slice(0, 180)}</Body></div>}
          </div>
          <div className="flex gap-1">
            {analysis.vibeScore > 0 && stat(`${analysis.vibeScore}`, "vibe", ACCENT_HEX.lime)}
            {stat(compact(stats.totalMessages), "texts", ACCENT_HEX.cyan)}
            {stat(stats.topEmojiOverall, "top", ACCENT_HEX.pink)}
            {stat(`${stats.longestStreakDays}d`, "streak", ACCENT_HEX.tangerine)}
          </div>
          <div className="mt-4 text-center"><span className="rounded-full border border-stroke bg-inkCard/70 px-3.5 py-2"><Display size={12}>Made with tikboo 🍵</Display></span></div>
        </div>
      </div>
    );
  }
);
