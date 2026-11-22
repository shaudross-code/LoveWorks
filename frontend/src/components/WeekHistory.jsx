import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api";
import { ChevronDown, CheckCircle2, Clock, BadgeDollarSign, Loader2, CircleDollarSign } from "lucide-react";
import { fmtDay, weekday, weekRange, money } from "@/lib/weeks";

function DayRow({ d }) {
  const [open, setOpen] = useState(false);
  const empty = d.count === 0 && d.hours === 0;
  return (
    <div className="py-2" data-testid={`history-day-${d.date}`}>
      <button disabled={d.count === 0} onClick={() => setOpen((o) => !o)}
        className={`w-full flex items-center gap-3 text-left text-sm ${empty ? "text-zinc-600" : "text-zinc-200"}`}>
        <span className="w-24 shrink-0"><span className="font-medium">{weekday(d.date)}</span> <span className="text-zinc-500">{fmtDay(d.date)}</span></span>
        <span className="flex-1 inline-flex items-center gap-1"><CheckCircle2 className="w-3.5 h-3.5 text-yellow-400/70" /> {d.count} task{d.count === 1 ? "" : "s"}</span>
        <span className="w-16 text-right tabular-nums text-zinc-400">{d.hours.toFixed(1)}h</span>
        <span className="w-20 text-right tabular-nums text-yellow-300 font-semibold">{money(d.earned)}</span>
        <ChevronDown className={`w-4 h-4 text-zinc-500 transition-transform ${open ? "rotate-180" : ""} ${d.count === 0 ? "invisible" : ""}`} />
      </button>
      {open && (
        <ul className="mt-2 ml-24 space-y-1 text-xs text-zinc-400">
          {d.tasks.map((t, i) => (
            <li key={`${t.task_id}-${i}`} className="flex justify-between gap-3">
              <span className="truncate">{t.title} <span className="text-zinc-600">· {new Date(t.completed_at).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}</span></span>
              <span className="tabular-nums">{money(t.price)}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function WeekCard({ w, defaultOpen }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <section data-testid={`history-week-${w.week_start}`} className="bg-[#121214] border border-yellow-400/15 rounded-2xl">
      <button onClick={() => setOpen((o) => !o)} className="w-full px-5 py-4 flex items-center gap-4 flex-wrap text-left">
        <div className="flex-1 min-w-[160px]">
          <div className="font-display text-lg font-semibold">{weekRange(w.week_start, w.week_last_day)}</div>
          <div className="text-xs text-zinc-500 flex items-center gap-3 mt-0.5">
            <span className="inline-flex items-center gap-1"><CheckCircle2 className="w-3 h-3" /> {w.tasks_completed} tasks</span>
            <span className="inline-flex items-center gap-1"><Clock className="w-3 h-3" /> {w.hours.toFixed(1)}h</span>
          </div>
        </div>
        {w.payout ? (
          <span data-testid={`history-paid-${w.week_start}`} className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] bg-emerald-400/10 text-emerald-300 border border-emerald-400/25">
            <CircleDollarSign className="w-3.5 h-3.5" /> Paid {money(w.payout.amount)}
          </span>
        ) : w.earned > 0 ? (
          <span className="px-2.5 py-1 rounded-full text-[11px] bg-zinc-800 text-zinc-400">Not paid yet</span>
        ) : null}
        <div className="text-right">
          <div className="text-[10px] uppercase tracking-widest text-zinc-500">Earned</div>
          <div className="font-display text-2xl font-bold text-yellow-400 tabular-nums inline-flex items-center gap-1" data-testid={`history-earned-${w.week_start}`}>
            <BadgeDollarSign className="w-5 h-5" />{w.earned.toFixed(2)}
          </div>
        </div>
        <ChevronDown className={`w-5 h-5 text-zinc-500 transition-transform ${open ? "rotate-180" : ""}`} />
      </button>
      {open && <div className="px-5 pb-4 divide-y divide-white/5 border-t border-yellow-400/10">{w.days.map((d) => <DayRow key={d.date} d={d} />)}</div>}
    </section>
  );
}

export default function WeekHistory({ path }) {
  const [weeks, setWeeks] = useState(null);
  const [more, setMore] = useState({ next: null, has: false });
  const [loading, setLoading] = useState(false);

  const load = useCallback(async (before) => {
    setLoading(true);
    try {
      const { data } = await api.get(path, { params: { weeks: 6, ...(before ? { before } : {}) } });
      setWeeks((prev) => (before ? [...(prev || []), ...data.weeks] : data.weeks));
      setMore({ next: data.next_before, has: data.has_more });
    } finally {
      setLoading(false);
    }
  }, [path]);
  useEffect(() => { setWeeks(null); load(); }, [load]);

  if (!weeks) return <div className="p-10 grid place-items-center text-zinc-500"><Loader2 className="w-5 h-5 animate-spin" /></div>;
  return (
    <div className="space-y-3" data-testid="week-history">
      {weeks.map((w, i) => <WeekCard key={w.week_start} w={w} defaultOpen={i === 0} />)}
      {more.has && (
        <button data-testid="history-load-older" disabled={loading} onClick={() => load(more.next)}
          className="w-full h-11 rounded-2xl border border-yellow-400/20 text-sm text-yellow-300 hover:bg-yellow-400/5 transition-colors inline-flex items-center justify-center gap-2">
          {loading && <Loader2 className="w-4 h-4 animate-spin" />} Show older weeks
        </button>
      )}
    </div>
  );
}
