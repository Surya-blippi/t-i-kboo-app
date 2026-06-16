import Link from "next/link";

export function LegalDoc({ title, body }: { title: string; body: string }) {
  const lines = body.trim().split("\n");
  return (
    <div className="min-h-[100dvh] bg-ink text-textHi">
      <div className="mx-auto w-full max-w-[680px] px-6 py-10">
        <Link href="/" className="font-body text-sm text-textMid">← back to tikboo</Link>
        <h1 className="mt-5 font-display text-3xl font-extrabold tracking-tight">{title}</h1>
        <div className="mt-6 space-y-1">
          {lines.map((raw, i) => {
            const line = raw.trim();
            if (!line) return <div key={i} className="h-3" />;
            if (line.startsWith("## "))
              return (
                <h2 key={i} className="pt-4 pb-1 font-display text-base font-extrabold text-lime">
                  {line.slice(3)}
                </h2>
              );
            if (line.startsWith("- "))
              return (
                <p key={i} className="flex gap-2 font-body text-[15px] leading-relaxed text-textHi">
                  <span className="text-textMid">•</span>
                  <span>{line.slice(2)}</span>
                </p>
              );
            return (
              <p key={i} className="font-body text-[15px] leading-relaxed text-textHi">
                {line}
              </p>
            );
          })}
        </div>
      </div>
    </div>
  );
}
