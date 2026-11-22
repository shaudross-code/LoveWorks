import { useState } from "react";
import { BadgeDollarSign, Loader2, Plus, ShoppingBag, UserCircle2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import ImageField from "@/components/form/ImageField";
import LabeledInput, { FieldLabel } from "@/components/form/LabeledInput";
import LabeledSelect from "@/components/form/LabeledSelect";
import TeammatesField from "@/components/TeammatesField";
import api, { attempt, multipart } from "@/lib/api";
import { CATEGORIES, emptyEssential, essentialCreateParams, essentialEditPayload, essentialToForm, validateEssential } from "@/lib/essentials";
import { bindField } from "@/lib/forms";

function EssentialPhoto({ item, onChange }) {
  const [busy, setBusy] = useState(false);
  const upload = async (file) => {
    const fd = new FormData();
    fd.append("file", file);
    setBusy(true);
    const res = await attempt(() => api.post(`/essentials/${item.id}/image`, fd, multipart), "Photo saved");
    setBusy(false);
    if (res?.data) onChange({ image_url: res.data.image_url, image_path: res.data.image_path });
  };
  return <ImageField label="Photo" imageUrl={item.image_url} alt={`Photo of ${item.title}`} busy={busy} testPrefix="essential-image" replaceLabel="Replace" onFile={upload} />;
}

function TypeAndDue({ form, setForm, field }) {
  return (
    <div className="grid grid-cols-2 gap-3">
      <div>
        <FieldLabel>Type</FieldLabel>
        <button data-testid="essential-recurring-toggle" type="button" onClick={() => setForm((f) => ({ ...f, recurring: !f.recurring }))}
          className={`mt-2 w-full h-11 rounded-xl text-sm font-semibold transition border ${form.recurring ? "bg-emerald-400/15 text-emerald-300 border-emerald-400/40" : "bg-pink-400/10 text-pink-300 border-pink-400/40"}`}>
          {form.recurring ? "🔁 Recurring" : "✨ One-time"}
        </button>
      </div>
      <LabeledInput label="Due date (optional)" testid="essential-due-date" type="date" {...field("due_date")} />
    </div>
  );
}

function AssigneeSelect({ form, setForm, workers }) {
  const options = [{ value: "self", label: "Keep on my list" }, ...workers.map((w) => ({ value: w.id, label: w.name || w.email }))];
  return (
    <LabeledSelect label="For (optional)" icon={UserCircle2} testid="essential-assignee" options={options}
      value={form.assignee_id || "self"} onValue={(v) => setForm((f) => ({ ...f, assignee_id: v === "self" ? "" : v }))} />
  );
}

// Add / edit essential dialog body.
export default function EssentialForm({ item: initial, workers, onDone, reload }) {
  const editing = Boolean(initial);
  const [item, setItem] = useState(initial);
  const [form, setForm] = useState(() => (editing ? essentialToForm(initial) : emptyEssential(workers[0]?.id || "")));
  const [busy, setBusy] = useState(false);
  const field = bindField(form, setForm);
  const patchItem = (patch) => { setItem((it) => ({ ...it, ...patch })); reload(); };

  const submit = async () => {
    const problem = editing ? null : validateEssential(form);
    if (problem) { toast.error(problem); return; }
    setBusy(true);
    const ok = editing
      ? await attempt(() => api.patch(`/essentials/${item.id}`, essentialEditPayload(form)), "Essential updated")
      : await attempt(() => api.post(`/essentials?${essentialCreateParams(form)}`, new FormData(), multipart), "Essential added 🛒");
    setBusy(false);
    if (ok) onDone();
  };

  return (
    <>
      <DialogHeader>
        <DialogTitle className="font-display text-2xl flex items-center gap-2">
          <ShoppingBag className="w-5 h-5 text-yellow-400" /> {editing ? "Edit essential" : "Add essential"}
        </DialogTitle>
      </DialogHeader>
      <div className="space-y-4">
        {editing && <EssentialPhoto item={item} onChange={patchItem} />}
        {editing && (
          <TeammatesField docId={item.id} collection="essentials" ownerId={item.owner_id} collaboratorIds={item.collaborator_ids || []}
            workers={workers} label="Essential teammates" onChanged={(ids) => patchItem({ collaborator_ids: ids })} />
        )}
        {!editing && workers.length > 0 && <AssigneeSelect form={form} setForm={setForm} workers={workers} />}
        <LabeledInput label="Title" testid="essential-title" placeholder="e.g., Dish soap, Diapers, Bread" {...field("title")} />
        <div className="grid grid-cols-2 gap-3">
          <LabeledInput label="Price" icon={BadgeDollarSign} testid="essential-price" type="number" min="0" step="0.01" placeholder="e.g., 8.99" {...field("price")} />
          <LabeledInput label="Quantity" testid="essential-quantity" type="number" min="1" step="1" {...field("quantity")} />
        </div>
        <LabeledSelect label="Category" testid="essential-category" options={CATEGORIES} optionPrefix="essential-category" {...field("category")} />
        <LabeledInput label="Note (optional)" testid="essential-note" placeholder="e.g., the lavender scent" {...field("note")} />
        <TypeAndDue form={form} setForm={setForm} field={field} />
      </div>
      <DialogFooter>
        <Button data-testid="confirm-essential" onClick={submit} disabled={busy} className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
          {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : (editing ? "Save changes" : <><Plus className="w-4 h-4 mr-2" /> Add to list</>)}
        </Button>
      </DialogFooter>
    </>
  );
}
