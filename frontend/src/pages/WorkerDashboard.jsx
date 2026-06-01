import { useEffect, useMemo, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Play, Square, Loader2, CheckCircle2, Circle, BadgeDollarSign, Sparkles } from "lucide-react";
import { toast } from "sonner";

function formatDuration(seconds) {
  const s = Math.max(0, Math.floor(seconds));
  const h = Math.floor(s / 3600).toString().padStart(2, "0");
  const m = Math.floor((s % 3600) / 60).toString().padStart(2, "0");
  const sec = (s % 60).toString().padStart(2, "0");
  return `${h}:${m}:${sec}`;
}

export default function WorkerDashboard() {
  const [active, setActive] = useState(null); // {id, clock_in} | null
  const [tasks, setTasks] = useState([]);
  const [entries, setEntries] = useState([]);
  const [now, setNow] = useState(Date.now());
  const [busy, setBusy] = useState(false);

  const load = async () => {
    const [a, t, e] = await Promise.all([
      api.get("/time/active"), api.get("/tasks"), api.get("/time/entries"),
    ]);
    setActive(a.data && a.data.id ? a.data : null);
    setTasks(t.data);
    setEntries(e.data);
  };
  useEffect(() => { load(); }, []);
  useEffect(() => { const id = setInterval(() => setNow(Date.now()), 1000); return () => clearInterval(id); }, []);

  const liveSeconds = active ? Math.floor((now - new Date(active.clock_in).getTime()) / 1000) : 0;

  const todayHours = useMemo(() => {
    const start = new Date(); start.setHours(0, 0, 0, 0);
    let total = 0;
    entries.forEach((e) => {
      if (!e.clock_out) return;
      const inT = new Date(e.clock_in).getTime();
      if (inT >= start.getTime()) total += e.duration_seconds || 0;
    });
    if (active) {
      const inT = new Date(active.clock_in).getTime();
      if (inT >= start.getTime()) total += liveSeconds;
    }
    return total / 3600;
  }, [entries, active, liveSeconds]);

  const earnings = useMemo(
    () => tasks.filter(t => t.status === "completed").reduce((s, t) => s + Number(t.price), 0),
    [tasks]
  );

  const clockIn = async () => {
    setBusy(true);
    try { await api.post("/time/clock-in"); toast.success("Clocked in. Get to it."); load(); }
    catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };
  const clockOut = async () => {
    setBusy(true);
    try { await api.post("/time/clock-out"); toast.success("Clocked out. Good work."); load(); }
    catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const setStatus = async (t, status) => {
    try { await api.patch(`/tasks/${t.id}`, { status }); load();
      if (status === "completed") toast.success(`+$${Number(t.price).toFixed(2)} earned`); }
    catch (e) { toast.error(formatApiError(e)); }
  };

  const groups = useMemo(() => ({
    open: tasks.filter(t => t.status !== "completed"),
    done: tasks.filter(t => t.status === "completed"),
  }), [tasks]);

  return (
    <div className="space-y-10">
      {/* Hero clock-in card */}
      <div className="relative overflow-hidden bg-[#121214] border border-yellow-400/15 rounded-3xl p-8 sm:p-12">
        <div className="absolute -top-32 -right-32 w-[420px] h-[420px] bg-yellow-400/10 rounded-full blur-3xl pointer-events-none" />
        <div className="relative grid md:grid-cols-2 gap-10 items-center">
          <div>
            <div className="text-xs uppercase tracking-widest text-yellow-400">{active ? "Currently working" : "Ready to start"}</div>
            <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">
              {active ? "You're on the clock." : "Punch in to begin."}
            </h1>
            <div className="mt-6 grid grid-cols-2 gap-4 max-w-md">
              <Tile label="Shift timer" value={active ? formatDuration(liveSeconds) : "00:00:00"} testid="shift-timer" />
              <Tile label="Today" value={`${todayHours.toFixed(2)}h`} testid="today-hours" />
              <Tile label="Earned (tasks)" value={`$${earnings.toFixed(2)}`} testid="earnings-total" accent="text-yellow-400" />
              <Tile label="Open tasks" value={groups.open.length} testid="open-task-count" />
            </div>
          </div>

          <div className="flex justify-center md:justify-end">
            {active ? (
              <Button data-testid="clock-out-btn" disabled={busy} onClick={clockOut}
                className="h-44 w-44 rounded-full bg-red-500 hover:bg-red-400 text-white font-display font-bold text-xl shadow-xl shadow-red-500/30 transition-transform hover:scale-105">
                <div className="flex flex-col items-center">
                  {busy ? <Loader2 className="w-7 h-7 animate-spin" /> : <Square className="w-9 h-9 mb-1" />}
                  Clock out
                </div>
              </Button>
            ) : (
              <Button data-testid="clock-in-btn" disabled={busy} onClick={clockIn}
                className="h-44 w-44 rounded-full bg-yellow-400 hover:bg-yellow-300 text-black font-display font-bold text-xl shadow-xl shadow-yellow-400/30 gold-pulse transition-transform hover:scale-105">
                <div className="flex flex-col items-center">
                  {busy ? <Loader2 className="w-7 h-7 animate-spin" /> : <Play className="w-9 h-9 mb-1" />}
                  Clock in
                </div>
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Tasks */}
      <section>
        <div className="flex items-end justify-between mb-4">
          <h2 className="font-display text-2xl font-semibold tracking-tight">Your tasks</h2>
          <div className="text-xs uppercase tracking-widest text-zinc-500">{groups.open.length} open · {groups.done.length} done</div>
        </div>

        <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl divide-y divide-yellow-400/5">
          {tasks.length === 0 && (
            <div className="p-10 text-center">
              <Sparkles className="w-7 h-7 text-yellow-400 mx-auto" />
              <div className="mt-3 font-display text-xl">No tasks yet</div>
              <div className="text-sm text-zinc-500">Your admin will assign them here.</div>
            </div>
          )}
          {[...groups.open, ...groups.done].map((t) => (
            <div key={t.id} data-testid={`worker-task-${t.id}`} className="px-5 sm:px-6 py-4 flex items-center gap-3">
              <button
                data-testid={`toggle-task-${t.id}`}
                onClick={() => setStatus(t, t.status === "completed" ? "assigned" : "completed")}
                className={`w-9 h-9 rounded-full grid place-items-center border transition ${
                  t.status === "completed"
                    ? "bg-green-500/20 border-green-400/40 text-green-400"
                    : "bg-zinc-900 border-yellow-400/20 text-zinc-500 hover:text-yellow-400"
                }`}
                aria-label={t.status === "completed" ? "Mark incomplete" : "Mark complete"}
              >
                {t.status === "completed" ? <CheckCircle2 className="w-5 h-5" /> : <Circle className="w-5 h-5" />}
              </button>
              <div className="flex-1 min-w-0">
                <div className={`font-medium ${t.status === "completed" ? "line-through text-zinc-500" : ""}`}>{t.title}</div>
                {t.description && <div className="text-xs text-zinc-500 mt-0.5 line-clamp-1">{t.description}</div>}
              </div>
              <div className="inline-flex items-center gap-1 text-yellow-400 font-display font-semibold">
                <BadgeDollarSign className="w-4 h-4" />{Number(t.price).toFixed(2)}
              </div>
              {t.status !== "completed" && (
                <Button data-testid={`worker-start-${t.id}`} size="sm" variant="ghost" onClick={() => setStatus(t, t.status === "in_progress" ? "assigned" : "in_progress")}
                  className={`rounded-full h-8 px-3 text-xs border ${
                    t.status === "in_progress"
                      ? "border-yellow-400/30 text-yellow-300 bg-yellow-400/10"
                      : "border-yellow-400/20 text-zinc-300 hover:text-yellow-400"
                  }`}>
                  {t.status === "in_progress" ? "Working…" : "Start"}
                </Button>
              )}
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

function Tile({ label, value, testid, accent }) {
  return (
    <div data-testid={testid} className="px-4 py-3 rounded-2xl bg-zinc-900/70 border border-zinc-800">
      <div className="text-[10px] uppercase tracking-widest text-zinc-500">{label}</div>
      <div className={`mt-1 font-display text-2xl font-bold tabular-nums ${accent || "text-white"}`}>{value}</div>
    </div>
  );
}
