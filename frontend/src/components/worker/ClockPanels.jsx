import { ACTIVITIES, activityOf } from "@/lib/activities";
import { fmtClock } from "@/lib/format";

export function Tile({ label, value, testid, accent, icon: Icon, sub }) {
  return (
    <div data-testid={testid} className="px-4 py-3 rounded-2xl bg-zinc-900/70 border border-zinc-800">
      <div className="text-[10px] uppercase tracking-widest text-zinc-500 flex items-center gap-1">
        {Icon && <Icon className="w-3 h-3" />} {label}
      </div>
      <div className={`mt-1 font-display text-2xl font-bold tabular-nums ${accent || "text-white"}`}>{value}</div>
      {sub && <div className="text-[10px] text-zinc-500 mt-0.5">{sub}</div>}
    </div>
  );
}

// Every running clock with its own Stop button.
export function ActiveClocks({ actives, now, busy, onStop }) {
  return (
    <div data-testid="active-clocks" className="relative mt-8 pt-8 border-t border-yellow-400/10">
      <div className="text-xs uppercase tracking-widest text-zinc-500 mb-3">Running clocks</div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        {actives.map((a) => {
          const act = activityOf(a.activity);
          return (
            <div key={a.id} data-testid={`active-clock-${a.activity}`} className="flex items-center gap-3 p-3 rounded-xl bg-zinc-900/70 border border-zinc-800">
              <div className={`w-10 h-10 rounded-full ${act.bg} ${act.text} grid place-items-center shrink-0`}><act.icon className="w-5 h-5" /></div>
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium truncate">{act.label}</div>
                <div className="text-xs text-zinc-500 tabular-nums">{fmtClock((now - new Date(a.clock_in).getTime()) / 1000)}</div>
              </div>
              <button data-testid={`stop-clock-${a.activity}`} disabled={busy} onClick={() => onStop(a.id)}
                className="text-xs px-2.5 h-8 rounded-full bg-red-500/15 text-red-400 hover:bg-red-500/25 transition">
                Stop
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// Activity picker for the first clock-in and for adding parallel clocks.
export function ActivityPicker({ actives, busy, onPick }) {
  const running = new Set(actives.map((a) => a.activity));
  return (
    <div data-testid="activity-picker" className="relative mt-8 pt-8 border-t border-yellow-400/10">
      <div className="text-xs uppercase tracking-widest text-zinc-500 mb-3">
        {actives.length > 0 ? "Add another clock — you can run several at once" : "What are you doing?"}
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
        {ACTIVITIES.map((a) => {
          const isRunning = running.has(a.key);
          return (
            <button key={a.key} data-testid={`activity-${a.key}`} disabled={busy || isRunning} onClick={() => onPick(a.key)}
              title={isRunning ? "Already running" : ""}
              className={`group flex flex-col items-center gap-2 p-4 rounded-2xl bg-zinc-900/70 border border-zinc-800 transition ${isRunning ? "opacity-40 cursor-not-allowed" : "hover:border-yellow-400/40 hover:-translate-y-0.5"}`}>
              <div className={`w-12 h-12 rounded-full ${a.bg} ${a.text} grid place-items-center group-hover:scale-110 transition-transform`}><a.icon className="w-5 h-5" /></div>
              <div className="font-medium text-sm">{a.label}</div>
              {isRunning && <div className="text-[10px] text-yellow-400 uppercase tracking-widest">running</div>}
            </button>
          );
        })}
      </div>
    </div>
  );
}
