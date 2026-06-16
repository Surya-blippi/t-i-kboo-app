// Local credit wallet — no backend. A credit unlocks one report.
// Unlocked report IDs are remembered so revisiting a report never re-charges.
const CREDITS_KEY = "tikboo_credits";
const UNLOCKED_KEY = "tikboo_unlocked_reports";

function readNum(key: string): number {
  if (typeof window === "undefined") return 0;
  const v = parseInt(localStorage.getItem(key) || "0", 10);
  return Number.isFinite(v) ? v : 0;
}

function readSet(key: string): Set<string> {
  if (typeof window === "undefined") return new Set();
  try {
    return new Set(JSON.parse(localStorage.getItem(key) || "[]"));
  } catch {
    return new Set();
  }
}

export const Credits = {
  get(): number {
    return readNum(CREDITS_KEY);
  },
  add(n: number) {
    localStorage.setItem(CREDITS_KEY, String(this.get() + n));
  },
  isUnlocked(reportId: string): boolean {
    return readSet(UNLOCKED_KEY).has(reportId);
  },
  /** Returns true if the report ends up unlocked (already was, or a credit was spent). */
  unlock(reportId: string): boolean {
    if (this.isUnlocked(reportId)) return true;
    const credits = this.get();
    if (credits <= 0) return false;
    localStorage.setItem(CREDITS_KEY, String(credits - 1));
    const set = readSet(UNLOCKED_KEY);
    set.add(reportId);
    localStorage.setItem(UNLOCKED_KEY, JSON.stringify([...set]));
    return true;
  },
};
