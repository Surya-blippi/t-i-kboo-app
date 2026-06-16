"use client";
import { useState } from "react";
import { motion } from "framer-motion";
import { ACCENT_HEX, Body, ChunkyButton, Display, cx } from "./ui";
import type { AiAnalysis, ChatStats } from "@/lib/types";

const BENEFITS: [string, string, string][] = [
  ["🧠", "The full AI read", "Vibe, roast, attachment style & score"],
  ["🚩", "Every red flag, decoded", "With the real receipts"],
  ["🔒", "Private & secure", "Analyzed for your eyes — never sold"],
  ["🔖", "Use anytime", "Credits never expire"],
];

const PRICE_SINGLE = process.env.NEXT_PUBLIC_PRICE_SINGLE || "$1";
const PRICE_PACK = process.env.NEXT_PUBLIC_PRICE_PACK || "$4";

export interface PaywallReport {
  stats: ChatStats;
  analysis: AiAnalysis;
  otherName: string;
  reportId: string;
}

export function Paywall({
  report, onClose,
}: { report: PaywallReport; onClose: () => void }) {
  const [pack, setPack] = useState<"single" | "pack">("pack");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const checkout = async () => {
    setBusy(true); setErr(null);
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ pack }),
      });
      const data = await res.json();
      if (!res.ok || !data.url) throw new Error(data.error || "Couldn't start checkout.");
      localStorage.setItem("tikboo_pending_payment", data.paymentId);
      localStorage.setItem("tikboo_pending_credits", String(data.credits));
      localStorage.setItem("tikboo_resume", JSON.stringify(report));
      window.location.href = data.url;
    } catch (e: any) {
      setErr(e?.message || "Something went wrong.");
      setBusy(false);
    }
  };

  const Option = ({ id, title, price, sub, badge }: {
    id: "single" | "pack"; title: string; price: string; sub: string; badge?: string;
  }) => {
    const on = pack === id;
    return (
      <button onClick={() => setPack(id)}
        className="flex w-full items-center rounded-[20px] border-2 px-5 py-4 text-left transition active:scale-[0.99]"
        style={on ? { borderColor: ACCENT_HEX.lime, background: "#CBFF4D1F" } : { borderColor: "#2A2A38", background: "#1C1C26" }}>
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <Display size={18}>{title}</Display>
            {badge && <span className="rounded-lg bg-lime px-2 py-0.5"><Display size={10} color="#0B0B0F">{badge}</Display></span>}
          </div>
          <div className="mt-1"><Body size={13}>{sub}</Body></div>
        </div>
        <Display size={22} color={on ? ACCENT_HEX.lime : "#F5F5F7"}>{price}</Display>
        <span className="ml-3" style={{ color: on ? ACCENT_HEX.lime : "#6C6C7E" }}>{on ? "◉" : "○"}</span>
      </button>
    );
  };

  return (
    <motion.div className="absolute inset-0 z-30 overflow-y-auto bg-ink"
      initial={{ y: "100%" }} animate={{ y: 0 }} transition={{ type: "spring", damping: 28 }}>
      <div className="mx-auto flex min-h-full w-full max-w-[480px] flex-col px-6 pb-8 pt-4">
        <button onClick={onClose} className="self-start p-2 text-textMid text-lg">✕</button>
        <Display size={22}>UNLOCK THE</Display>
        <Display size={38} color={ACCENT_HEX.lime}>FULL TEA 🍵</Display>

        <div className="mt-6 space-y-3.5">
          {BENEFITS.map((b) => (
            <div key={b[1]} className="flex items-center gap-3.5">
              <span className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl border border-stroke bg-inkCard text-[22px]">{b[0]}</span>
              <div><Display size={15}>{b[1]}</Display><div><Body size={13}>{b[2]}</Body></div></div>
            </div>
          ))}
        </div>

        <div className="mt-7 space-y-3">
          <Option id="pack" title="10 reports" price={PRICE_PACK} sub="Best value · just $0.40 each" badge="SAVE 60%" />
          <Option id="single" title="1 report" price={PRICE_SINGLE} sub="Unlock this one report" />
        </div>

        {err && <div className="mt-3 text-center"><Body size={13} color={ACCENT_HEX.pink}>{err}</Body></div>}

        <div className="mt-6">
          <ChunkyButton
            label={busy ? "OPENING CHECKOUT…" : `BUY ${pack === "pack" ? "10 REPORTS" : "1 REPORT"}`}
            loading={busy}
            onClick={checkout}
          />
          <div className="mt-3 text-center">
            <Body size={11} color="#6C6C7E">🔒 Secure checkout by DodoPayments · cards & UPI · one-time, no subscription</Body>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
