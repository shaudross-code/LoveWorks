import { Sparkles } from "lucide-react";
import AlarmsPanel from "@/components/AlarmsPanel";
import GoalsCard from "@/components/GoalsCard";
import HealthCard from "@/components/HealthCard";
import SetupChecklist from "@/components/SetupChecklist";
import WeeklyStrip from "@/components/WeeklyStrip";
import ClockHero from "@/components/worker/ClockHero";
import DeadlinesSection from "@/components/worker/DeadlinesSection";
import WorkerTaskRow from "@/components/worker/WorkerTaskRow";
import { useWorkerDashboard } from "@/hooks/useWorkerDashboard";

function TaskList({ tasks, groups, setStatus }) {
  return (
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
          <WorkerTaskRow key={t.id} t={t} onToggle={() => setStatus(t, t.status === "completed" ? "assigned" : "completed")}
            onStart={() => setStatus(t, t.status === "in_progress" ? "assigned" : "in_progress")} />
        ))}
      </div>
    </section>
  );
}

export default function WorkerDashboard() {
  const dash = useWorkerDashboard();
  return (
    <div className="space-y-10">
      <SetupChecklist />
      <AlarmsPanel />
      <HealthCard />
      <ClockHero dash={dash} />
      <DeadlinesSection deadlines={dash.deadlines} onComplete={(t) => dash.setStatus(t, "completed")} />
      <TaskList tasks={dash.tasks} groups={dash.groups} setStatus={dash.setStatus} />
      <section data-testid="worker-weekly-strip" className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-5">
        <WeeklyStrip days={dash.weekly.completions_by_day || []} streak={dash.weekly.streak_days || 0} title="Your week" />
      </section>
      <GoalsCard />
    </div>
  );
}
