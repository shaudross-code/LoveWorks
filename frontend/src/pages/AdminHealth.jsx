import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api";
import Avatar from "@/components/Avatar";
import WeekPicker from "@/components/WeekPicker";
import SortHeader, { useSorted } from "@/components/SortHeader";
import { downloadCsv } from "@/lib/csv";
import { weekday } from "@/lib/weeks";
import { kgToLb, fmtKcal } from "@/lib/health";
import { Download, EyeOff, Flame, Scale, Bluetooth, Loader2 } from "lucide-react";

const lb = (kg) => (kg == null ? null : kgToLb(kg));
const valueOf = (r, k) => (k === "name" ? (r.worker.name || "").toLowerCase() : r.shared ? r[k] : null);

function Change({ kg }) {
  if (kg == null) return <span className="text-zinc-600">—</span>;
  const v = kgToLb(Math.abs(kg));
  if (v === 0) return <span className="text-zinc-400">0 lb</span>;
  return <span className={kg < 0 ? "text-emerald-300" : "text-amber-300"}>{kg < 0 ? "−" : "+"}{v} lb</span>;
}

function DayDots({ days }) {
  const max = Math.max(1, ...days.map((d) => d.active_kcal || 0));
  return (
    <div className="flex items-end gap-1 h-8" aria-hidden>
      {days.map((d) => (
        <div key={d.date} title={`${weekday(d.date)}: ${fmtKcal(d.active_kcal)} active kcal`}
          className="w-2.5 rounded-sm bg-orange-400/80" style={{ height: `${Math.max(8, ((d.active_kcal || 0) / max) * 100)}%`, opacity: d.active_kcal ? 1 : 0.15 }} />
      ))}
    </div>
  );
}

