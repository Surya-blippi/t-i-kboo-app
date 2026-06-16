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
  useEffect(() => { setCredits(Credits.get()); }, []);
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
      <div className="mt-3 text-center"><Body size={12} color="#6C6C7E">🔒 analyzed securely · never stored or sold</Body></div>
      <div className="mt-2 flex items-center justify-center gap-3">
        <a href="/privacy"><Body size={11} color="#6C6C7E">Privacy</Body></a>
        <Body size={11} color="#6C6C7E">·</Body>
        <a href="/terms"><Body size={11} color="#6C6C7E">Terms</Body></a>
      </div>
    </Screen>
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
