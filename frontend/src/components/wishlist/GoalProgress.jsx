import { Percent, TrendingUp } from "lucide-react";
import { PERIOD_LABEL } from "@/lib/wishlist";

const PERIOD_KEYS = [["today", "Today"], ["week", "Week"], ["month", "Month"], ["year", "Year"]];
const money = (n) => `$${(n || 0).toFixed(2)}`;

// Period + allocation chips shown on every goal/trip card.
export function GoalChips({ g }) {
  return (
    <>
      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-sky-400/15 text-sky-300">
        <TrendingUp className="w-3 h-3" /> {PERIOD_LABEL[g.period || "weekly"]}
      </span>
      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-emerald-400/15 text-emerald-300">
        <Percent className="w-3 h-3" /> {Number(g.allocation_percent || 0)}% alloc
      </span>
    </>
  );
}

// Amount toward the target this period, progress bar, and today/week/month/year totals.
export default function GoalProgress({ g, noTargetText = "No target set" }) {
  const target = Number(g.target_amount || 0);
  const pct = g.progress?.pct_of_target || 0;
  return (
    <div className="mt-3">
      <div className="flex items-baseline gap-2 flex-wrap">
        <div className="font-display text-2xl font-bold tabular-nums text-yellow-400">{money(g.progress?.period_amount)}</div>
        {target > 0
          ? <div className="text-sm text-zinc-400">of ${target.toFixed(2)} · <span className="text-yellow-300">{pct}%</span> this {g.period || "weekly"}</div>
          : <div className="text-xs text-zinc-500">{noTargetText}</div>}
      </div>
      {target > 0 && (
        <div className="mt-2 h-2.5 bg-zinc-900 rounded-full overflow-hidden">
          <div className="h-full bg-gradient-to-r from-yellow-300 to-yellow-500 rounded-full transition-all" style={{ width: `${pct}%` }} />
        </div>
      )}
      <div className="mt-3 grid grid-cols-2 min-[400px]:grid-cols-4 gap-2 text-[11px]">
        {PERIOD_KEYS.map(([k, label]) => (
          <div key={k} className="rounded-lg bg-zinc-900/60 border border-zinc-800 px-2 py-1.5">
            <div className="uppercase tracking-widest text-zinc-500">{label}</div>
            <div className="font-display text-sm font-semibold text-white tabular-nums">{money(g.progress?.[k])}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
