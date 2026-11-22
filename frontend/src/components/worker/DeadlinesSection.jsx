import { AlertTriangle, ArrowRight, Calendar, CalendarClock, Circle, Hourglass } from "lucide-react";
import { fmtDateDay } from "@/lib/format";

const TONES = {
  red: "border-red-400/30 text-red-300",
  yellow: "border-yellow-400/40 text-yellow-300",
  sky: "border-sky-400/30 text-sky-300",
  zinc: "border-zinc-700 text-zinc-300",
};

function DeadlineTask({ t, onComplete }) {
  return (
    <button data-testid={`deadline-task-${t.id}`} onClick={() => onComplete(t)}
      className="w-full text-left flex items-center gap-3 px-3 py-2 rounded-xl bg-zinc-900/70 hover:bg-zinc-900 border border-zinc-800 transition">
      <Circle className="w-4 h-4 text-zinc-500" />
      <div className="flex-1 min-w-0">
        <div className="text-sm font-medium truncate">{t.title}</div>
        <div className="text-[11px] text-zinc-500 flex items-center gap-2">
          {t.due_at && <span><Calendar className="inline w-3 h-3 -mt-0.5" /> {fmtDateDay(t.due_at)}</span>}
          {t.estimated_hours && <span><Hourglass className="inline w-3 h-3 -mt-0.5" /> {t.estimated_hours}h</span>}
        </div>
      </div>
      <div className="text-yellow-400 font-display font-semibold">${Number(t.price).toFixed(2)}</div>
      <ArrowRight className="w-4 h-4 text-zinc-600" />
    </button>
  );
}

function DeadlineBucket({ title, tasks, empty, tone, icon: Icon, testid, onComplete }) {
  const total = tasks.reduce((s, t) => s + Number(t.price), 0);
  return (
    <div data-testid={testid} className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-5">
      <div className="flex items-center justify-between mb-3">
        <div className={`inline-flex items-center gap-2 px-2.5 py-1 rounded-full text-xs border ${TONES[tone]}`}>
          <Icon className="w-3.5 h-3.5" /> {title}
          <span className="opacity-60">· {tasks.length}</span>
        </div>
        {tasks.length > 0 && (
          <div className="text-xs text-zinc-400">potential <span className="text-yellow-400 font-display font-semibold">${total.toFixed(2)}</span></div>
        )}
      </div>
      {tasks.length === 0 ? <div className="text-sm text-zinc-500 py-3">{empty}</div> : (
        <div className="space-y-2">
          {tasks.slice(0, 4).map((t) => <DeadlineTask key={t.id} t={t} onComplete={onComplete} />)}
          {tasks.length > 4 && <div className="text-[11px] text-zinc-500 pl-1">+{tasks.length - 4} more</div>}
        </div>
      )}
    </div>
  );
}

const BUCKETS = [
  { key: "overdue", testid: "bucket-overdue", tone: "red", icon: AlertTriangle, title: "Overdue", empty: "No overdue tasks — nice." },
  { key: "dueToday", testid: "bucket-today", tone: "yellow", icon: Calendar, title: "Due today", empty: "Nothing due today." },
  { key: "dueThisWeek", testid: "bucket-week", tone: "sky", icon: CalendarClock, title: "Due this week", empty: "Quiet week ahead." },
  { key: "anytime", testid: "bucket-anytime", tone: "zinc", icon: Hourglass, title: "Open · later", empty: "Inbox zero." },
];

// What needs to ship today and this week; tapping a task completes it.
export default function DeadlinesSection({ deadlines, onComplete }) {
  return (
    <section data-testid="deadlines-section">
      <div className="flex items-center gap-3 mb-4">
        <div className="w-10 h-10 rounded-xl bg-yellow-400/10 text-yellow-400 grid place-items-center"><CalendarClock className="w-5 h-5" /></div>
        <div>
          <h2 className="font-display text-2xl font-semibold tracking-tight">Deadlines</h2>
          <p className="text-xs text-zinc-500 mt-0.5">What needs to ship today and this week.</p>
        </div>
      </div>
      <div className="grid md:grid-cols-2 gap-4">
        {BUCKETS.map(({ key, ...b }) => <DeadlineBucket key={key} {...b} tasks={deadlines[key]} onComplete={onComplete} />)}
      </div>
    </section>
  );
}
