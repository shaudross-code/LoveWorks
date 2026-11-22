import { useState } from "react";
import { ExternalLink, Loader2, Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import ImageField from "@/components/form/ImageField";
import LabeledInput from "@/components/form/LabeledInput";
import TeammatesField from "@/components/TeammatesField";
import { AllocationInput, DeadlineInput, LinkInput, PeriodSelect, TargetInput } from "@/components/wishlist/GoalFields";
import api, { attempt, multipart } from "@/lib/api";
import { bindField } from "@/lib/forms";
import { goalEditPayload, goalToForm } from "@/lib/wishlist";

function GoalPhoto({ goal, copy, onChange }) {
  const [busy, setBusy] = useState(false);
  const run = async (call, message) => {
    setBusy(true);
    const res = await attempt(call, message);
    setBusy(false);
    if (res?.data) onChange({ image_url: res.data.image_url, image_path: res.data.image_path ?? null });
  };
  const upload = (file) => {
    const fd = new FormData();
    fd.append("file", file);
    run(() => api.post(`/goals/${goal.id}/image`, fd, multipart), "Image updated");
  };
  return (
    <ImageField label={copy.photoLabel} imageUrl={goal.image_url} alt={`${copy.photoLabel} for ${goal.title || "goal"}`}
      busy={busy} testPrefix="edit-image" previewTestid="edit-image-preview" onFile={upload}
      onRemove={() => run(() => api.delete(`/goals/${goal.id}/image`), "Image removed")} />
  );
}

// Edit dialog body for a goal or trip (photo, teammates and all settings).
export default function EditGoalForm({ goal: initial, copy, workers, onDone, reload }) {
  const [goal, setGoal] = useState(initial);
  const [form, setForm] = useState(() => goalToForm(initial));
  const [busy, setBusy] = useState(false);
  const field = bindField(form, setForm);
  const patchGoal = (patch) => { setGoal((g) => ({ ...g, ...patch })); reload(); };

  const submit = async () => {
    setBusy(true);
    const ok = await attempt(() => api.patch(`/goals/${goal.id}`, goalEditPayload(form)), copy.savedToast);
    setBusy(false);
    if (ok) onDone();
  };

  return (
    <>
      <DialogHeader>
        <DialogTitle className="font-display text-2xl flex items-center gap-2">
          <Pencil className="w-5 h-5 text-yellow-400" /> {copy.editTitle}
        </DialogTitle>
      </DialogHeader>
      <div className="space-y-4">
        <div className="text-sm text-zinc-400">{copy.editBlurb}</div>
        <GoalPhoto goal={goal} copy={copy} onChange={patchGoal} />
        <TeammatesField docId={goal.id} collection="goals" ownerId={goal.owner_id} collaboratorIds={goal.collaborator_ids || []}
          workers={workers} label={copy.teammatesLabel} onChanged={(ids) => patchGoal({ collaborator_ids: ids })} />
        <LabeledInput label="Title" testid="edit-title" placeholder={copy.editPlaceholder} {...field("title")} />
        <div className="grid grid-cols-2 gap-3">
          <DeadlineInput prefix="edit" field={field} label="Deadline" />
          <LinkInput prefix="edit" field={field} label={copy.linkLabel} icon={ExternalLink} />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <TargetInput prefix="edit" field={field} />
          <PeriodSelect prefix="edit" field={field} />
        </div>
        <AllocationInput prefix="edit" field={field} label="Allocation % of task earnings"
          hint="e.g., 50% means half of every completed task's earnings is credited toward this goal." />
      </div>
      <DialogFooter>
        <Button data-testid="confirm-edit" onClick={submit} disabled={busy}
          className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
          {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : "Save settings"}
        </Button>
      </DialogFooter>
    </>
  );
}
