"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import { unzipSync, strFromU8 } from "fflate";
import { parseChat, resolveOtherPerson } from "@/lib/parser";
import { buildDigest, computeStats } from "@/lib/stats";
import type { AiAnalysis, ChatStats, Subject } from "@/lib/types";
import { Home, ContextStep, Analyzing, Screen } from "@/components/screens";
import { Results } from "@/components/Results";
import { Body, ChunkyButton, Display, ACCENT_HEX } from "@/components/ui";
import { Credits } from "@/lib/credits";

type Stage = "home" | "context" | "analyzing" | "results" | "history" | "settings";

const PRIVACY_URL = "/privacy";
const TERMS_URL = "/terms";

const subjectLabel = (s: Subject) => (s === "girl" ? "a girl" : s === "guy" ? "a guy" : "a group");

interface HistoryEntry {
  id: string; savedAt: number; title: string; vibeEmoji: string; vibeTitle: string;
  vibeScore: number; relationship: string; otherName: string; stats: ChatStats; analysis: AiAnalysis;
}

export default function Page() {
  const [stage, setStage] = useState<Stage>("home");
  const [busy, setBusy] = useState(false);
  const [stats, setStats] = useState<ChatStats | null>(null);
  const [otherName, setOtherName] = useState("");
  const [analysis, setAnalysis] = useState<AiAnalysis | null>(null);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [reportId, setReportId] = useState("");
  const ctxRef = useRef<{ subject: Subject; relationship: string }>({ subject: "group", relationship: "Friend" });

  // Returning from DodoPayments checkout — verify, top up credits, resume report.
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (params.get("dodo") !== "return") return;
    const pid = localStorage.getItem("tikboo_pending_payment");
    const cleanUrl = () => window.history.replaceState({}, "", "/");
    if (!pid) { cleanUrl(); return; }
    (async () => {
      try {
        const res = await fetch(`/api/verify?payment_id=${encodeURIComponent(pid)}`);
        const data = await res.json();
        if (data.paid) {
          const credits = parseInt(localStorage.getItem("tikboo_pending_credits") || "0", 10);
          if (credits > 0) Credits.add(credits);
          localStorage.removeItem("tikboo_pending_payment");
          localStorage.removeItem("tikboo_pending_credits");
          const resume = localStorage.getItem("tikboo_resume");
          localStorage.removeItem("tikboo_resume");
          if (resume) {
            const r = JSON.parse(resume);
            Credits.unlock(r.reportId); // spend one credit to open this report
            setStats(r.stats); setAnalysis(r.analysis);
            setOtherName(r.otherName); setReportId(r.reportId);
            setStage("results");
          } else {
            setStage("settings"); // bought from Settings — show the new balance
          }
        }
      } catch { /* ignore */ } finally { cleanUrl(); }
    })();
  }, []);

  const handleFile = useCallback(async (file: File) => {
    setBusy(true); setError(null);
    try {
      const buf = await file.arrayBuffer();
      let text: string;
      if (file.name.toLowerCase().endsWith(".zip")) {
        const files = unzipSync(new Uint8Array(buf));
        const txtName = Object.keys(files).find((n) => n.toLowerCase().endsWith(".txt"));
        if (!txtName) throw new Error("No .txt chat file found inside the zip.");
        text = strFromU8(files[txtName]);
      } else {
        text = new TextDecoder("utf-8").decode(buf);
      }
      const msgs = parseChat(text);
      const s = computeStats(msgs);
      setStats(s);
      setOtherName(resolveOtherPerson(s.people.map((p) => p.name), file.name));
      setStage("context");
    } catch (e: any) {
      alert(e?.message ?? "Couldn't read that file.");
    } finally {
      setBusy(false);
    }
  }, []);

  const runAnalysis = useCallback(async (s: ChatStats, subject: Subject, relationship: string, other: string) => {
    setReady(false); setError(null); setAnalysis(null);
    const you = s.isGroup ? undefined : s.people.map((p) => p.name).find((n) => n !== other);
    const digest = buildDigest(s, { subjectLabel: subjectLabel(subject), relationship, otherName: other });
    try {
      const res = await fetch("/api/analyze", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ digest, you }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Analysis failed.");
      setAnalysis(data.analysis as AiAnalysis);
      setReady(true);
    } catch (e: any) {
      setError(e?.message ?? "Something went wrong.");
    }
  }, []);

  const onContextDone = (subject: Subject, relationship: string) => {
    if (!stats) return;
    ctxRef.current = { subject, relationship };
    setStage("analyzing");
    runAnalysis(stats, subject, relationship, otherName);
  };

  const saveHistory = (id: string, s: ChatStats, a: AiAnalysis, other: string, relationship: string) => {
    try {
      const entry: HistoryEntry = {
        id, savedAt: Date.now(),
        title: s.isGroup ? "Group chat" : other || s.people[0]?.name || "Chat",
        vibeEmoji: a.vibeEmoji, vibeTitle: a.vibeTitle, vibeScore: a.vibeScore,
        relationship, otherName: other, stats: s, analysis: a,
      };
      const list: HistoryEntry[] = JSON.parse(localStorage.getItem("tikboo_history") || "[]");
      list.unshift(entry);
      localStorage.setItem("tikboo_history", JSON.stringify(list.slice(0, 50)));
    } catch { /* ignore */ }
  };

  const onComplete = () => {
    const id = `${Date.now()}`;
    setReportId(id);
    if (stats && analysis) saveHistory(id, stats, analysis, otherName, ctxRef.current.relationship);
    setStage("results");
  };

  const restart = () => {
    setStage("home"); setStats(null); setAnalysis(null); setOtherName(""); setReady(false); setError(null);
  };

  if (stage === "home") return <Home onFile={handleFile} onOpenHistory={() => setStage("history")} onOpenSettings={() => setStage("settings")} busy={busy} />;
  if (stage === "context" && stats)
    return <ContextStep stats={stats} otherName={otherName} onBack={restart} onDone={onContextDone} />;
  if (stage === "analyzing")
    return <Analyzing ready={ready} error={error} subjectInitial={(otherName || "✨")[0]?.toUpperCase() || "✨"}
      onComplete={onComplete} onRetry={() => runAnalysis(stats!, ctxRef.current.subject, ctxRef.current.relationship, otherName)} />;
  if (stage === "results" && stats && analysis)
    return <Results stats={stats} analysis={analysis} otherName={otherName} reportId={reportId} onRestart={restart} />;
  if (stage === "history")
    return <HistoryView onBack={restart} onOpen={(e) => { setStats(e.stats); setAnalysis(e.analysis); setOtherName(e.otherName); setReportId(e.id); setStage("results"); }} />;
  if (stage === "settings")
    return <SettingsView onBack={restart} />;
  return <Home onFile={handleFile} onOpenHistory={() => setStage("history")} onOpenSettings={() => setStage("settings")} busy={busy} />;
}

