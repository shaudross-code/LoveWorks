import { useEffect, useState } from "react";
import api from "@/lib/api";
import { Clock } from "lucide-react";
import { activityOf } from "@/lib/activities";

function fmt(dt) { if (!dt) return "—"; return new Date(dt).toLocaleString(); }
function dur(secs) {
  const s = Math.max(0, Math.floor(secs || 0));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  return `${h}h ${m}m`;
}

export default function WorkerHistory() {
  const [entries, setEntries] = useState([]);
  useEffect(() => { (async () => { const { data } = await api.get("/time/entries"); setEntries(data); })(); }, []);

  const total = entries.reduce((s, e) => s + (e.duration_seconds || 0), 0);

  return (
    <div className="space-y-8">
      <div>
        <div className="text-xs uppercase tracking-widest text-yellow-400">History</div>
        <h1 className="font-display text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight mt-2">Time entries.</h1>
        <p className="mt-2 text-zinc-400">Every shift, accounted for. Total time logged: <span className="text-white font-semibold">{dur(total)}</span>.</p>
      </div>

      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl divide-y divide-yellow-400/5">
        {entries.length === 0 && (
          <div className="p-10 text-center">
            <Clock className="w-7 h-7 text-yellow-400 mx-auto" />
            <div className="mt-3 font-display text-xl">No shifts yet</div>
            <div className="text-sm text-zinc-500">Clock in to log your first hours.</div>
          </div>
        )}
        {entries.map((e) => {
          const a = activityOf(e.activity);
          const Icon = a.icon;
          return (
            <div key={e.id} data-testid={`entry-${e.id}`} className="px-6 py-4 flex items-center gap-4 flex-wrap">
              <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs ${a.pill}`}>
                <Icon className="w-3 h-3" /> {a.label}
              </span>
              <div className="flex-1 min-w-[220px]">
                <div className="font-medium">{fmt(e.clock_in)}</div>
                <div className="text-xs text-zinc-500">→ {fmt(e.clock_out)}</div>
              </div>
              <div className="font-display text-xl text-yellow-400 font-semibold tabular-nums">
                {e.clock_out ? dur(e.duration_seconds) : <span className="text-green-400">In progress</span>}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