export default function AdminHealth() {
  const [week, setWeek] = useState(null);
  const [data, setData] = useState(null);
  const [sort, setSort] = useState({ key: "active_total", dir: "desc" });
  const load = useCallback(async () => {
    const { data: d } = await api.get("/admin/health/crew", { params: week ? { week } : {} });
    setData(d);
  }, [week]);
  useEffect(() => { load(); }, [load]);

  const rows = useSorted(data?.rows || [], sort, valueOf);
  const shared = rows.filter((r) => r.shared);
  const stamp = data ? data.week_start : "";

  const summaryCsv = () => downloadCsv(`crew-health-summary-${stamp}.csv`,
    ["Worker", "Email", "Shared", "Active kcal (week)", "Avg active kcal/day", "Total kcal (week)", "Avg total kcal/day", "Days with data", "Latest weight (lb)", "Weight date", "Weight change (lb)", "Weight from"],
    rows.map((r) => r.shared
      ? [r.worker.name, r.worker.email, "yes", r.active_total, r.active_avg, r.total_total, r.total_avg, r.days_with_data, lb(r.latest_weight_kg), r.latest_weight_date, lb(r.weight_change_kg), r.weight_source === "scale_bluetooth" ? "Scale (Bluetooth)" : r.latest_weight_kg != null ? "Apple Health" : ""]
      : [r.worker.name, r.worker.email, "not shared", "", "", "", "", "", "", "", "", ""]));

  const dailyCsv = () => downloadCsv(`crew-health-daily-${stamp}.csv`,
    ["Worker", "Email", "Date", "Active kcal", "Total kcal", "Weight (lb)"],
    rows.flatMap((r) => r.shared
      ? r.days.map((d) => [r.worker.name, r.worker.email, d.date, d.active_kcal ?? "", d.total_kcal ?? "", lb(d.weight_kg) ?? ""])
      : [[r.worker.name, r.worker.email, "not shared", "", "", ""]]));

  const totalActive = shared.reduce((s, r) => s + (r.active_total || 0), 0);
  const csvBtn = "inline-flex items-center gap-2 h-9 px-4 rounded-full text-sm border border-yellow-400/30 text-yellow-300 hover:bg-yellow-400/10 transition-colors disabled:opacity-40";

  return (
    <div className="space-y-8" data-testid="admin-health-page">
      <div>
        <div className="text-xs uppercase tracking-widest text-yellow-400">Crew health</div>
        <h1 className="font-display text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight mt-2">Calories and weight, week by week.</h1>
        <p className="mt-2 text-zinc-400">From each worker's Apple Watch, Apple Health and smart scale. Workers can turn sharing off at any time.</p>
      </div>

      <div className="flex flex-wrap items-center gap-3 justify-between">
        <WeekPicker data={data} onChange={setWeek} />
        <div className="flex gap-2">
          <button data-testid="health-csv-summary" disabled={!data} onClick={summaryCsv} className={csvBtn}><Download className="w-4 h-4" /> Summary CSV</button>
          <button data-testid="health-csv-daily" disabled={!data} onClick={dailyCsv} className={csvBtn}><Download className="w-4 h-4" /> Daily CSV</button>
        </div>
      </div>

      <div className="grid sm:grid-cols-3 gap-4">
        <Stat label="Crew active calories" value={fmtKcal(totalActive)} unit="kcal" testid="health-stat-active" icon={Flame} tone="text-orange-300" />
        <Stat label="Sharing" value={`${shared.length} / ${rows.length}`} unit="workers" testid="health-stat-sharing" />
        <Stat label="Weighed in this week" value={shared.filter((r) => r.days.some((d) => d.weight_kg != null)).length} unit="workers" testid="health-stat-weighed" icon={Scale} tone="text-sky-300" />
      </div>

      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl overflow-x-auto">
        {!data && <div className="p-10 grid place-items-center text-zinc-500"><Loader2 className="w-5 h-5 animate-spin" /></div>}
        {data && rows.length === 0 && <div className="p-10 text-center text-zinc-500">No workers yet.</div>}
        {data && rows.length > 0 && (
          <table className="w-full text-sm min-w-[880px]" data-testid="health-table">
            <thead className="border-b border-yellow-400/10">
              <tr>
                <SortHeader label="Worker" k="name" sort={sort} setSort={setSort} align="left" />
                <th className="px-4 py-3 text-left text-[10px] uppercase tracking-widest text-zinc-500 font-medium">Mon–Sun</th>
                <SortHeader label="Active (week)" k="active_total" sort={sort} setSort={setSort} />
                <SortHeader label="Avg active/day" k="active_avg" sort={sort} setSort={setSort} />
                <SortHeader label="Total (week)" k="total_total" sort={sort} setSort={setSort} />
                <SortHeader label="Avg total/day" k="total_avg" sort={sort} setSort={setSort} />
                <SortHeader label="Weight" k="latest_weight_kg" sort={sort} setSort={setSort} />
                <SortHeader label="Change" k="weight_change_kg" sort={sort} setSort={setSort} />
              </tr>
            </thead>
            <tbody className="divide-y divide-yellow-400/5">
              {rows.map((r) => (
                <tr key={r.worker.id} data-testid={`health-row-${r.worker.id}`} className="hover:bg-white/[0.02] transition-colors whitespace-nowrap">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <Avatar url={r.worker.avatar_url} name={r.worker.name} size={34} />
                      <div className="min-w-0">
                        <div className="font-medium truncate">{r.worker.name}</div>
                        <div className="text-xs text-zinc-500 truncate">{r.worker.email}</div>
                      </div>
                    </div>
                  </td>
                  {r.shared ? (
                    <>
                      <td className="px-4 py-3"><DayDots days={r.days} /></td>
                      <td className="px-4 py-3 text-right tabular-nums text-orange-300 font-semibold">{fmtKcal(r.active_total)}</td>
                      <td className="px-4 py-3 text-right tabular-nums">{fmtKcal(r.active_avg)}</td>
                      <td className="px-4 py-3 text-right tabular-nums">{fmtKcal(r.total_total)}</td>
                      <td className="px-4 py-3 text-right tabular-nums">{fmtKcal(r.total_avg)}</td>
                      <td className="px-4 py-3 text-right tabular-nums text-sky-300" data-testid={`health-weight-${r.worker.id}`}>
                        {r.latest_weight_kg == null ? <span className="text-zinc-600">—</span> : (
                          <span className="inline-flex items-center gap-1" title={`Weighed ${r.latest_weight_date}`}>
                            {kgToLb(r.latest_weight_kg)} lb {r.weight_source === "scale_bluetooth" && <Bluetooth className="w-3 h-3" />}
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-right tabular-nums"><Change kg={r.weight_change_kg} /></td>
                    </>
                  ) : (
                    <td colSpan={7} className="px-4 py-3 text-zinc-500" data-testid={`health-not-shared-${r.worker.id}`}>
                      <span className="inline-flex items-center gap-2"><EyeOff className="w-4 h-4" /> Not shared — this worker turned sharing off</span>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
      <p className="text-xs text-zinc-500">Averages count only days with calories. Change compares the last weigh-in this week with the one before it.</p>
    </div>
  );
}

function Stat({ label, value, unit, icon: Icon, tone = "text-white", testid }) {
  return (
    <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-5">
      <div className="text-[10px] uppercase tracking-widest text-zinc-500 flex items-center gap-1">{Icon && <Icon className="w-3 h-3" />} {label}</div>
      <div className={`mt-2 font-display text-3xl font-bold tabular-nums ${tone}`} data-testid={testid}>{value} <span className="text-sm text-zinc-500 font-normal">{unit}</span></div>
    </div>
  );
}
