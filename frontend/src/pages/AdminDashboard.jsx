import { useEffect, useState } from "react";
import api from "@/lib/api";
import { Users, ClipboardList, BadgeDollarSign, Activity, Clock } from "lucide-react";

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
  const [stats, setStats] = useState({ workers: 0, tasks: 0, completed: 0, earnings: 0, hours: 0, active: 0 });
  const [recent, setRecent] = useState([]);

  useEffect(() => {
    (async () => {
      const [w, t, p] = await Promise.all([
        api.get("/workers"), api.get("/tasks"), api.get("/payroll"),
      ]);
      const tasks = t.data;
      const completed = tasks.filter(x => x.status === "completed").length;
      const earnings = p.data.reduce((s, x) => s + x.tasks_earnings, 0);
      const hours = p.data.reduce((s, x) => s + x.total_hours, 0);
      const active = p.data.filter(x => x.currently_clocked_in).length;
      setStats({ workers: w.data.length, tasks: tasks.length, completed, earnings, hours, active });
      setRecent(tasks.slice(0, 6));
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
