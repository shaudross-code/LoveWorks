import { useEffect, useState, useCallback } from "react";
import api, { formatApiError } from "@/lib/api";
import Avatar from "@/components/Avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from "@/components/ui/dialog";
import { Plus, Trash2, UserPlus, Mail, BadgeCheck, Loader2, Wifi, WifiOff, Clock, ClipboardList } from "lucide-react";
import { toast } from "sonner";
import { activityOf } from "@/lib/activities";

function timeAgo(iso) {
  if (!iso) return "never";
  const s = Math.max(1, Math.floor((Date.now() - new Date(iso).getTime()) / 1000));
  if (s < 60) return `${s}s ago`;
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}
function fmtDuration(secs) {
  const s = Math.max(0, Math.floor(secs));
  const h = Math.floor(s / 3600).toString().padStart(2, "0");
  const m = Math.floor((s % 3600) / 60).toString().padStart(2, "0");
  const sec = (s % 60).toString().padStart(2, "0");
  return `${h}:${m}:${sec}`;
}

function ProgressBar({ done, required, accent = "bg-yellow-400" }) {
  const pct = required > 0 ? Math.min(100, Math.round((done / required) * 100)) : (done > 0 ? 100 : 0);
  return (
    <div className="h-2 bg-zinc-800 rounded-full overflow-hidden mt-2">
      <div className={`h-full ${accent} rounded-full transition-all`} style={{ width: `${pct}%` }} />
    </div>
  );
}

