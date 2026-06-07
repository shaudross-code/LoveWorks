import { useEffect, useMemo, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";
import {
  Play, Square, Loader2, CheckCircle2, Circle, BadgeDollarSign, Sparkles,
  CalendarClock, Calendar, AlertTriangle, Hourglass, TrendingUp, ArrowRight,
  Repeat, Wallet, Clock,
} from "lucide-react";
import { toast } from "sonner";
import GoalsCard from "@/components/GoalsCard";
import SpeakButton from "@/components/SpeakButton";
import WeeklyStrip from "@/components/WeeklyStrip";
import PushPrompt from "@/components/PushPrompt";
import { ACTIVITIES, activityOf } from "@/lib/activities";

function formatDuration(seconds) {
  const s = Math.max(0, Math.floor(seconds));
  const h = Math.floor(s / 3600).toString().padStart(2, "0");
  const m = Math.floor((s % 3600) / 60).toString().padStart(2, "0");
  const sec = (s % 60).toString().padStart(2, "0");
  return `${h}:${m}:${sec}`;
}

function startOfDay(d = new Date()) { const x = new Date(d); x.setHours(0, 0, 0, 0); return x; }
function endOfDay(d = new Date())   { const x = new Date(d); x.setHours(23, 59, 59, 999); return x; }
function startOfWeek(d = new Date()) {
  const x = startOfDay(d);
  const day = x.getDay(); // 0=Sun
  const diff = (day === 0 ? -6 : 1 - day); // Monday as week start
  x.setDate(x.getDate() + diff);
  return x;
}
function endOfWeek(d = new Date()) {
  const s = startOfWeek(d);
  const e = new Date(s); e.setDate(e.getDate() + 6); e.setHours(23, 59, 59, 999);
  return e;
}
function fmtDate(iso) {
  if (!iso) return null;
  try { return new Date(iso).toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" }); }
  catch { return null; }
}
const DOW_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
function fmtTime12(hhmm) {
  if (!hhmm) return "";
  const [h, m] = hhmm.split(":").map(Number);
  if (!Number.isFinite(h)) return hhmm;
  const ampm = h >= 12 ? "PM" : "AM";
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return `${h12}:${String(m).padStart(2, "0")} ${ampm}`;
}

export default function WorkerDashboard() {
  const [active, setActive] = useState(null); // includes activity
  const [tasks, setTasks] = useState([]);
  const [entries, setEntries] = useState([]);
  const [now, setNow] = useState(Date.now());
  const [busy, setBusy] = useState(false);
  const [pickerOpen, setPickerOpen] = useState(false);
  const [weekly, setWeekly] = useState({ streak_days: 0, completions_by_day: [] });

  const load = async () => {
    const [a, t, e, wk] = await Promise.all([
      api.get("/time/active"), api.get("/tasks"), api.get("/time/entries"), api.get("/me/weekly-activity"),
    ]);
    setActive(a.data && a.data.id ? a.data : null);
    setTasks(t.data);
    setEntries(e.data);
    setWeekly(wk.data);
  };
  useEffect(() => { load(); }, []);
  useEffect(() => { const id = setInterval(() => setNow(Date.now()), 1000); return () => clearInterval(id); }, []);

  const liveSeconds = active ? Math.floor((now - new Date(active.clock_in).getTime()) / 1000) : 0;
  const currentActivity = active ? activityOf(active.activity) : null;

  const todayHours = useMemo(() => {
    const start = startOfDay().getTime();
    let total = 0;
    entries.forEach((e) => {
      if (!e.clock_out) return;
      const inT = new Date(e.clock_in).getTime();
      if (inT >= start) total += e.duration_seconds || 0;
    });
    if (active) {
      const inT = new Date(active.clock_in).getTime();
      if (inT >= start) total += liveSeconds;
    }
    return total / 3600;
  }, [entries, active, liveSeconds]);

  const earnings = useMemo(
    () => tasks.filter(t => t.status === "completed").reduce((s, t) => s + Number(t.price), 0),
    [tasks]
  );

  // Deadlines / weekly potential
  const dl = useMemo(() => {
    const todayStart = startOfDay().getTime();
    const todayEnd = endOfDay().getTime();
    const weekStart = startOfWeek().getTime();
    const weekEnd = endOfWeek().getTime();
    const dueToday = [], dueThisWeek = [], overdue = [], anytime = [];
    let weeklyPotential = 0;
    let openTotal = 0;
    tasks.forEach((t) => {
      if (t.status === "completed") return;
      openTotal += Number(t.price);
      if (!t.due_at) { anytime.push(t); return; }
      const due = new Date(t.due_at).getTime();
      if (due < todayStart) overdue.push(t);
      else if (due <= todayEnd) dueToday.push(t);
      else if (due <= weekEnd) dueThisWeek.push(t);
      if (due >= weekStart && due <= weekEnd) weeklyPotential += Number(t.price);
    });
    return { dueToday, dueThisWeek, overdue, anytime, weeklyPotential, openTotal };
  }, [tasks]);

  const clockIn = async (activityKey) => {
    setBusy(true);
    try {
      await api.post("/time/clock-in", { activity: activityKey });
      toast.success(`Clocked in — ${activityOf(activityKey).label}`);
      setPickerOpen(false);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };
  const clockOut = async () => {
    setBusy(true);
    try { await api.post("/time/clock-out"); toast.success("Clocked out"); load(); }
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
      <PushPrompt />
      {/* Hero — clock in / activity */}
      <div className="relative overflow-hidden bg-[#121214] border border-yellow-400/15 rounded-3xl p-6 sm:p-10">
        <div className="absolute -top-32 -right-32 w-[420px] h-[420px] bg-yellow-400/10 rounded-full blur-3xl pointer-events-none" />
        <div className="relative grid lg:grid-cols-[1fr_auto] gap-8 items-center">
          <div className="min-w-0">
            <div className="text-xs uppercase tracking-widest text-yellow-400 flex items-center gap-2">
              {active ? <>Currently <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] ${currentActivity.pill}`}>
                <currentActivity.icon className="w-3 h-3" /> {currentActivity.label}
              </span></> : "Ready to start"}
            </div>
            <h1 className="font-display text-3xl sm:text-5xl font-bold tracking-tight mt-2">
              {active ? "You're on the clock." : "Punch in to begin."}
            </h1>

            {/* Tiles grid 3x2 — earned & weekly potential now visible */}
            <div className="mt-6 grid grid-cols-2 sm:grid-cols-3 gap-3 max-w-2xl">
              <Tile testid="shift-timer"      label="Shift timer"    value={active ? formatDuration(liveSeconds) : "00:00:00"} />
              <Tile testid="today-hours"      label="Today"          value={`${todayHours.toFixed(2)}h`} />
              <Tile testid="open-task-count"  label="Open tasks"     value={groups.open.length} />
              <Tile testid="earnings-total"   label="Earned"         value={`$${earnings.toFixed(2)}`} accent="text-yellow-400" />
              <Tile testid="weekly-potential" label="This week potential" value={`$${dl.weeklyPotential.toFixed(2)}`}
                    accent="text-yellow-400" icon={TrendingUp} sub={`if you finish ${dl.dueThisWeek.length + dl.dueToday.length} due tasks`} />
              <Tile testid="open-total"       label="All open value" value={`$${dl.openTotal.toFixed(2)}`} sub="across all open tasks" />
            </div>
          </div>

          <div className="flex justify-center lg:justify-end">
            {active ? (
              <div className="flex flex-col items-center gap-3">
                <div className={`relative h-44 w-44 rounded-full ${currentActivity.bg} grid place-items-center shadow-xl ${currentActivity.text} ring-4 ${currentActivity.ring}`}>
                  <div className="text-center">
                    <currentActivity.icon className="w-7 h-7 mx-auto" />
                    <div className="font-display font-bold mt-1 text-sm uppercase tracking-widest">{currentActivity.label}</div>
                    <div className="font-display font-bold tabular-nums text-lg mt-1">{formatDuration(liveSeconds)}</div>
                  </div>
                </div>
                <Button data-testid="clock-out-btn" disabled={busy} onClick={clockOut}
                  className="rounded-full h-11 px-6 bg-red-500 hover:bg-red-400 text-white font-semibold">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Square className="w-4 h-4 mr-2" /> Clock out</>}
                </Button>
              </div>
            ) : (
              <Button data-testid="clock-in-btn" disabled={busy} onClick={() => setPickerOpen((v) => !v)}
                className="h-44 w-44 rounded-full bg-yellow-400 hover:bg-yellow-300 text-black font-display font-bold text-xl shadow-xl shadow-yellow-400/30 gold-pulse transition-transform hover:scale-105">
                <div className="flex flex-col items-center">
                  <Play className="w-9 h-9 mb-1" /> Clock in
                </div>
              </Button>
            )}
          </div>
        </div>

        {/* Activity picker (slides in when Clock In is pressed) */}
        {!active && pickerOpen && (
          <div data-testid="activity-picker" className="relative mt-8 pt-8 border-t border-yellow-400/10">
            <div className="text-xs uppercase tracking-widest text-zinc-500 mb-3">What are you doing?</div>
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
              {ACTIVITIES.map((a) => (
                <button
                  key={a.key}
                  data-testid={`activity-${a.key}`}
                  disabled={busy}
                  onClick={() => clockIn(a.key)}
                  className={`group flex flex-col items-center gap-2 p-4 rounded-2xl bg-zinc-900/70 border border-zinc-800 hover:border-yellow-400/40 hover:-translate-y-0.5 transition`}
                >
                  <div className={`w-12 h-12 rounded-full ${a.bg} ${a.text} grid place-items-center group-hover:scale-110 transition-transform`}>
                    <a.icon className="w-5 h-5" />
                  </div>
                  <div className="font-medium text-sm">{a.label}</div>
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Deadlines */}
      <section data-testid="deadlines-section">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-yellow-400/10 text-yellow-400 grid place-items-center"><CalendarClock className="w-5 h-5" /></div>
          <div>
            <h2 className="font-display text-2xl font-semibold tracking-tight">Deadlines</h2>
            <p className="text-xs text-zinc-500 mt-0.5">What needs to ship today and this week.</p>
          </div>
        </div>

        <div className="grid md:grid-cols-2 gap-4">
          <DeadlineBucket
            testid="bucket-overdue" tone="red" icon={AlertTriangle}
            title="Overdue" empty="No overdue tasks — nice." tasks={dl.overdue} onComplete={(t) => setStatus(t, "completed")}
          />
          <DeadlineBucket
            testid="bucket-today" tone="yellow" icon={Calendar}
            title="Due today" empty="Nothing due today." tasks={dl.dueToday} onComplete={(t) => setStatus(t, "completed")}
          />
          <DeadlineBucket
            testid="bucket-week" tone="sky" icon={CalendarClock}
            title="Due this week" empty="Quiet week ahead." tasks={dl.dueThisWeek} onComplete={(t) => setStatus(t, "completed")}
          />
          <DeadlineBucket
            testid="bucket-anytime" tone="zinc" icon={Hourglass}
            title="Open · anytime" empty="Inbox zero." tasks={dl.anytime} onComplete={(t) => setStatus(t, "completed")}
          />
        </div>
      </section>

      {/* All Tasks */}
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
            <TaskRow key={t.id} t={t} onToggle={() => setStatus(t, t.status === "completed" ? "assigned" : "completed")}
              onStart={() => setStatus(t, t.status === "in_progress" ? "assigned" : "in_progress")} />
          ))}
        </div>
      </section>

      {/* Weekly completion strip */}
      <section data-testid="worker-weekly-strip" className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-5">
        <WeeklyStrip days={weekly.completions_by_day || []} streak={weekly.streak_days || 0} title="Your week" />
      </section>

      <GoalsCard />
    </div>
  );
}

function Tile({ label, value, testid, accent, icon: Icon, sub }) {
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

function DeadlineBucket({ title, tasks, empty, tone, icon: Icon, testid, onComplete }) {
  const tones = {
    red:    "border-red-400/30 text-red-300",
    yellow: "border-yellow-400/40 text-yellow-300",
    sky:    "border-sky-400/30 text-sky-300",
    zinc:   "border-zinc-700 text-zinc-300",
  };
  const total = tasks.reduce((s, t) => s + Number(t.price), 0);
  return (
    <div data-testid={testid} className={`bg-[#121214] border ${tones[tone] ? "" : ""} border-yellow-400/15 rounded-2xl p-5`}>
      <div className="flex items-center justify-between mb-3">
        <div className={`inline-flex items-center gap-2 px-2.5 py-1 rounded-full text-xs border ${tones[tone] || "border-yellow-400/20"}`}>
          <Icon className="w-3.5 h-3.5" /> {title}
          <span className="opacity-60">· {tasks.length}</span>
        </div>
        {tasks.length > 0 && (
          <div className="text-xs text-zinc-400">
            potential <span className="text-yellow-400 font-display font-semibold">${total.toFixed(2)}</span>
          </div>
        )}
      </div>
      {tasks.length === 0 ? (
        <div className="text-sm text-zinc-500 py-3">{empty}</div>
      ) : (
        <div className="space-y-2">
          {tasks.slice(0, 4).map((t) => (
            <button key={t.id} data-testid={`deadline-task-${t.id}`} onClick={() => onComplete(t)}
              className="w-full text-left flex items-center gap-3 px-3 py-2 rounded-xl bg-zinc-900/70 hover:bg-zinc-900 border border-zinc-800 transition">
              <Circle className="w-4 h-4 text-zinc-500" />
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium truncate">{t.title}</div>
                <div className="text-[11px] text-zinc-500 flex items-center gap-2">
                  {t.due_at && <span><Calendar className="inline w-3 h-3 -mt-0.5" /> {fmtDate(t.due_at)}</span>}
                  {t.estimated_hours && <span><Hourglass className="inline w-3 h-3 -mt-0.5" /> {t.estimated_hours}h</span>}
                </div>
              </div>
              <div className="text-yellow-400 font-display font-semibold">${Number(t.price).toFixed(2)}</div>
              <ArrowRight className="w-4 h-4 text-zinc-600" />
            </button>
          ))}
          {tasks.length > 4 && <div className="text-[11px] text-zinc-500 pl-1">+{tasks.length - 4} more</div>}
        </div>
      )}
    </div>
  );
}

function TaskRow({ t, onToggle, onStart }) {
  return (
    <div data-testid={`worker-task-${t.id}`} className="px-5 sm:px-6 py-4 flex items-center gap-3 flex-wrap">
      <button
        data-testid={`toggle-task-${t.id}`} onClick={onToggle}
        className={`w-9 h-9 rounded-full grid place-items-center border transition ${
          t.status === "completed"
            ? "bg-green-500/20 border-green-400/40 text-green-400"
            : "bg-zinc-900 border-yellow-400/20 text-zinc-500 hover:text-yellow-400"
        }`}>
        {t.status === "completed" ? <CheckCircle2 className="w-5 h-5" /> : <Circle className="w-5 h-5" />}
      </button>
      <div className="flex-1 min-w-[200px]">
        <div className="flex items-center gap-2 flex-wrap">
          <div className={`font-medium ${t.status === "completed" ? "line-through text-zinc-500" : ""}`}>{t.title}</div>
          <SpeakButton
            testid={`speak-task-${t.id}`}
            text={`${t.title}. ${t.description || ""}`}
            label="Read task aloud"
            size={14}
          />
          {t.frequency && t.frequency !== "once" && (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] bg-sky-400/15 text-sky-300 uppercase tracking-widest">
              <Repeat className="w-3 h-3" /> {t.frequency}
            </span>
          )}
          {t.payout_schedule && t.payout_schedule !== "per_task" && (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] bg-emerald-400/15 text-emerald-300 uppercase tracking-widest">
              <Wallet className="w-3 h-3" /> paid {t.payout_schedule}
            </span>
          )}
        </div>
        {t.description && (
          <div data-testid={`worker-task-desc-${t.id}`} className="text-sm text-zinc-300 mt-1.5 whitespace-pre-wrap break-words">
            {t.description}
          </div>
        )}
        <div className="text-xs text-zinc-500 mt-1 flex flex-wrap gap-x-3 gap-y-1 items-center">
          {t.due_at && <span><Calendar className="inline w-3 h-3 -mt-0.5" /> {fmtDate(t.due_at)}</span>}
          {t.due_day_of_week != null && <span><Calendar className="inline w-3 h-3 -mt-0.5" /> {DOW_NAMES[t.due_day_of_week]}</span>}
          {t.due_time && <span className="text-yellow-300"><Clock className="inline w-3 h-3 -mt-0.5" /> by {fmtTime12(t.due_time)}</span>}
          {t.daily_hours != null && <span><Hourglass className="inline w-3 h-3 -mt-0.5" /> {t.daily_hours < 1 ? `${Math.round(t.daily_hours * 60)}m/day` : `${t.daily_hours}h/day`}</span>}
          {t.estimated_hours != null && <span><Hourglass className="inline w-3 h-3 -mt-0.5" /> {t.estimated_hours}h total</span>}
        </div>
      </div>
      <div className="inline-flex items-center gap-1 text-yellow-400 font-display font-semibold">
        <BadgeDollarSign className="w-4 h-4" />{Number(t.price).toFixed(2)}
      </div>
      {t.status !== "completed" && (
        <Button data-testid={`worker-start-${t.id}`} size="sm" variant="ghost" onClick={onStart}
          className={`rounded-full h-8 px-3 text-xs border ${
            t.status === "in_progress"
              ? "border-yellow-400/30 text-yellow-300 bg-yellow-400/10"
              : "border-yellow-400/20 text-zinc-300 hover:text-yellow-400"
          }`}>
          {t.status === "in_progress" ? "Working…" : "Start"}
        </Button>
      )}
    </div>
  );
}
