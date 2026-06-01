import { useEffect, useState } from "react";
import api from "@/lib/api";
import { BadgeDollarSign, Clock, CheckCircle2, Activity } from "lucide-react";

export default function AdminPayroll() {
  const [rows, setRows] = useState([]);

  useEffect(() => {
    (async () => {
      const { data } = await api.get("/payroll");
      setRows(data);
    })();
  }, []);

  const totalEarn = rows.reduce((s, r) => s + r.tasks_earnings, 0);
  const totalHours = rows.reduce((s, r) => s + r.total_hours, 0);

  return (
    <div className="space-y-8">
      <div>
        <div className="text-xs uppercase tracking-widest text-yellow-400">Payroll</div>
        <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">Who earned what.</h1>
        <p className="mt-2 text-zinc-400">Completed tasks add up here. Hours are tracked for context — pay is per task.</p>
      </div>

      <div className="grid sm:grid-cols-2 gap-4">
        <div className="bg-gradient-to-br from-yellow-400 to-yellow-300 text-black rounded-2xl p-6">
          <div className="text-xs uppercase tracking-widest opacity-70">Total payroll due</div>
          <div className="mt-3 font-display text-5xl font-bold tracking-tight" data-testid="payroll-total-earnings">${totalEarn.toFixed(2)}</div>
          <div className="mt-2 text-sm opacity-70">Across {rows.length} worker{rows.length === 1 ? "" : "s"}</div>
        </div>
        <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-6">
          <div className="text-xs uppercase tracking-widest text-zinc-500">Total hours logged</div>
          <div className="mt-3 font-display text-5xl font-bold tracking-tight text-white" data-testid="payroll-total-hours">{totalHours.toFixed(1)}h</div>
          <div className="mt-2 text-sm text-zinc-500">For reference only</div>
        </div>
      </div>

      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl overflow-hidden">
        <div className="px-6 py-4 border-b border-yellow-400/10 font-display text-lg">Per-worker breakdown</div>
        {rows.length === 0 && <div className="p-10 text-center text-zinc-500">No workers yet.</div>}
        <div className="divide-y divide-yellow-400/5">
          {rows.map((r) => (
            <div key={r.worker.id} data-testid={`payroll-row-${r.worker.id}`} className="px-6 py-5 flex items-center gap-4 flex-wrap">
              <div className="flex items-center gap-3 flex-1 min-w-[180px]">
                <div className="w-10 h-10 rounded-xl bg-yellow-400 text-black grid place-items-center font-display font-bold">
                  {(r.worker.name || "?")[0]?.toUpperCase()}
                </div>
                <div className="min-w-0">
                  <div className="font-medium flex items-center gap-2">
                    {r.worker.name}
                    {r.currently_clocked_in && (
                      <span className="inline-flex items-center gap-1 text-[10px] uppercase tracking-widest text-green-400 bg-green-400/10 px-2 py-0.5 rounded-full">
                        <span className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" /> on the clock
                      </span>
                    )}
                  </div>
                  <div className="text-xs text-zinc-500 truncate">{r.worker.email}</div>
                </div>
              </div>
              <Metric icon={CheckCircle2} label="Tasks" value={r.tasks_completed} />
              <Metric icon={Clock} label="Hours" value={`${r.total_hours.toFixed(1)}h`} />
              <Metric icon={Activity} label="Status" value={r.currently_clocked_in ? "Active" : "Idle"} accent={r.currently_clocked_in ? "text-green-400" : ""} />
              <div className="ml-auto text-right">
                <div className="text-xs uppercase tracking-widest text-zinc-500">Earned</div>
                <div className="font-display text-2xl font-bold text-yellow-400 flex items-center gap-1">
                  <BadgeDollarSign className="w-5 h-5" />
                  {r.tasks_earnings.toFixed(2)}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function Metric({ icon: Icon, label, value, accent }) {
  return (
    <div className="px-3 py-2 rounded-lg bg-zinc-900/60 border border-zinc-800 min-w-[90px]">
      <div className="text-[10px] uppercase tracking-widest text-zinc-500 flex items-center gap-1"><Icon className="w-3 h-3" /> {label}</div>
      <div className={`mt-0.5 font-display font-semibold ${accent || "text-white"}`}>{value}</div>
    </div>
  );
}
