import { useState } from "react";
import { Loader2, Target, UserCircle2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import LabeledInput from "@/components/form/LabeledInput";
import LabeledSelect from "@/components/form/LabeledSelect";
import { AllocationInput, DeadlineInput, LinkInput, PeriodSelect, TargetInput } from "@/components/wishlist/GoalFields";
import api, { attempt, multipart } from "@/lib/api";
import { bindField } from "@/lib/forms";
import { emptyAssignForm, goalCreateParams } from "@/lib/wishlist";
import { toast } from "sonner";

// "Assign a new goal/trip" (admin) or "Add a trip" (worker) dialog body.
export default function AssignGoalForm({ copy, workers, onDone }) {
  const [form, setForm] = useState(() => emptyAssignForm(workers[0]?.id || ""));
  const [busy, setBusy] = useState(false);
  const field = bindField(form, setForm);

  const submit = async () => {
    if (copy.pickWorker && !form.assignee_id) { toast.error("Pick a worker"); return; }
    if (!form.title.trim()) { toast.error("Add a title"); return; }
    setBusy(true);
    const params = goalCreateParams(form, copy.kind, copy.pickWorker ? form.assignee_id : null);
    const ok = await attempt(() => api.post(`/goals?${params}`, new FormData(), multipart), copy.assignedToast);
    setBusy(false);
    if (ok) onDone();
  };

  return (
    <>
      <DialogHeader>
        <DialogTitle className="font-display text-2xl flex items-center gap-2">
          <Target className="w-5 h-5 text-yellow-400" /> {copy.assignTitle}
        </DialogTitle>
      </DialogHeader>
      <div className="space-y-4">
        <div className="text-sm text-zinc-400">{copy.assignBlurb}</div>
        {copy.pickWorker && (
          <LabeledSelect label="Worker" icon={UserCircle2} testid="assign-worker" placeholder="Pick a worker" optionPrefix="assign-worker"
            options={workers.map((w) => ({ value: w.id, label: w.name || w.email }))} {...field("assignee_id")} />
        )}
        <LabeledInput label={copy.titleLabel} testid="assign-title" placeholder={copy.titlePlaceholder} {...field("title")} />
        <div className="grid grid-cols-2 gap-3">
          <TargetInput prefix="assign" field={field} placeholder="e.g., 250" />
          <PeriodSelect prefix="assign" field={field} />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <AllocationInput prefix="assign" field={field} />
          <DeadlineInput prefix="assign" field={field} />
        </div>
        <LinkInput prefix="assign" field={field} label="Product link (optional)" />
      </div>
      <DialogFooter>
        <Button data-testid="confirm-assign" onClick={submit} disabled={busy}
          className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
          {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Target className="w-4 h-4 mr-2" /> {copy.assignSubmit}</>}
        </Button>
      </DialogFooter>
    </>
  );
}
