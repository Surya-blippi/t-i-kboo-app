"use client";
import { useState } from "react";
import { motion } from "framer-motion";
import { ACCENT_HEX, Body, ChunkyButton, Display, cx } from "./ui";

const BENEFITS: [string, string, string][] = [
  ["🧠", "The full AI read", "Vibe, roast, attachment style & score"],
  ["🚩", "Every red flag, decoded", "Plus the green flags you missed"],
  ["🔒", "Private & secure", "Analyzed for your eyes — never sold"],
  ["🔖", "Unlimited chats", "Analyze every DM and group, anytime"],
];

export function Paywall({ onClose, onUnlocked }: { onClose: () => void; onUnlocked: () => void }) {
  const [exclusive, setExclusive] = useState(true);
  const [plan, setPlan] = useState<"yearly" | "weekly">("yearly");
  const [busy, setBusy] = useState(false);

  const plans = {
    yearly: { title: "Yearly", price: exclusive ? "₹499 / year" : "₹999 / year", per: exclusive ? "≈ ₹9.6/wk" : "≈ ₹19/wk", badge: exclusive ? "80% OFF" : "BEST VALUE", trial: false },
    weekly: { title: "Weekly", price: "₹199 / week", per: "3-day free trial", badge: "", trial: true },
  } as const;
  const sel = plans[plan];

  const start = () => { setBusy(true); setTimeout(onUnlocked, 500); };

  return (
    <motion.div className="absolute inset-0 z-30 overflow-y-auto bg-ink" initial={{ y: "100%" }} animate={{ y: 0 }} transition={{ type: "spring", damping: 28 }}>
      <div className="mx-auto flex min-h-full w-full max-w-[480px] flex-col px-6 pb-6 pt-4">
        <div className="flex items-center justify-between">
          <button onClick={onClose} className="p-2 text-textMid">✕</button>
          <button onClick={onUnlocked} className="p-2"><Body size={14} weight={700}>Restore</Body></button>
        </div>
        <Display size={22}>UNLOCK THE</Display>
        <Display size={38} color={ACCENT_HEX.lime}>FULL TEA 🍵</Display>
        <div className="mt-5 space-y-3.5">
          {BENEFITS.map((b) => (
            <div key={b[1]} className="flex items-center gap-3.5">
              <span className="grid h-12 w-12 place-items-center rounded-2xl border border-stroke bg-inkCard text-[22px]">{b[0]}</span>
              <div><Display size={15}>{b[1]}</Display><div><Body size={13}>{b[2]}</Body></div></div>
            </div>
          ))}
        </div>

        <button onClick={() => setExclusive((v) => !v)} className="mt-5 flex items-center gap-2.5 rounded-2xl border px-4 py-2.5 text-left"
          style={{ borderColor: exclusive ? ACCENT_HEX.lime : "#2A2A38", background: `linear-gradient(90deg, ${exclusive ? "#CBFF4D2E" : "#CBFF4D10"}, #1C1C26)` }}>
          <span>🏷️</span><span className="flex-1"><Display size={14}>EXCLUSIVE OFFER</Display></span>
          <span className={cx("h-6 w-11 rounded-full p-0.5 transition", exclusive ? "bg-lime" : "bg-inkSoft")}>
            <span className={cx("block h-5 w-5 rounded-full bg-white transition", exclusive ? "translate-x-5" : "")} />
          </span>
        </button>

        <div className="mt-3 space-y-3">
          {(["yearly", "weekly"] as const).map((k) => {
            const p = plans[k]; const on = plan === k;
            return (
              <button key={k} onClick={() => setPlan(k)} className="flex w-full items-center rounded-[20px] border-2 px-4 py-4 text-left transition"
                style={on ? { borderColor: ACCENT_HEX.lime, background: "#CBFF4D1F" } : { borderColor: "#2A2A38", background: "#1C1C26" }}>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <Display size={18}>{p.title}</Display>
                    {p.badge && <span className="rounded-lg bg-lime px-2 py-0.5"><Display size={10} color="#0B0B0F">{p.badge}</Display></span>}
                  </div>
                  <div className="mt-1"><Body size={14} weight={700} color="#F5F5F7">{p.price}</Body></div>
                </div>
                <Body size={13}>{p.per}</Body>
                <span className="ml-2" style={{ color: on ? ACCENT_HEX.lime : "#6C6C7E" }}>{on ? "◉" : "○"}</span>
              </button>
            );
          })}
        </div>

        <div className="mt-5">
          <div className="mb-2 text-center"><Body size={13}>🛡 Cancel anytime, no commitments</Body></div>
          <ChunkyButton label={sel.trial ? "START FREE TRIAL" : "UNLOCK MY REPORT"} loading={busy} onClick={start} />
          <div className="mt-3 px-2 text-center">
            <Body size={10} color="#6C6C7E">
              {sel.trial ? "No payment now. After the trial, " : "Your subscription "}auto-renews at the price shown unless cancelled at least 24h before it ends. Payment is charged to your account. Manage anytime in settings.
            </Body>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
