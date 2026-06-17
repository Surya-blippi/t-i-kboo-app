"use client";
import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Blobs, Body, ChunkyButton, Display, cx, ACCENT_HEX } from "./ui";
import { Credits } from "@/lib/credits";
import type { ChatStats, Subject } from "@/lib/types";

/* ---------------- HOME ---------------- */
export function Home({
  onFile, onOpenHistory, onOpenSettings, busy,
}: { onFile: (f: File) => void; onOpenHistory: () => void; onOpenSettings: () => void; busy: boolean }) {
  const input = useRef<HTMLInputElement>(null);
  const [credits, setCredits] = useState(0);
  const [showHow, setShowHow] = useState(false);
  useEffect(() => { setCredits(Credits.get()); }, []);

  const openWhatsApp = () => {
    const ua = navigator.userAgent || "";
    const isMobile = /iphone|ipad|ipod|android/i.test(ua);
    // Mobile → the app; desktop → WhatsApp Web.
    window.open(isMobile ? "whatsapp://" : "https://web.whatsapp.com", "_blank");
  };
  return (
    <Screen colors={["violet", "pink", "lime"]}>
      <div className="flex items-center justify-between">
        <Logo />
        <div className="flex items-center gap-1">
          {credits > 0 && (
            <button onClick={onOpenSettings} className="mr-1 rounded-full border border-stroke bg-inkCard px-2.5 py-1">
              <Body size={12} weight={700} color="#CBFF4D">{credits} 🎟️</Body>
            </button>
          )}
          <button onClick={onOpenHistory} aria-label="History" className="p-2 text-textMid">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 3v5h5" /><path d="M3.05 13A9 9 0 106 5.3L3 8" /><path d="M12 7v5l4 2" /></svg>
          </button>
          <button onClick={onOpenSettings} aria-label="Settings" className="p-2 text-textMid">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 11-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 11-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 112.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 112.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"/></svg>
          </button>
        </div>
      </div>
      <div className="flex-1 flex flex-col justify-center">
        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }}>
          <Display size={46} style={{ lineHeight: 1.02 }}>YOUR CHAT,</Display>
        </motion.div>
        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.12 }}>
          <Display size={46} color={ACCENT_HEX.lime} style={{ lineHeight: 1.02 }}>DECODED.</Display>
        </motion.div>
        <div className="mt-4 max-w-md">
          <Body size={16}>Upload a WhatsApp chat export and get a Wrapped-style breakdown plus an AI vibe check. The receipts are receipt-ing.</Body>
        </div>
        <div className="mt-7"><Steps /></div>
      </div>
      <input ref={input} type="file" accept=".txt,.zip,text/plain" className="hidden"
        onChange={(e) => { const f = e.target.files?.[0]; if (f) onFile(f); e.currentTarget.value = ""; }} />
      <ChunkyButton label={busy ? "READING…" : "UPLOAD CHAT"} loading={busy} onClick={() => input.current?.click()} />
      <button onClick={openWhatsApp}
        className="mt-3 flex w-full items-center justify-center gap-2 rounded-[22px] border border-stroke bg-inkCard py-4 active:scale-[0.99]">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="#CBFF4D"><path d="M12.04 2c-5.46 0-9.91 4.45-9.91 9.91 0 1.75.46 3.45 1.32 4.95L2 22l5.25-1.38a9.9 9.9 0 004.79 1.22h.01c5.46 0 9.91-4.45 9.91-9.91 0-2.65-1.03-5.14-2.9-7.01A9.82 9.82 0 0012.04 2zm5.8 14.18c-.24.68-1.42 1.31-1.95 1.36-.5.05-1.13.07-1.83-.11-.42-.13-.96-.31-1.66-.61-2.92-1.26-4.83-4.2-4.98-4.4-.14-.2-1.18-1.57-1.18-3 0-1.42.75-2.12 1.01-2.41.27-.29.58-.36.78-.36l.56.01c.18.01.42-.07.66.5.24.59.82 2.03.89 2.18.07.14.12.31.02.5-.09.2-.14.31-.28.48-.14.17-.3.38-.42.5-.14.14-.29.29-.12.57.17.29.74 1.22 1.59 1.98 1.1.98 2.02 1.28 2.31 1.42.29.14.46.12.63-.07.17-.2.72-.84.91-1.13.19-.29.39-.24.66-.14.27.1 1.7.8 1.99.95.29.14.48.22.55.34.07.12.07.69-.17 1.37z"/></svg>
        <Body size={15} weight={800} color="#F5F5F7">Open WhatsApp</Body>
      </button>
      <button onClick={() => setShowHow(true)} className="mt-3 text-center">
        <Body size={14} weight={700} color="#AFAFC0">📖 How do I export a chat?</Body>
      </button>
      <div className="mt-2 text-center"><Body size={12} color="#6C6C7E">🔒 analyzed securely · never stored or sold</Body></div>
      <div className="mt-2 flex items-center justify-center gap-3">
        <a href="/privacy"><Body size={11} color="#6C6C7E">Privacy</Body></a>
        <Body size={11} color="#6C6C7E">·</Body>
        <a href="/terms"><Body size={11} color="#6C6C7E">Terms</Body></a>
      </div>
      {showHow && <HowToModal onClose={() => setShowHow(false)} />}
    </Screen>
  );
}

