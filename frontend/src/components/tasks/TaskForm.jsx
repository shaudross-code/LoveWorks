import { useState } from "react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import LabeledInput, { FieldLabel } from "@/components/form/LabeledInput";
import LabeledSelect from "@/components/form/LabeledSelect";
import TaskAlarmFields from "@/components/TaskAlarmFields";
import { TaskEffortFields, TaskScheduleFields } from "@/components/tasks/TaskFormFields";
import api, { attempt } from "@/lib/api";
import { bindField } from "@/lib/forms";
import { EMPTY_TASK, taskPayload, taskToForm, validateTask } from "@/lib/tasks";

// Assign / edit task dialog body.
export default function TaskForm({ task, workers, onDone }) {
  const [form, setForm] = useState(() => (task ? taskToForm(task) : EMPTY_TASK));
  const [busy, setBusy] = useState(false);
  const field = bindField(form, setForm);
  const workerOptions = workers.map((w) => ({ value: w.id, label: `${w.name} · ${w.email}` }));

  const submit = async (e) => {
    e.preventDefault();
    const problem = validateTask(form);
    if (problem) { toast.error(problem); return; }
    setBusy(true);
    const payload = taskPayload(form);
    const ok = task
      ? await attempt(() => api.patch(`/tasks/${task.id}`, payload), "Task updated")
      : await attempt(() => api.post("/tasks", payload), "Task assigned");
    setBusy(false);
    if (ok) onDone();
  };

  return (
    <>
      <DialogHeader>
        <DialogTitle className="font-display text-2xl">{task ? "Edit task" : "Assign a task"}</DialogTitle>
      </DialogHeader>
      <form onSubmit={submit} className="space-y-4 max-h-[70vh] overflow-y-auto pr-1">
        <LabeledInput label="Title" testid="task-title" required {...field("title")} />
        <div>
          <FieldLabel>Description</FieldLabel>
          <Textarea data-testid="task-description" value={form.description} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
            className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl min-h-20" />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <LabeledInput label="Price (USD)" testid="task-price-input" required type="number" min="0" step="0.01" {...field("price")} />
          <LabeledSelect label="Assignee" testid="task-assignee" placeholder="Pick worker" options={workerOptions} optionPrefix="assignee-option" {...field("assignee_id")} />
        </div>
        <TaskScheduleFields form={form} setForm={setForm} field={field} />
        <TaskEffortFields form={form} setForm={setForm} field={field} />
        <TaskAlarmFields form={form} setForm={setForm} workerName={workers.find((w) => w.id === form.assignee_id)?.name} />
        <DialogFooter>
          <Button data-testid="submit-task" type="submit" disabled={busy} className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
            {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : (task ? "Save changes" : "Assign task")}
          </Button>
        </DialogFooter>
      </form>
    </>
  );
}
