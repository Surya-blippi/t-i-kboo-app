"use client";
import { useState } from "react";
import { motion } from "framer-motion";
import { ACCENT_HEX, Body, ChunkyButton, Display } from "./ui";
import type { AiAnalysis, ChatStats } from "@/lib/types";

const BENEFITS: [string, string, string][] = [
  ["🧠", "The full AI read", "Vibe, roast, attachment style & score"],
  ["🚩", "Every red flag, decoded", "With the real receipts"],
  ["🔒", "Private & secure", "Analyzed for your eyes — never sold"],
  ["🔖", "Unlimited chats", "Unlock every report, forever"],
];

const PRICE = process.env.NEXT_PUBLIC_UNLOCK_PRICE || "₹149";

export function Paywall({
  report, onClose,
}: {
  report: { stats: ChatStats; analysis: AiAnalysis; otherName: string };
  onClose: () => void;
}) {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const unlock = async () => {
    setBusy(true); setErr(null);
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });
      const data = await res.json();
      if (!res.ok || !data.url) throw new Error(data.error || "Couldn't start checkout.");
      // Stash so we can restore + unlock when the user returns from checkout.
      localStorage.setItem("tikboo_pending_payment", data.paymentId);
      localStorage.setItem("tikboo_resume", JSON.stringify(report));
      window.location.href = data.url;
    } catch (e: any) {
      setErr(e?.message || "Something went wrong.");
      setBusy(false);
    }
  };

  return (
    <motion.div className="absolute inset-0 z-30 overflow-y-auto bg-ink"
      initial={{ y: "100%" }} animate={{ y: 0 }} transition={{ type: "spring", damping: 28 }}>
      <div className="mx-auto flex min-h-full w-full max-w-[480px] flex-col px-6 pb-6 pt-4">
        <button onClick={onClose} className="self-start p-2 text-textMid">✕</button>
        <Display size={22}>UNLOCK THE</Display>
        <Display size={38} color={ACCENT_HEX.lime}>FULL TEA 🍵</Display>

        <div className="mt-6 space-y-3.5">
          {BENEFITS.map((b) => (
            <div key={b[1]} className="flex items-center gap-3.5">
              <span className="grid h-12 w-12 place-items-center rounded-2xl border border-stroke bg-inkCard text-[22px]">{b[0]}</span>
              <div><Display size={15}>{b[1]}</Display><div><Body size={13}>{b[2]}</Body></div></div>
            </div>
          ))}
        </div>

        <div className="mt-7 rounded-[22px] border-2 border-lime bg-lime/10 px-5 py-5 text-center">
          <Display size={40} color={ACCENT_HEX.lime}>{PRICE}</Display>
          <div className="mt-1"><Body size={14} weight={700} color="#F5F5F7">one-time · unlock forever</Body></div>
          <div className="mt-1"><Body size={12}>no subscription, no auto-renew</Body></div>
        </div>

        {err && <div className="mt-3 text-center"><Body size={13} color={ACCENT_HEX.pink}>{err}</Body></div>}

        <div className="mt-6">
          <ChunkyButton label={busy ? "OPENING CHECKOUT…" : `UNLOCK FOR ${PRICE}`} loading={busy} onClick={unlock} />
          <div className="mt-3 flex items-center justify-center gap-2">
            <Body size={11} color="#6C6C7E">🔒 Secure checkout by DodoPayments · UPI & cards</Body>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
