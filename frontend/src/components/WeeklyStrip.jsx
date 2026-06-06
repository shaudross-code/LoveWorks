import { useState } from "react";
import { Flame } from "lucide-react";

const DAY_LABELS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

function fmtHours(h) {
  if (!h) return "0h";
  if (h < 1) return `${Math.round(h * 60)}m`;
  const whole = Math.floor(h);
  const mins = Math.round((h - whole) * 60);
  return mins ? `${whole}h ${mins}m` : `${whole}h`;
}

/**
 * Reusable 7-day strip with rich hover/click popover.
 * Props:
 *  - days: [{day, count, earned, hours, titles}, ...] length 7 (Mon..Sun)
 *  - streak: number (consecutive days ending today)
 *  - title: optional header text (default "Completed this week")
 *  - dense: smaller variant
 */
export default function WeeklyStrip({ days = [], streak = 0, title = "Completed this week", dense = false }) {
  const [hovered, setHovered] = useState(null); // day index
  const todayIdx = (new Date().getDay() + 6) % 7;

  // Determine which days are part of the active streak ending today
  const streakSet = new Set();
  for (let i = 0; i < streak; i += 1) streakSet.add(todayIdx - i);

  return (
    <div className="relative">
      <div className="flex items-center justify-between mb-2">
        <div className="text-[10px] uppercase tracking-widest text-zinc-500">{title}</div>
        {streak >= 2 && (
          <div data-testid="weekly-streak"
            className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-gradient-to-r from-orange-500 to-yellow-400 text-black text-[10px] font-bold uppercase tracking-widest shadow-md">
            <Flame className="w-3 h-3" /> {streak}-day streak
          </div>
        )}
      </div>
      <div className="grid grid-cols-7 gap-1.5">
        {days.map((d, i) => {
          const has = d.count > 0;
          const isToday = i === todayIdx;
          const isStreak = streakSet.has(i) && has;
          return (
            <button
              key={d.day || DAY_LABELS[i]}
              type="button"
              onMouseEnter={() => setHovered(i)}
              onMouseLeave={() => setHovered(null)}
              onClick={() => setHovered((cur) => (cur === i ? null : i))}
              data-testid={`weekly-day-${d.day || DAY_LABELS[i]}`}
              className={`relative rounded-lg ${dense ? "py-1.5" : "py-2"} text-center border transition outline-none ${
                has
                  ? "bg-gradient-to-br from-yellow-400 to-amber-500 text-black border-yellow-500 hover:-translate-y-0.5"
                  : "bg-zinc-900/60 text-zinc-500 border-zinc-800 hover:bg-zinc-900"
              } ${isToday ? "ring-2 ring-yellow-400/60" : ""}`}
            >
              {isStreak && (
                <Flame className="absolute -top-1.5 -right-1.5 w-3.5 h-3.5 text-orange-500 fill-orange-500 drop-shadow" />
              )}
              <div className={`text-[9px] uppercase tracking-widest font-semibold ${has ? "opacity-80" : ""}`}>{d.day || DAY_LABELS[i]}</div>
              <div className={`font-display ${dense ? "text-sm" : "text-base"} font-bold tabular-nums ${has ? "" : "text-zinc-600"}`}>{d.count}</div>
            </button>
          );
        })}
      </div>

      {hovered != null && (() => {
        const d = days[hovered];
        if (!d) return null;
        // anchor popover near the hovered tile
        const left = `${(hovered + 0.5) * (100 / 7)}%`;
        return (
          <div
            className="absolute z-30 -translate-x-1/2 mt-2 w-60 bg-[#0f0f12] border border-yellow-400/30 rounded-xl p-3 shadow-2xl pointer-events-none"
            style={{ left, top: "100%" }}
          >
            <div className="flex items-center justify-between">
              <div className="font-display font-semibold">{d.day}</div>
              <div className="text-[10px] uppercase tracking-widest text-zinc-500">
                {hovered === todayIdx ? "Today" : ""}
              </div>
            </div>
            <div className="mt-1 text-sm">
              <span className="text-white font-semibold">{d.count}</span>
              <span className="text-zinc-400"> task{d.count === 1 ? "" : "s"} · </span>
              <span className="text-yellow-400 font-semibold">${(d.earned || 0).toFixed(2)}</span>
              <span className="text-zinc-400"> · </span>
              <span className="text-emerald-400 font-semibold">{fmtHours(d.hours)}</span>
            </div>
            {d.titles && d.titles.length > 0 && (
              <ul className="mt-2 text-xs text-zinc-300 space-y-0.5 list-disc list-inside">
                {d.titles.map((t, k) => <li key={k} className="truncate">{t}</li>)}
              </ul>
            )}
            {!d.count && <div className="text-xs text-zinc-500 mt-1">Nothing logged yet.</div>}
          </div>
        );
      })()}
    </div>
  );
}
