import { useCallback, useEffect, useMemo, useState } from "react";
import { ClipboardList, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import FilterTabs from "@/components/FilterTabs";
import AdminTaskRow from "@/components/tasks/AdminTaskRow";
import TaskForm from "@/components/tasks/TaskForm";
import { useDialogState } from "@/hooks/useDialogState";
import api, { attempt } from "@/lib/api";
import { TASK_STATUS_TABS } from "@/lib/tasks";

const TABS = TASK_STATUS_TABS.map((s) => ({ value: s, label: s.replace("_", " ") }));

export default function AdminTasks() {
  const [tasks, setTasks] = useState([]);
  const [workers, setWorkers] = useState([]);
  const [filter, setFilter] = useState("all");
  const dialog = useDialogState();

  const load = useCallback(async () => {
    const [t, w] = await Promise.all([api.get("/tasks"), api.get("/workers")]);
    setTasks(t.data);
    setWorkers(w.data);
  }, []);
  useEffect(() => { load(); }, [load]);

  const filtered = useMemo(() => (filter === "all" ? tasks : tasks.filter((t) => t.status === filter)), [tasks, filter]);
  const done = () => { dialog.close(); load(); };
  const complete = async (t) => { if (await attempt(() => api.patch(`/tasks/${t.id}`, { status: "completed" }), "Marked completed")) load(); };
  const remove = async (t) => {
    if (!window.confirm(`Delete "${t.title}"?`)) return;
    if (await attempt(() => api.delete(`/tasks/${t.id}`), "Task deleted")) load();
  };

  return (
    <div className="space-y-8">
      <div className="flex items-end justify-between gap-4 flex-wrap">
        <div>
          <div className="text-xs uppercase tracking-widest text-yellow-400">Workboard</div>
          <h1 className="font-display text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight mt-2">Assign & price tasks.</h1>
          <p className="mt-2 text-zinc-400">Set price, deadline, hours, frequency, and payout schedule for every task.</p>
        </div>
        <Button data-testid="open-create-task" disabled={workers.length === 0} onClick={() => dialog.open("create")}
          className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-11 px-5 disabled:opacity-50">
          <Plus className="w-4 h-4 mr-2" /> New task
        </Button>
      </div>
      <FilterTabs tabs={TABS} value={filter} onChange={setFilter} testPrefix="tab-" />
      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl divide-y divide-yellow-400/5">
        {filtered.length === 0 && (
          <div className="p-10 text-center">
            <ClipboardList className="w-8 h-8 text-yellow-400 mx-auto" />
            <div className="mt-3 font-display text-xl">No tasks here</div>
            <div className="text-sm text-zinc-500">{workers.length === 0 ? "Create a worker first to assign tasks." : "Click \"New task\" to get started."}</div>
          </div>
        )}
        {filtered.map((t) => (
          <AdminTaskRow key={t.id} t={t} onEdit={() => dialog.open("edit", t)} onComplete={() => complete(t)} onDelete={() => remove(t)} />
        ))}
      </div>
      <Dialog open={dialog.state.open} onOpenChange={(o) => !o && dialog.close()}>
        <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl max-w-xl" aria-describedby={undefined}>
          {dialog.state.mode && <TaskForm key={dialog.state.key} task={dialog.state.item} workers={workers} onDone={done} />}
        </DialogContent>
      </Dialog>
    </div>
  );
}
