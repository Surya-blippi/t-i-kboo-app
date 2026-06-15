"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import { unzipSync, strFromU8 } from "fflate";
import { parseChat, resolveOtherPerson } from "@/lib/parser";
import { buildDigest, computeStats } from "@/lib/stats";
import type { AiAnalysis, ChatStats, Subject } from "@/lib/types";
import { Home, ContextStep, Analyzing, Screen } from "@/components/screens";
import { Results } from "@/components/Results";
import { Body, ChunkyButton, Display } from "@/components/ui";

type Stage = "home" | "context" | "analyzing" | "results" | "history";

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
  const ctxRef = useRef<{ subject: Subject; relationship: string }>({ subject: "group", relationship: "Friend" });

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

  const saveHistory = (s: ChatStats, a: AiAnalysis, other: string, relationship: string) => {
    try {
      const entry: HistoryEntry = {
        id: `${Date.now()}`, savedAt: Date.now(),
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
    if (stats && analysis) saveHistory(stats, analysis, otherName, ctxRef.current.relationship);
    setStage("results");
  };

  const restart = () => {
    setStage("home"); setStats(null); setAnalysis(null); setOtherName(""); setReady(false); setError(null);
  };

  if (stage === "home") return <Home onFile={handleFile} onOpenHistory={() => setStage("history")} busy={busy} />;
  if (stage === "context" && stats)
    return <ContextStep stats={stats} otherName={otherName} onBack={restart} onDone={onContextDone} />;
  if (stage === "analyzing")
    return <Analyzing ready={ready} error={error} subjectInitial={(otherName || "✨")[0]?.toUpperCase() || "✨"}
      onComplete={onComplete} onRetry={() => runAnalysis(stats!, ctxRef.current.subject, ctxRef.current.relationship, otherName)} />;
  if (stage === "results" && stats && analysis)
    return <Results stats={stats} analysis={analysis} otherName={otherName} onRestart={restart} />;
  if (stage === "history")
    return <HistoryView onBack={restart} onOpen={(e) => { setStats(e.stats); setAnalysis(e.analysis); setOtherName(e.otherName); setStage("results"); }} />;
  return <Home onFile={handleFile} onOpenHistory={() => setStage("history")} busy={busy} />;
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
