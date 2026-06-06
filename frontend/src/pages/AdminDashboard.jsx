import { useEffect, useState } from "react";
import api from "@/lib/api";
import { Users, ClipboardList, BadgeDollarSign, Activity, Clock, TrendingUp, CalendarRange } from "lucide-react";

function Stat({ icon: Icon, label, value, accent, testid }) {
  return (
    <div data-testid={testid} className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-6 hover:-translate-y-0.5 hover:shadow-lg hover:shadow-yellow-400/5 transition">
      <div className="flex items-center justify-between">
        <div className="text-xs uppercase tracking-widest text-zinc-500">{label}</div>
        <div className={`w-9 h-9 rounded-xl grid place-items-center ${accent || "bg-yellow-400/10 text-yellow-400"}`}>
          <Icon className="w-4 h-4" />
        </div>
      </div>
      <div className="mt-5 font-display text-4xl font-bold tracking-tight">{value}</div>
    </div>
  );
}

export default function AdminDashboard() {
  const [stats, setStats] = useState({ workers: 0, tasks: 0, completed: 0, earnings: 0, hours: 0, active: 0, potential_weekly: 0, potential_monthly: 0 });
  const [recent, setRecent] = useState([]);
  const [byWorker, setByWorker] = useState([]);

  useEffect(() => {
    (async () => {
      const [w, t, p, ws] = await Promise.all([
        api.get("/workers"), api.get("/tasks"), api.get("/payroll"), api.get("/admin/worker-status"),
      ]);
      const tasks = t.data;
      const completed = tasks.filter(x => x.status === "completed").length;
      const earnings = p.data.reduce((s, x) => s + x.tasks_earnings, 0);
      const hours = p.data.reduce((s, x) => s + x.total_hours, 0);
      const active = p.data.filter(x => x.currently_clocked_in).length;
      const potential_weekly = ws.data.reduce((s, x) => s + (x.potential_weekly || 0), 0);
      const potential_monthly = ws.data.reduce((s, x) => s + (x.potential_monthly || 0), 0);
      setStats({ workers: w.data.length, tasks: tasks.length, completed, earnings, hours, active, potential_weekly, potential_monthly });
      setRecent(tasks.slice(0, 6));
      setByWorker(ws.data);
    })();
  }, []);

  return (
    <div className="space-y-8">
      <div className="fade-up">
        <div className="text-xs uppercase tracking-widest text-yellow-400">Overview</div>
        <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">Today at a glance.</h1>
        <p className="mt-2 text-zinc-400 max-w-xl">The numbers your foreman brain craves — workers on the clock, tasks in motion, money earned.</p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        <Stat testid="stat-workers"   icon={Users}          label="Workers"          value={stats.workers} />
        <Stat testid="stat-active"    icon={Activity}       label="On the Clock"     value={stats.active}  accent="bg-green-400/10 text-green-400" />
        <Stat testid="stat-hours"     icon={Clock}          label="Hours Logged"     value={stats.hours.toFixed(1)} />
        <Stat testid="stat-tasks"     icon={ClipboardList}  label="Tasks Assigned"   value={stats.tasks} />
        <Stat testid="stat-completed" icon={ClipboardList}  label="Completed"        value={stats.completed} accent="bg-green-400/10 text-green-400" />
        <Stat testid="stat-earnings"  icon={BadgeDollarSign}label="Total Payroll"    value={`$${stats.earnings.toFixed(2)}`} />
      </div>

      {/* Potential earnings — if every open task gets completed */}
      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl">
        <div className="px-6 py-5 border-b border-yellow-400/10 flex items-center justify-between flex-wrap gap-2">
          <div>
            <h2 className="font-display text-xl font-semibold flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-yellow-400" /> Potential earnings
            </h2>
            <p className="text-xs text-zinc-500 mt-0.5">If every worker completes all open tasks on schedule.</p>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-right">
              <div className="text-[10px] uppercase tracking-widest text-zinc-500">This week</div>
              <div className="font-display text-2xl font-bold text-yellow-400 tabular-nums" data-testid="potential-weekly-total">${stats.potential_weekly.toFixed(2)}</div>
            </div>
            <div className="text-right pl-4 border-l border-yellow-400/10">
              <div className="text-[10px] uppercase tracking-widest text-zinc-500">This month</div>
              <div className="font-display text-2xl font-bold text-emerald-400 tabular-nums" data-testid="potential-monthly-total">${stats.potential_monthly.toFixed(2)}</div>
            </div>
          </div>
        </div>
        <div className="divide-y divide-yellow-400/5">
          {byWorker.length === 0 && (
            <div className="px-6 py-8 text-zinc-500 text-sm">No workers yet — invite one to see projections.</div>
          )}
          {byWorker.map((s) => (
            <div key={s.worker.id} data-testid={`potential-row-${s.worker.id}`} className="px-6 py-4 flex items-center gap-4 flex-wrap">
              <div className="flex-1 min-w-[180px]">
                <div className="font-medium">{s.worker.name}</div>
                <div className="text-xs text-zinc-500 inline-flex items-center gap-1 mt-0.5">
                  <CalendarRange className="w-3 h-3" /> {s.open_tasks_count} open task{s.open_tasks_count === 1 ? "" : "s"}
                </div>
              </div>
              <div className="flex items-center gap-4">
                <div className="text-right">
                  <div className="text-[10px] uppercase tracking-widest text-zinc-500">Weekly</div>
                  <div className="font-display text-lg font-semibold text-yellow-400 tabular-nums">${(s.potential_weekly || 0).toFixed(2)}</div>
                </div>
                <div className="text-right pl-4 border-l border-yellow-400/10">
                  <div className="text-[10px] uppercase tracking-widest text-zinc-500">Monthly</div>
                  <div className="font-display text-lg font-semibold text-emerald-400 tabular-nums">${(s.potential_monthly || 0).toFixed(2)}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl">
        <div className="px-6 py-5 border-b border-yellow-400/10 flex items-center justify-between">
          <h2 className="font-display text-xl font-semibold">Recent tasks</h2>
          <a href="/admin/tasks" className="text-sm text-yellow-400 hover:underline">Manage →</a>
        </div>
        <div className="divide-y divide-yellow-400/5">
          {recent.length === 0 && <div className="px-6 py-8 text-zinc-500 text-sm">No tasks yet — head to Tasks to assign your first one.</div>}
          {recent.map((t) => (
            <div key={t.id} data-testid={`recent-task-${t.id}`} className="px-6 py-4 flex items-center gap-4">
              <div className="flex-1 min-w-0">
                <div className="font-medium truncate">{t.title}</div>
                <div className="text-xs text-zinc-500 truncate">Assigned to {t.assignee_name || "—"}</div>
              </div>
              <div className="text-yellow-400 font-display font-semibold">${Number(t.price).toFixed(2)}</div>
              <StatusPill status={t.status} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function StatusPill({ status }) {
  const map = {
    assigned:    "bg-zinc-800 text-zinc-300",
    in_progress: "bg-yellow-400/15 text-yellow-300",
    completed:   "bg-green-400/15 text-green-400",
  };
  return <span className={`px-2.5 py-1 rounded-full text-xs ${map[status] || map.assigned}`}>{status.replace("_", " ")}</span>;
}