function HowToModal({ onClose }: { onClose: () => void }) {
  const [tab, setTab] = useState<"iphone" | "android">("iphone");
  const iphone = [
    "Open WhatsApp and go to the chat you want analyzed (a person or a group).",
    "Tap the contact or group name at the very top to open its info page.",
    "Scroll all the way down and tap “Export Chat”.",
    "When asked, choose “Without Media” (it’s faster and all we need).",
    "In the share sheet, tap “Save to Files”, pick a place (e.g. “On My iPhone”), and tap Save.",
    "Come back here, tap “UPLOAD CHAT”, open Files, and pick the chat you just saved (a .txt or .zip).",
  ];
  const android = [
    "Open WhatsApp and go to the chat you want analyzed.",
    "Tap the ⋮ menu (three dots, top-right).",
    "Tap “More”, then “Export chat”.",
    "Choose “Without Media” when asked.",
    "Choose “Save to Files” / “Files” (or save to Downloads).",
    "Come back here, tap “UPLOAD CHAT”, and pick the chat file you saved (a .txt or .zip).",
  ];
  const steps = tab === "iphone" ? iphone : android;
  return (
    <motion.div className="absolute inset-0 z-40 overflow-y-auto bg-ink"
      initial={{ y: "100%" }} animate={{ y: 0 }} transition={{ type: "spring", damping: 28 }}>
      <div className="mx-auto flex min-h-full w-full max-w-[480px] flex-col px-6 pb-8 pt-4">
        <button onClick={onClose} className="self-end p-2 text-textMid text-lg">✕</button>
        <Display size={30}>HOW TO USE</Display>
        <div className="mt-1"><Body size={14}>Export your chat from WhatsApp, then upload it here. Takes ~20 seconds.</Body></div>

        <div className="mt-5 flex gap-2 rounded-2xl bg-inkCard p-1">
          {(["iphone", "android"] as const).map((t) => (
            <button key={t} onClick={() => setTab(t)}
              className="flex-1 rounded-xl py-2.5"
              style={tab === t ? { background: ACCENT_HEX.lime } : {}}>
              <Display size={14} color={tab === t ? "#0B0B0F" : "#AFAFC0"}>
                {t === "iphone" ? "iPhone" : "Android"}
              </Display>
            </button>
          ))}
        </div>

        <div className="mt-5 flex-1 space-y-3">
          {steps.map((s, i) => (
            <div key={i} className="flex gap-3.5">
              <span className="grid h-8 w-8 shrink-0 place-items-center rounded-xl"
                style={{ background: ACCENT_HEX[["pink","violet","cyan","lime","tangerine","pink"][i]] }}>
                <Display size={14} color="#0B0B0F">{i + 1}</Display>
              </span>
              <div className="pt-0.5"><Body size={15} color="#F5F5F7">{s}</Body></div>
            </div>
          ))}
        </div>

        <div className="mt-4 rounded-2xl border border-stroke bg-inkCard p-4">
          <Body size={13}>💡 Tip: “Without Media” keeps it quick. We only read the messages to build your report — nothing is stored or shared.</Body>
        </div>

        <div className="mt-5">
          <ChunkyButton label="GOT IT" onClick={onClose} />
        </div>
      </div>
    </motion.div>
  );
}

function Logo() {
  return (
    <div className="flex items-center gap-2">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/logo.png" alt="tikboo" width={38} height={38} />
      <Display size={22}>tikboo</Display>
    </div>
  );
}