export default function AdminWorkers() {
  const [statuses, setStatuses] = useState([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ name: "", email: "", password: "" });
  const [busy, setBusy] = useState(false);
  const [now, setNow] = useState(Date.now());

  const load = useCallback(async () => {
    try { const { data } = await api.get("/admin/worker-status"); setStatuses(data); }
    catch (e) { toast.error(formatApiError(e)); }
  }, []);
  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    const poll = setInterval(load, 20000);
    return () => clearInterval(poll);
  }, [load]);
  useEffect(() => {
    const tick = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(tick);
  }, []);

  const create = async (e) => {
    e.preventDefault();
    setBusy(true);
    try {
      await api.post("/workers", form);
      toast.success("Worker invited", { description: `${form.name} can now sign in.` });
      setForm({ name: "", email: "", password: "" });
      setOpen(false);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const remove = async (w) => {
    if (!window.confirm(`Remove ${w.name}? This also deletes their tasks and time entries.`)) return;
    try {
      await api.delete(`/workers/${w.id}`);
      toast.success("Worker removed");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  };

  const onlineCount = statuses.filter(s => s.online).length;
  const clockedInCount = statuses.filter(s => s.currently_clocked_in).length;

  return (
    <div className="space-y-8">
      <div className="flex items-end justify-between gap-4 flex-wrap">
        <div>
          <div className="text-xs uppercase tracking-widest text-yellow-400">Crew · Live</div>
          <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">Your workers.</h1>
          <p className="mt-2 text-zinc-400 flex items-center gap-3">
            <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs bg-green-400/15 text-green-400">
              <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" /> {onlineCount} online
            </span>
            <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs bg-yellow-400/15 text-yellow-300">
              <Clock className="w-3 h-3" /> {clockedInCount} on the clock
            </span>
            <span className="text-xs text-zinc-500">· auto-refresh every 20s</span>
          </p>
        </div>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button data-testid="open-create-worker" className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-11 px-5">
              <UserPlus className="w-4 h-4 mr-2" /> New worker
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl" aria-describedby={undefined}>
            <DialogHeader>
              <DialogTitle className="font-display text-2xl">Invite a worker</DialogTitle>
            </DialogHeader>
            <form onSubmit={create} className="space-y-4">
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Full name</label>
                <Input data-testid="worker-name" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Email</label>
                <Input data-testid="worker-email" required type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Temporary password</label>
                <Input data-testid="worker-password" required minLength={6} type="text" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                <div className="text-xs text-zinc-500 mt-1">They&apos;ll use this to log in. Share it securely.</div>
              </div>
              <DialogFooter>
                <Button data-testid="submit-create-worker" type="submit" disabled={busy} className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Plus className="w-4 h-4 mr-2" /> Create worker</>}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <div className="grid lg:grid-cols-2 gap-4">
        {statuses.length === 0 && (
          <div className="col-span-full text-center bg-[#121214] border border-yellow-400/15 rounded-2xl p-10">
            <BadgeCheck className="w-8 h-8 text-yellow-400 mx-auto" />
            <div className="mt-3 font-display text-xl">No workers yet</div>
            <div className="text-sm text-zinc-500">Click &quot;New worker&quot; to invite your first teammate.</div>
          </div>
        )}
        {statuses.map((s) => {
          const w = s.worker;
          const activity = s.active_activity ? activityOf(s.active_activity) : null;
          const shiftSecs = s.active_clock_in_at
            ? Math.max(0, Math.floor((now - new Date(s.active_clock_in_at).getTime()) / 1000))
            : 0;
          return (
            <div key={w.id} data-testid={`worker-card-${w.id}`}
              className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-5">
              <div className="flex items-start gap-3">
                <div className="relative">
                  <Avatar url={w.avatar_url} name={w.name || w.email} size={52} />
                  <span data-testid={`presence-${w.id}`}
                    className={`absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full border-2 border-[#121214] ${
                      s.online ? "bg-green-400" : "bg-zinc-600"
                    } ${s.online ? "animate-pulse" : ""}`}
                    title={s.online ? "Online now" : `Last seen ${timeAgo(s.last_seen_at)}`}
                  />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <div className="font-display text-lg font-semibold truncate">{w.name}</div>
                    {s.online ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-green-400/15 text-green-400">
                        <Wifi className="w-3 h-3" /> online
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-zinc-800 text-zinc-400">
                        <WifiOff className="w-3 h-3" /> {timeAgo(s.last_seen_at)}
                      </span>
                    )}
                  </div>
                  <div className="text-xs text-zinc-500 flex items-center gap-1 truncate"><Mail className="w-3 h-3" /> {w.email}</div>
                  {s.currently_clocked_in && activity ? (
                    <div className="mt-2 inline-flex items-center gap-2">
                      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] ${activity.pill}`}>
                        <activity.icon className="w-3 h-3" /> {activity.label}
                      </span>
                      <span className="text-yellow-300 font-display font-semibold tabular-nums text-sm">{fmtDuration(shiftSecs)}</span>
                    </div>
                  ) : (
                    <div className="mt-2 text-[11px] text-zinc-500 uppercase tracking-widest">Off the clock</div>
                  )}
                </div>
                <button data-testid={`delete-worker-${w.id}`} onClick={() => remove(w)} className="text-zinc-500 hover:text-red-400 transition" aria-label="Remove worker">
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>

              <div className="mt-5 grid grid-cols-2 gap-3">
                <div className="bg-zinc-900/60 border border-zinc-800 rounded-xl p-3">
                  <div className="text-[10px] uppercase tracking-widest text-zinc-500">Today</div>
                  <div className="mt-1 font-display text-xl font-bold tabular-nums">
                    <span className="text-white">{s.today_worked_hours.toFixed(1)}h</span>
                    <span className="text-zinc-500 text-sm font-normal"> / {s.daily_required_hours.toFixed(1)}h</span>
                  </div>
                  <div className="text-[10px] text-zinc-500 mt-0.5">
                    {s.today_left_hours > 0
                      ? <span className="text-yellow-300">{s.today_left_hours.toFixed(1)}h left</span>
                      : <span className="text-green-400">Hit daily target</span>}
                  </div>
                  <ProgressBar done={s.today_worked_hours} required={s.daily_required_hours} accent="bg-yellow-400" />
                </div>
                <div className="bg-zinc-900/60 border border-zinc-800 rounded-xl p-3">
                  <div className="text-[10px] uppercase tracking-widest text-zinc-500">This week</div>
                  <div className="mt-1 font-display text-xl font-bold tabular-nums">
                    <span className="text-white">{s.week_worked_hours.toFixed(1)}h</span>
                    <span className="text-zinc-500 text-sm font-normal"> / {s.weekly_required_hours.toFixed(1)}h</span>
                  </div>
                  <div className="text-[10px] text-zinc-500 mt-0.5">
                    {s.week_left_hours > 0
                      ? <span className="text-yellow-300">{s.week_left_hours.toFixed(1)}h left</span>
                      : <span className="text-green-400">Weekly target hit</span>}
                  </div>
                  <ProgressBar done={s.week_worked_hours} required={s.weekly_required_hours} accent="bg-emerald-400" />
                </div>
              </div>
              <div className="mt-3 text-xs text-zinc-500 inline-flex items-center gap-1">
                <ClipboardList className="w-3 h-3" /> {s.open_tasks_count} open task{s.open_tasks_count === 1 ? "" : "s"}
              </div>

              {/* Weekly completion strip — Mon..Sun */}
              <div className="mt-4">
                <div className="text-[10px] uppercase tracking-widest text-zinc-500 mb-2">Completed this week</div>
                <div className="grid grid-cols-7 gap-1.5">
                  {(s.completions_by_day || []).map((d) => {
                    const todayIdx = (new Date().getDay() + 6) % 7; // 0=Mon
                    const isToday = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"][todayIdx] === d.day;
                    const has = d.count > 0;
                    return (
                      <div
                        key={d.day}
                        data-testid={`day-${w.id}-${d.day}`}
                        title={has ? `${d.day}: ${d.count} task${d.count === 1 ? "" : "s"} · $${d.earned.toFixed(2)}${d.titles?.length ? "\n• " + d.titles.join("\n• ") : ""}` : `${d.day}: nothing yet`}
                        className={`rounded-lg px-1 py-2 text-center border transition ${
                          has
                            ? "bg-gradient-to-br from-yellow-400 to-amber-500 text-black border-yellow-500"
                            : "bg-zinc-900/60 text-zinc-500 border-zinc-800"
                        } ${isToday ? "ring-2 ring-yellow-400/60" : ""}`}
                      >
                        <div className="text-[9px] uppercase tracking-widest font-semibold opacity-80">{d.day}</div>
                        <div className={`font-display text-base font-bold tabular-nums ${has ? "" : "text-zinc-600"}`}>{d.count}</div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
