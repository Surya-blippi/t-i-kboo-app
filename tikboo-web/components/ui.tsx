"use client";
import { motion } from "framer-motion";
import { ReactNode } from "react";

export function cx(...c: (string | false | undefined)[]) {
  return c.filter(Boolean).join(" ");
}

export const ACCENTS = ["lime", "pink", "violet", "cyan", "tangerine"] as const;
export const ACCENT_HEX: Record<string, string> = {
  lime: "#CBFF4D", pink: "#FF4D9D", violet: "#8B5CFF",
  cyan: "#45E0FF", tangerine: "#FF8A3D",
};

export function onAccentText(accent: string) {
  // lime/cyan/tangerine are light → dark text; pink/violet → light text
  return accent === "lime" || accent === "cyan" || accent === "tangerine"
    ? "#0B0B0F" : "#F5F5F7";
}

export function Blobs({ colors }: { colors?: [string, string, string] }) {
  const c = colors ?? ["violet", "pink", "lime"];
  const hex = c.map((x) => ACCENT_HEX[x] ?? x);
  return (
    <div className="absolute inset-0 overflow-hidden">
      <div className="blob" style={{ top: -120, left: -80, width: 320, height: 320, background: `radial-gradient(circle, ${hex[0]}88, transparent 70%)` }} />
      <div className="blob" style={{ top: 160, right: -110, width: 300, height: 300, background: `radial-gradient(circle, ${hex[1]}88, transparent 70%)` }} />
      <div className="blob" style={{ bottom: -140, left: -60, width: 360, height: 360, background: `radial-gradient(circle, ${hex[2]}88, transparent 70%)` }} />
      <div className="absolute inset-0 bg-ink/60" />
    </div>
  );
}

export function ChunkyButton({
  label, onClick, accent = "lime", disabled, loading, icon,
}: {
  label: string; onClick?: () => void; accent?: string;
  disabled?: boolean; loading?: boolean; icon?: ReactNode;
}) {
  const bg = ACCENT_HEX[accent] ?? accent;
  const fg = onAccentText(accent);
  const off = disabled || loading;
  return (
    <motion.button
      whileTap={off ? undefined : { y: 3, scale: 0.99 }}
      onClick={off ? undefined : onClick}
      disabled={off}
      className="w-full rounded-[22px] px-7 py-5 font-display font-extrabold text-[17px] flex items-center justify-center gap-2.5"
      style={{
        background: off ? `${bg}59` : bg,
        color: fg,
        boxShadow: off ? "none" : `0 10px 28px ${bg}59`,
      }}
    >
      {loading ? (
        <span className="inline-block h-5 w-5 animate-spin rounded-full border-[3px] border-current border-t-transparent" />
      ) : (
        <>
          {icon}
          {label}
        </>
      )}
    </motion.button>
  );
}

export function Display({ children, size = 28, color = "#F5F5F7", className = "", style }: {
  children: ReactNode; size?: number; color?: string; className?: string; style?: React.CSSProperties;
}) {
  return (
    <span className={cx("font-display font-extrabold tracking-tight leading-tight", className)}
      style={{ fontSize: size, color, ...style }}>
      {children}
    </span>
  );
}

export function Body({ children, size = 15, color = "#AFAFC0", className = "", weight = 500 }: {
  children: ReactNode; size?: number; color?: string; className?: string; weight?: number;
}) {
  return (
    <span className={cx("font-body", className)}
      style={{ fontSize: size, color, fontWeight: weight, lineHeight: 1.5 }}>
      {children}
    </span>
  );
}
