import { useCallback, useEffect, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import Avatar from "@/components/Avatar";
import WeekPicker from "@/components/WeekPicker";
import { downloadCsv } from "@/lib/csv";
import { money, weekday } from "@/lib/weeks";
import { toast } from "sonner";
import { BadgeDollarSign, Clock, CheckCircle2, Download, CircleDollarSign, Undo2, AlertTriangle, Loader2 } from "lucide-react";

function DayStrip({ days }) {
  return (
    <div className="grid grid-cols-7 gap-1 min-w-[260px]">
      {days.map((d) => (
        <div key={d.date} title={`${d.count} task(s), ${money(d.earned)}, ${d.hours.toFixed(1)}h`}
          className={`rounded-md px-1 py-1 text-center border ${d.count ? "border-yellow-400/30 bg-yellow-400/[0.07]" : "border-zinc-800 bg-zinc-900/50"}`}>
          <div className="text-[9px] uppercase tracking-widest text-zinc-500">{weekday(d.date).slice(0, 2)}</div>
          <div className={`text-xs font-semibold tabular-nums ${d.count ? "text-yellow-300" : "text-zinc-600"}`}>{d.count}</div>
        </div>
      ))}
    </div>
  );
}

function PaidBadge({ r, onUndo, busy }) {
  const p = r.payout;
  return (
    <div className="text-right">
      <span data-testid={`payroll-paid-${r.worker.id}`} className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] bg-emerald-400/10 text-emerald-300 border border-emerald-400/25">
        <CircleDollarSign className="w-3.5 h-3.5" /> Paid {money(p.amount)} · {new Date(p.paid_at).toLocaleDateString(undefined, { month: "short", day: "numeric" })}
      </span>
      {r.changed_since_paid && (
        <div className="mt-1 text-[11px] text-amber-300 inline-flex items-center gap-1" data-testid={`payroll-changed-${r.worker.id}`}>
          <AlertTriangle className="w-3 h-3" /> Now {money(r.earned)} — undo and mark paid again to update
        </div>
      )}
      <button data-testid={`payroll-undo-${r.worker.id}`} disabled={busy} onClick={onUndo} className="mt-1 ml-2 text-[11px] text-zinc-500 hover:text-zinc-300 inline-flex items-center gap-1 transition-colors">
        <Undo2 className="w-3 h-3" /> Undo
      </button>
    </div>
  );
}

