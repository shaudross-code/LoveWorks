import { useEffect, useState } from "react";
import api from "@/lib/api";
import { visualFor } from "@/lib/awards";
import { Trophy, Lock } from "lucide-react";

export default function Awards() {
  const [data, setData] = useState({ items: [], earned_count: 0, total: 0 });

  useEffect(() => {
    (async () => {
      try { const { data } = await api.get("/awards"); setData(data); }
      catch { /* noop */ }
    })();
  }, []);

  const pct = data.total ? Math.round((data.earned_count / data.total) * 100) : 0;

  return (
    <div className="space-y-8">
      <div>
        <div className="text-xs uppercase tracking-widest text-yellow-400">Awards</div>
        <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">Trophy case.</h1>
        <p className="mt-2 text-zinc-400">Earn medals by completing tasks, hitting streaks, and beating deadlines.</p>
      </div>

      <div className="bg-gradient-to-br from-yellow-400 to-yellow-300 text-black rounded-2xl p-6 flex items-center gap-5">
        <div className="w-14 h-14 rounded-2xl bg-black/10 grid place-items-center">
          <Trophy className="w-7 h-7" />
        </div>
        <div className="flex-1">
          <div className="text-xs uppercase tracking-widest opacity-70">Progress</div>
          <div className="font-display text-3xl font-bold tracking-tight" data-testid="awards-progress">
            {data.earned_count} / {data.total} earned
          </div>
          <div className="mt-2 h-2 bg-black/15 rounded-full overflow-hidden">
            <div className="h-full bg-black/70 rounded-full transition-all" style={{ width: `${pct}%` }} />
          </div>
        </div>
        <div className="font-display text-4xl font-bold tabular-nums">{pct}%</div>
      </div>

      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {data.items.map((a) => {
          const { Icon, accent, text } = visualFor(a.icon);
          return (
            <div key={a.code} data-testid={`award-${a.code}`}
              className={`relative rounded-2xl p-5 border transition ${
                a.earned
                  ? "bg-[#121214] border-yellow-400/30 hover:-translate-y-0.5 hover:shadow-lg hover:shadow-yellow-400/10"
                  : "bg-[#0e0e10] border-zinc-800 opacity-70"
              }`}>
              <div className="flex items-start gap-4">
                <div className={`relative w-16 h-16 rounded-2xl grid place-items-center bg-gradient-to-br ${accent} ${text} ${a.earned ? "" : "grayscale opacity-50"}`}>
                  <Icon className="w-8 h-8" />
                  {a.earned && (
                    <span className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-green-500 text-white text-[10px] grid place-items-center font-bold">
                      ✓
                    </span>
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-display text-lg font-semibold text-white">{a.title}</div>
                  <div className="text-xs text-zinc-400 mt-1">{a.description}</div>
                  {a.earned ? (
                    <div className="mt-2 inline-flex items-center gap-1 text-[10px] uppercase tracking-widest text-yellow-400">
                      Earned {a.earned_at ? new Date(a.earned_at).toLocaleDateString(undefined,{month:"short",day:"numeric"}) : ""}
                    </div>
                  ) : (
                    <div className="mt-2 inline-flex items-center gap-1 text-[10px] uppercase tracking-widest text-zinc-500">
                      <Lock className="w-3 h-3" /> Locked
                    </div>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