function SettingsView({ onBack }: { onBack: () => void }) {
  const [credits, setCredits] = useState(0);
  const [busy, setBusy] = useState<string | null>(null);
  useEffect(() => { setCredits(Credits.get()); }, []);

  const buy = async (pack: "single" | "pack") => {
    setBusy(pack);
    try {
      const res = await fetch("/api/checkout", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ pack }),
      });
      const data = await res.json();
      if (!res.ok || !data.url) throw new Error(data.error || "Checkout failed");
      localStorage.setItem("tikboo_pending_payment", data.paymentId);
      localStorage.setItem("tikboo_pending_credits", String(data.credits));
      localStorage.removeItem("tikboo_resume"); // buying from settings, no report to resume
      window.location.href = data.url;
    } catch (e: any) {
      alert(e?.message || "Something went wrong");
      setBusy(null);
    }
  };

  return (
    <Screen colors={["cyan", "violet", "lime"]}>
      <button onClick={onBack} className="self-start p-2 text-textHi text-lg">←</button>
      <div className="mt-1"><Display size={24}>SETTINGS</Display></div>

      <div className="mt-6 rounded-[22px] border-2 border-lime bg-lime/10 p-5 text-center">
        <Display size={44} color={ACCENT_HEX.lime}>{credits}</Display>
        <div className="mt-1"><Body size={14} weight={700} color="#F5F5F7">{credits === 1 ? "report credit" : "report credits"}</Body></div>
        <div className="mt-1"><Body size={12}>1 credit unlocks 1 full report</Body></div>
      </div>

      <div className="mt-6"><Display size={15} color={ACCENT_HEX.pink}>BUY CREDITS</Display></div>
      <div className="mt-3 space-y-3">
        <button onClick={() => buy("pack")} disabled={!!busy}
          className="flex w-full items-center rounded-[20px] border border-stroke bg-inkCard px-5 py-4 text-left active:scale-[0.99]">
          <div className="flex-1">
            <div className="flex items-center gap-2"><Display size={17}>10 reports</Display><span className="rounded-lg bg-lime px-2 py-0.5"><Display size={10} color="#0B0B0F">BEST VALUE</Display></span></div>
            <div className="mt-1"><Body size={13}>just $0.40 each</Body></div>
          </div>
          <Display size={20} color={ACCENT_HEX.lime}>{busy === "pack" ? "…" : "$4"}</Display>
        </button>
        <button onClick={() => buy("single")} disabled={!!busy}
          className="flex w-full items-center rounded-[20px] border border-stroke bg-inkCard px-5 py-4 text-left active:scale-[0.99]">
          <div className="flex-1"><Display size={17}>1 report</Display><div className="mt-1"><Body size={13}>unlock a single report</Body></div></div>
          <Display size={20} color={ACCENT_HEX.lime}>{busy === "single" ? "…" : "$1"}</Display>
        </button>
      </div>

      <div className="mt-7 flex items-center gap-3">
        <a href={PRIVACY_URL} target="_blank" rel="noreferrer"><Body size={12} color="#AFAFC0">Privacy</Body></a>
        <Body size={12} color="#6C6C7E">·</Body>
        <a href={TERMS_URL} target="_blank" rel="noreferrer"><Body size={12} color="#AFAFC0">Terms</Body></a>
      </div>
      <div className="mt-2"><Body size={11} color="#6C6C7E">Credits are stored on this device. Secure checkout by DodoPayments.</Body></div>
    </Screen>
  );
}