function WeeklyPayroll() {
  const [week, setWeek] = useState(null);
  const [data, setData] = useState(null);
  const [busy, setBusy] = useState(false);
  const load = useCallback(async () => {
    const { data: d } = await api.get("/payroll/week", { params: week ? { week } : {} });
    setData(d);
  }, [week]);
  useEffect(() => { load(); }, [load]);

  const act = async (fn, ok) => {
    setBusy(true);
    try { await fn(); toast.success(ok); await load(); } catch (e) { toast.error(formatApiError(e)); } finally { setBusy(false); }
  };
  const markPaid = (ids) => act(() => api.post(`/payroll/week/${data.week_start}/paid`, { worker_ids: ids }), ids ? "Marked paid" : "Week marked paid");
  const undo = (wid) => act(() => api.delete(`/payroll/week/${data.week_start}/paid/${wid}`), "Paid mark removed");

  const csv = () => downloadCsv(`payroll-week-${data.week_start}.csv`,
    ["Worker", "Email", ...data.rows[0].days.map((d) => `${d.date} tasks`), ...data.rows[0].days.map((d) => `${d.date} pay`), "Tasks", "Hours", "Earned", "Paid amount", "Paid on"],
    data.rows.map((r) => [r.worker.name, r.worker.email, ...r.days.map((d) => d.count), ...r.days.map((d) => d.earned.toFixed(2)),
      r.tasks_completed, r.hours.toFixed(2), r.earned.toFixed(2), r.payout ? r.payout.amount.toFixed(2) : "", r.payout ? r.payout.paid_at.slice(0, 10) : ""]));

  const unpaidCount = data ? data.rows.filter((r) => !r.payout && r.earned > 0).length : 0;
  return (
    <section className="space-y-4" data-testid="payroll-weekly">
      <div className="flex flex-wrap items-center gap-3 justify-between">
        <WeekPicker data={data} onChange={setWeek} testid="payroll-week" />
        <div className="flex gap-2">
          <button data-testid="payroll-week-csv" disabled={!data?.rows.length} onClick={csv}
            className="inline-flex items-center gap-2 h-9 px-4 rounded-full text-sm border border-yellow-400/30 text-yellow-300 hover:bg-yellow-400/10 transition-colors disabled:opacity-40">
            <Download className="w-4 h-4" /> CSV
          </button>
          <button data-testid="payroll-mark-all-paid" disabled={!data || busy || unpaidCount === 0 || data.is_future} onClick={() => markPaid(null)}
            className="inline-flex items-center gap-2 h-9 px-4 rounded-full text-sm font-semibold bg-yellow-400 text-black hover:bg-yellow-300 transition-colors disabled:opacity-40">
            <CircleDollarSign className="w-4 h-4" /> Mark all paid{unpaidCount ? ` (${unpaidCount})` : ""}
          </button>
        </div>
      </div>
      {data?.is_current && <div className="text-xs text-amber-300/90">This week isn't over yet. Totals keep growing until Sunday night.</div>}

      {data && (
        <div className="grid sm:grid-cols-3 gap-4">
          <Card label="Earned this week" value={money(data.totals.earned)} testid="payroll-week-earned" sub={`${data.totals.tasks_completed} tasks · ${data.totals.hours.toFixed(1)}h`} gold />
          <Card label="Paid" value={money(data.totals.paid)} testid="payroll-week-paid" />
          <Card label="Not paid yet" value={money(data.totals.unpaid)} testid="payroll-week-unpaid" />
        </div>
      )}

      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl divide-y divide-yellow-400/5">
        {!data && <div className="p-10 grid place-items-center text-zinc-500"><Loader2 className="w-5 h-5 animate-spin" /></div>}
        {data?.rows.length === 0 && <div className="p-10 text-center text-zinc-500">No workers yet.</div>}
        {data?.rows.map((r) => (
          <div key={r.worker.id} data-testid={`payroll-week-row-${r.worker.id}`} className="px-5 py-4 flex items-center gap-4 flex-wrap">
            <div className="flex items-center gap-3 flex-1 min-w-[180px]">
              <Avatar url={r.worker.avatar_url} name={r.worker.name} size={36} />
              <div className="min-w-0">
                <div className="font-medium truncate">{r.worker.name}</div>
                <div className="text-xs text-zinc-500">{r.tasks_completed} tasks · {r.hours.toFixed(1)}h</div>
              </div>
            </div>
            <DayStrip days={r.days} />
            <div className="w-24 text-right font-display text-xl font-bold text-yellow-400 tabular-nums" data-testid={`payroll-week-earned-${r.worker.id}`}>{money(r.earned)}</div>
            <div className="w-52 flex justify-end">
              {r.payout ? <PaidBadge r={r} busy={busy} onUndo={() => undo(r.worker.id)} /> : r.earned <= 0 ? (
                <span className="text-xs text-zinc-600" data-testid={`payroll-nothing-${r.worker.id}`}>Nothing to pay</span>
              ) : (
                <button data-testid={`payroll-mark-paid-${r.worker.id}`} disabled={busy || data.is_future} onClick={() => markPaid([r.worker.id])}
                  className="inline-flex items-center gap-1 h-8 px-3 rounded-full text-xs border border-emerald-400/30 text-emerald-300 hover:bg-emerald-400/10 transition-colors disabled:opacity-40">
                  <CircleDollarSign className="w-3.5 h-3.5" /> Mark paid
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}

function AllTime() {
  const [rows, setRows] = useState(null);
  useEffect(() => { api.get("/payroll").then(({ data }) => setRows(data)); }, []);
  if (!rows) return null;
  const sum = (k) => rows.reduce((s, r) => s + (r[k] || 0), 0);
  return (
    <section className="space-y-4" data-testid="payroll-all-time">
      <h2 className="font-display text-base md:text-lg font-semibold">All time</h2>
      <div className="grid sm:grid-cols-3 gap-4">
        <Card label="Earned all time" value={money(sum("tasks_earnings"))} testid="payroll-total-earnings" sub={`${sum("total_hours").toFixed(1)}h logged`} />
        <Card label="Paid so far" value={money(sum("paid_total"))} testid="payroll-total-paid" />
        <Card label="Still owed" value={money(sum("owed"))} testid="payroll-total-owed" gold />
      </div>
      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl divide-y divide-yellow-400/5">
        {rows.map((r) => (
          <div key={r.worker.id} data-testid={`payroll-row-${r.worker.id}`} className="px-5 py-4 flex items-center gap-4 flex-wrap">
            <div className="flex items-center gap-3 flex-1 min-w-[180px]">
              <Avatar url={r.worker.avatar_url} name={r.worker.name} size={36} />
              <div className="min-w-0">
                <div className="font-medium flex items-center gap-2">{r.worker.name}
                  {r.currently_clocked_in && <span className="text-[10px] uppercase tracking-widest text-green-400 bg-green-400/10 px-2 py-0.5 rounded-full">on the clock</span>}
                </div>
                <div className="text-xs text-zinc-500 truncate">{r.worker.email}</div>
              </div>
            </div>
            <Metric icon={CheckCircle2} label="Tasks" value={r.tasks_completed} />
            <Metric icon={Clock} label="Hours" value={`${r.total_hours.toFixed(1)}h`} />
            <Metric icon={CircleDollarSign} label="Paid" value={money(r.paid_total)} />
            <div className="ml-auto text-right">
              <div className="text-[10px] uppercase tracking-widest text-zinc-500">Earned · owed</div>
              <div className="font-display text-xl font-bold text-yellow-400 tabular-nums inline-flex items-center gap-1">
                <BadgeDollarSign className="w-5 h-5" />{r.tasks_earnings.toFixed(2)}
                <span className="text-sm text-zinc-400 font-normal" data-testid={`payroll-owed-${r.worker.id}`}>· {money(r.owed)}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}

export default function AdminPayroll() {
  return (
    <div className="space-y-10">
      <div>
        <div className="text-xs uppercase tracking-widest text-yellow-400">Payroll</div>
        <h1 className="font-display text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight mt-2">Who earned what, week by week.</h1>
        <p className="mt-2 text-zinc-400">Pay is per task, at the price it had when it was done. Mark a week paid and that amount is locked in.</p>
      </div>
      <WeeklyPayroll />
      <AllTime />
    </div>
  );
}

function Card({ label, value, sub, gold, testid }) {
  return (
    <div className={gold ? "bg-gradient-to-br from-yellow-400 to-yellow-300 text-black rounded-2xl p-5" : "bg-[#121214] border border-yellow-400/15 rounded-2xl p-5"}>
      <div className={`text-[10px] uppercase tracking-widest ${gold ? "opacity-70" : "text-zinc-500"}`}>{label}</div>
      <div className="mt-2 font-display text-3xl font-bold tabular-nums" data-testid={testid}>{value}</div>
      {sub && <div className={`mt-1 text-xs ${gold ? "opacity-70" : "text-zinc-500"}`}>{sub}</div>}
    </div>
  );
}

function Metric({ icon: Icon, label, value }) {
  return (
    <div className="px-3 py-2 rounded-lg bg-zinc-900/60 border border-zinc-800 min-w-[90px]">
      <div className="text-[10px] uppercase tracking-widest text-zinc-500 flex items-center gap-1"><Icon className="w-3 h-3" /> {label}</div>
      <div className="mt-0.5 font-display font-semibold text-white">{value}</div>
    </div>
  );
}