function Steps() {
  const steps: [string, string, string][] = [["1", "Export", "pink"], ["2", "Upload", "violet"], ["3", "Get read", "cyan"]];
  return (
    <div className="flex gap-2.5">
      {steps.map((s) => (
        <div key={s[0]} className="flex-1 rounded-[18px] border border-stroke bg-inkCard py-4 text-center">
          <Display size={22} color={ACCENT_HEX[s[2]]}>{s[0]}</Display>
          <div className="mt-1"><Body size={12} weight={700} color="#AFAFC0">{s[1]}</Body></div>
        </div>
      ))}
    </div>
  );
}

/* ---------------- CONTEXT (who + relationship) ---------------- */
export function ContextStep({
  stats, otherName, onDone, onBack,
}: { stats: ChatStats; otherName: string; onDone: (subject: Subject, relationship: string) => void; onBack: () => void }) {
  const isGroup = stats.isGroup;
  const [step, setStep] = useState(isGroup ? 1 : 0);
  const [subject, setSubject] = useState<Subject | null>(isGroup ? "group" : null);
  const [rel, setRel] = useState<string | null>(null);
  const name = isGroup ? "the group" : otherName || stats.people[0]?.name || "them";
  const canGo = step === 0 ? !!subject : !!rel;

  const back = () => { if (step === 1 && !isGroup) setStep(0); else onBack(); };
  const next = () => { if (step === 0) setStep(1); else onDone(subject ?? "group", rel ?? "Friend"); };

  return (
    <Screen colors={step === 0 ? ["pink", "violet", "cyan"] : ["violet", "lime", "pink"]}>
      <button onClick={back} className="self-start p-2 text-textHi" aria-label="Back">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M19 12H5M12 19l-7-7 7-7" /></svg>
      </button>
      <div className="flex-1 mt-2">
        <AnimatePresence mode="wait">
          {step === 0 ? (
            <motion.div key="g" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Display size={20} color="#AFAFC0">WHO IS</Display><br />
              <Display size={38} color={ACCENT_HEX.pink}>{name}?</Display>
              <div className="mt-7 flex gap-3.5">
                <GenderCard emoji="👩" label="A girl" sel={subject === "girl"} accent="pink" onClick={() => setSubject("girl")} />
                <GenderCard emoji="🧑" label="A guy" sel={subject === "guy"} accent="cyan" onClick={() => setSubject("guy")} />
              </div>
            </motion.div>
          ) : (
            <motion.div key="r" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <Display size={20} color="#AFAFC0">WHAT&apos;S THE VIBE</Display><br />
              <Display size={30} color={ACCENT_HEX.violet}>with {name}?</Display>
              <div className="mt-5 flex flex-col gap-2.5">
                {([["😳","Crush"],["🌀","Situationship"],["💞","Together"],["🪦","Ex"],["👯","Friend"],["🫂","Family"]] as const).map((o, i) => (
                  <RelTile key={o[1]} emoji={o[0]} label={o[1]} sel={rel === o[1]} accent={["lime","pink","violet","cyan","tangerine"][i % 5]} onClick={() => setRel(o[1])} />
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
      <ChunkyButton label={step === 0 ? "CONTINUE" : "ANALYZE THE CHAT"} accent="lime" disabled={!canGo} onClick={next} />
    </Screen>
  );
}

function GenderCard({ emoji, label, sel, accent, onClick }: { emoji: string; label: string; sel: boolean; accent: string; onClick: () => void }) {
  const hex = ACCENT_HEX[accent];
  return (
    <button onClick={onClick} className={cx("flex-1 rounded-[22px] py-7 border-2 transition", sel ? "" : "border-stroke bg-inkCard")}
      style={sel ? { borderColor: hex, background: `${hex}24` } : {}}>
      <div className="text-[56px] leading-none">{emoji}</div>
      <div className="mt-3"><Display size={18} color="#F5F5F7">{label}</Display></div>
    </button>
  );
}

function RelTile({ emoji, label, sel, accent, onClick }: { emoji: string; label: string; sel: boolean; accent: string; onClick: () => void }) {
  const hex = ACCENT_HEX[accent];
  return (
    <button onClick={onClick} className={cx("flex items-center gap-3.5 rounded-[18px] px-4 py-4 border-2 text-left transition", sel ? "" : "border-stroke bg-inkCard")}
      style={sel ? { borderColor: hex, background: `${hex}24` } : {}}>
      <span className="grid h-11 w-11 place-items-center rounded-xl bg-ink text-[22px]">{emoji}</span>
      <span className="flex-1"><Display size={17} color="#F5F5F7">{label}</Display></span>
      <span style={{ color: sel ? hex : "#6C6C7E" }}>{sel ? "●" : "○"}</span>
    </button>
  );
}

/* ---------------- ANALYZING ---------------- */
const STEPS = ["Reading the chat", "Anonymising the messages", "Detecting red flags", "Reading message patterns", "Cooking the verdict"];
export function Analyzing({ ready, error, onComplete, onRetry, subjectInitial }: {
  ready: boolean; error: string | null; onComplete: () => void; onRetry: () => void; subjectInitial: string;
}) {
  const [active, setActive] = useState(0);
  const readyRef = useRef(ready);
  readyRef.current = ready;
  useEffect(() => {
    if (error) return;
    const t = setInterval(() => {
      setActive((a) => {
        const cap = readyRef.current ? STEPS.length : STEPS.length - 1;
        const nv = a < cap ? a + 1 : a;
        if (nv >= STEPS.length && readyRef.current) { clearInterval(t); setTimeout(onComplete, 250); }
        return nv;
      });
    }, 850);
    return () => clearInterval(t);
  }, [error, onComplete]);

  const progress = Math.min(active / STEPS.length, 1);

  if (error) {
    return (
      <Screen colors={["pink", "violet", "cyan"]}>
        <div className="flex-1 flex flex-col justify-center">
          <div className="text-[56px]">😵‍💫</div>
          <Display size={28}>HIT A SNAG</Display>
          <div className="mt-2 mb-6"><Body size={15}>{error}</Body></div>
          <ChunkyButton label="TRY AGAIN" onClick={onRetry} />
        </div>
      </Screen>
    );
  }
  return (
    <Screen colors={["violet", "lime", "cyan"]}>
      <div className="flex-1 flex flex-col">
        <div className="mx-auto mt-2 grid h-20 w-20 place-items-center rounded-full" style={{ background: "linear-gradient(135deg,#8B5CFF,#45E0FF)" }}>
          <Display size={34}>{subjectInitial}</Display>
        </div>
        <div className="mt-5 text-center"><Display size={28} style={{ lineHeight: 1.1 }}>Analyzing your<br />conversation…</Display></div>
        <div className="mt-6 flex justify-between"><Body size={14}>Analyzing…</Body><Display size={16} color={ACCENT_HEX.lime}>{Math.round(progress * 100)}%</Display></div>
        <div className="mt-2 h-2.5 w-full overflow-hidden rounded-full bg-inkCard">
          <motion.div className="h-full bg-lime" animate={{ width: `${progress * 100}%` }} />
        </div>
        <div className="mt-6 flex flex-col gap-3">
          {STEPS.map((s, i) => {
            const done = i < active, act = i === active;
            return (
              <div key={s} className={cx("flex items-center gap-3.5 rounded-[18px] px-4 py-4 border", done ? "border-lime/40" : act ? "border-lime bg-inkCard" : "border-stroke bg-inkSoft")}
                style={done ? { background: "#CBFF4D1A" } : {}}>
                <span className={cx("grid h-9 w-9 place-items-center rounded-xl", done ? "" : "bg-ink")} style={done ? { background: "#CBFF4D2E" } : {}}>
                  {done ? "✅" : act ? <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-lime border-t-transparent" /> : "○"}
                </span>
                <Display size={15} color={done || act ? "#F5F5F7" : "#6C6C7E"}>{s}…</Display>
              </div>
            );
          })}
        </div>
      </div>
      <div className="rounded-2xl bg-lime/10 py-3 text-center"><Body size={13} weight={600}>🔒 Analyzed securely · never stored or sold</Body></div>
    </Screen>
  );
}

/* ---------------- shell ---------------- */
export function Screen({ children, colors }: { children: React.ReactNode; colors?: [string, string, string] }) {
  return (
    <div className="relative mx-auto flex min-h-[100dvh] w-full max-w-[480px] flex-col px-6 pb-7 pt-3">
      <Blobs colors={colors} />
      <div className="relative z-10 flex flex-1 flex-col">{children}</div>
    </div>
  );
}