function HistoryView({ onBack, onOpen }: { onBack: () => void; onOpen: (e: HistoryEntry) => void }) {
  const [list, setList] = useState<HistoryEntry[] | null>(null);
  useEffect(() => {
    try { setList(JSON.parse(localStorage.getItem("tikboo_history") || "[]")); } catch { setList([]); }
  }, []);
  const del = (id: string) => {
    const next = (list || []).filter((e) => e.id !== id);
    setList(next); localStorage.setItem("tikboo_history", JSON.stringify(next));
  };
  const deck = ["#CBFF4D", "#FF4D9D", "#8B5CFF", "#45E0FF", "#FF8A3D"];
  return (
    <Screen colors={["cyan", "pink", "violet"]}>
      <button onClick={onBack} className="self-start p-2 text-textHi">←</button>
      <div className="mt-1"><Display size={24}>HISTORY</Display></div>
      <div className="mt-4 flex-1 space-y-3 overflow-y-auto">
        {list === null ? (
          <Body>Loading…</Body>
        ) : list.length === 0 ? (
          <div className="mt-16 text-center"><div className="text-[56px]">🗂️</div><div className="mt-3"><Display size={22}>No reports yet</Display></div><div className="mt-2"><Body>Analyze a chat and it&apos;ll show up here.</Body></div></div>
        ) : (
          list.map((e, i) => (
            <div key={e.id} className="flex items-center gap-3.5 rounded-[20px] border border-stroke bg-inkCard p-4">
              <button onClick={() => onOpen(e)} className="flex flex-1 items-center gap-3.5 text-left">
                <span className="grid h-12 w-12 place-items-center rounded-2xl text-[24px]" style={{ background: `${deck[i % 5]}2E` }}>{e.vibeEmoji}</span>
                <span className="flex-1">
                  <Display size={17}>{e.title}</Display>
                  <div><Body size={13}>{e.relationship} · {e.vibeTitle || "tap to view"}</Body></div>
                </span>
                {e.vibeScore > 0 && <Display size={20} color={deck[i % 5]}>{e.vibeScore}</Display>}
              </button>
              <button onClick={() => del(e.id)} className="px-1 text-textLow">🗑</button>
            </div>
          ))
        )}
      </div>
    </Screen>
  );
}
