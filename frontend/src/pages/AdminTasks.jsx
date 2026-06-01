import { useEffect, useMemo, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Plus, Trash2, ClipboardList, Loader2, BadgeDollarSign, Calendar, Hourglass,
  Pencil, Repeat, Wallet,
} from "lucide-react";
import { toast } from "sonner";

const STATUS = ["all", "assigned", "in_progress", "completed"];
const STATUS_STYLE = {
  assigned:    "bg-zinc-800 text-zinc-300",
  in_progress: "bg-yellow-400/15 text-yellow-300",
  completed:   "bg-green-400/15 text-green-400",
};
const FREQUENCIES = [
  { value: "once",    label: "One-time" },
  { value: "daily",   label: "Daily" },
  { value: "weekly",  label: "Weekly" },
  { value: "monthly", label: "Monthly" },
];
const PAYOUTS = [
  { value: "per_task", label: "On completion" },
  { value: "daily",    label: "Daily" },
  { value: "weekly",   label: "Weekly" },
  { value: "monthly",  label: "Monthly" },
];
const FREQ_LABEL = Object.fromEntries(FREQUENCIES.map(f => [f.value, f.label]));
const PAYOUT_LABEL = Object.fromEntries(PAYOUTS.map(p => [p.value, p.label]));

const EMPTY = {
  title: "", description: "", price: "", assignee_id: "",
  due_at: "", estimated_hours: "", daily_hours: "",
  daily_hours_unit: "hours", // "hours" | "minutes"
  frequency: "once", payout_schedule: "per_task",
};

function toDateInput(iso) {
  if (!iso) return "";
  try { return new Date(iso).toISOString().slice(0, 10); } catch { return ""; }
}

function fmtDaily(h) {
  if (h == null) return "";
  const v = Number(h);
  if (!Number.isFinite(v)) return "";
  if (v < 1) {
    const mins = Math.round(v * 60);
    return `${mins}m/day`;
  }
  return `${(Math.round(v * 100) / 100)}h/day`;
}

export default function AdminTasks() {
  const [tasks, setTasks] = useState([]);
  const [workers, setWorkers] = useState([]);
  const [filter, setFilter] = useState("all");
  const [dialog, setDialog] = useState(null); // null | {mode:"create"} | {mode:"edit", task}
  const [form, setForm] = useState(EMPTY);
  const [busy, setBusy] = useState(false);

  const load = async () => {
    const [t, w] = await Promise.all([api.get("/tasks"), api.get("/workers")]);
    setTasks(t.data);
    setWorkers(w.data);
  };
  useEffect(() => { load(); }, []);

  const filtered = useMemo(() => filter === "all" ? tasks : tasks.filter(t => t.status === filter), [tasks, filter]);

  const openCreate = () => { setForm(EMPTY); setDialog({ mode: "create" }); };
  const openEdit = (t) => {
    // Prefer Minutes if the stored value is < 1 hour, so the admin sees a friendly number
    const dh = t.daily_hours;
    const useMinutes = dh != null && dh > 0 && dh < 1;
    setForm({
      title: t.title || "",
      description: t.description || "",
      price: String(t.price ?? ""),
      assignee_id: t.assignee_id,
      due_at: toDateInput(t.due_at),
      estimated_hours: t.estimated_hours != null ? String(t.estimated_hours) : "",
      daily_hours: dh != null ? String(useMinutes ? Math.round(dh * 60 * 100) / 100 : dh) : "",
      daily_hours_unit: useMinutes ? "minutes" : "hours",
      frequency: t.frequency || "once",
      payout_schedule: t.payout_schedule || "per_task",
    });
    setDialog({ mode: "edit", task: t });
  };

  const submit = async (e) => {
    e.preventDefault();
    if (!form.assignee_id) { toast.error("Pick a worker"); return; }
    if (!form.title.trim()) { toast.error("Title is required"); return; }
    setBusy(true);
    // Convert daily_hours according to unit toggle
    let dailyHours = null;
    if (form.daily_hours) {
      const v = parseFloat(form.daily_hours);
      if (Number.isFinite(v) && v >= 0) {
        dailyHours = form.daily_hours_unit === "minutes" ? v / 60 : v;
      }
    }
    const payload = {
      title: form.title.trim(),
      description: form.description,
      price: parseFloat(form.price),
      assignee_id: form.assignee_id,
      due_at: form.due_at || null,
      estimated_hours: form.estimated_hours ? parseFloat(form.estimated_hours) : null,
      daily_hours: dailyHours,
      frequency: form.frequency,
      payout_schedule: form.payout_schedule,
    };
    try {
      if (dialog?.mode === "edit") {
        await api.patch(`/tasks/${dialog.task.id}`, payload);
        toast.success("Task updated");
      } else {
        await api.post("/tasks", payload);
        toast.success("Task assigned");
      }
      setDialog(null);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const updateStatus = async (t, status) => {
    try { await api.patch(`/tasks/${t.id}`, { status }); toast.success(`Marked ${status.replace("_", " ")}`); load(); }
    catch (e) { toast.error(formatApiError(e)); }
  };

  const remove = async (t) => {
    if (!window.confirm(`Delete "${t.title}"?`)) return;
    try { await api.delete(`/tasks/${t.id}`); toast.success("Task deleted"); load(); }
    catch (e) { toast.error(formatApiError(e)); }
  };

  return (
    <div className="space-y-8">
      <div className="flex items-end justify-between gap-4 flex-wrap">
        <div>
          <div className="text-xs uppercase tracking-widest text-yellow-400">Workboard</div>
          <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">Assign & price tasks.</h1>
          <p className="mt-2 text-zinc-400">Set price, deadline, hours, frequency, and payout schedule for every task.</p>
        </div>
        <Button data-testid="open-create-task" disabled={workers.length === 0} onClick={openCreate}
          className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-11 px-5 disabled:opacity-50">
          <Plus className="w-4 h-4 mr-2" /> New task
        </Button>
      </div>

      <Tabs value={filter} onValueChange={setFilter}>
        <TabsList className="bg-[#121214] border border-yellow-400/15 rounded-xl p-1">
          {STATUS.map(s => (
            <TabsTrigger key={s} value={s} data-testid={`tab-${s}`}
              className="rounded-lg data-[state=active]:bg-yellow-400 data-[state=active]:text-black capitalize">
              {s.replace("_", " ")}
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>

      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl divide-y divide-yellow-400/5">
        {filtered.length === 0 && (
          <div className="p-10 text-center">
            <ClipboardList className="w-8 h-8 text-yellow-400 mx-auto" />
            <div className="mt-3 font-display text-xl">No tasks here</div>
            <div className="text-sm text-zinc-500">{workers.length === 0 ? "Create a worker first to assign tasks." : "Click \"New task\" to get started."}</div>
          </div>
        )}
        {filtered.map((t) => (
          <div key={t.id} data-testid={`task-row-${t.id}`} className="px-5 sm:px-6 py-4 flex items-center gap-3 flex-wrap hover:bg-white/[0.02]">
            <div className="flex-1 min-w-[260px]">
              <div className="flex items-center gap-2 flex-wrap">
                <div className="font-medium">{t.title}</div>
                <span className={`px-2.5 py-0.5 rounded-full text-xs ${STATUS_STYLE[t.status]}`}>{t.status.replace("_", " ")}</span>
                {t.frequency && t.frequency !== "once" && (
                  <span className="px-2.5 py-0.5 rounded-full text-xs bg-sky-400/15 text-sky-300 inline-flex items-center gap-1">
                    <Repeat className="w-3 h-3" /> {FREQ_LABEL[t.frequency]}
                  </span>
                )}
                {t.payout_schedule && t.payout_schedule !== "per_task" && (
                  <span className="px-2.5 py-0.5 rounded-full text-xs bg-emerald-400/15 text-emerald-300 inline-flex items-center gap-1">
                    <Wallet className="w-3 h-3" /> Paid {PAYOUT_LABEL[t.payout_schedule].toLowerCase()}
                  </span>
                )}
              </div>
              <div className="text-xs text-zinc-500 mt-1 flex flex-wrap items-center gap-x-3 gap-y-1">
                <span>{t.assignee_name}</span>
                {t.description && <span className="truncate max-w-[260px]">· {t.description}</span>}
                {t.due_at && <span className="text-zinc-400"><Calendar className="inline w-3 h-3 -mt-0.5" /> {new Date(t.due_at).toLocaleDateString(undefined,{month:"short",day:"numeric"})}</span>}
                {t.estimated_hours != null && <span className="text-zinc-400"><Hourglass className="inline w-3 h-3 -mt-0.5" /> {t.estimated_hours}h total</span>}
                {t.daily_hours != null && <span className="text-zinc-400"><Hourglass className="inline w-3 h-3 -mt-0.5" /> {fmtDaily(t.daily_hours)}</span>}
              </div>
            </div>
            <div className="flex items-center gap-2">
              <div className="flex items-center bg-zinc-900 border border-zinc-800 rounded-lg px-2 h-9">
                <BadgeDollarSign className="w-3.5 h-3.5 text-yellow-400 mr-1" />
                <span data-testid={`task-price-${t.id}`} className="w-20 text-white text-sm">{Number(t.price).toFixed(2)}</span>
              </div>
              <Button data-testid={`edit-task-${t.id}`} onClick={() => openEdit(t)} size="sm" variant="ghost"
                className="rounded-lg h-9 px-3 text-zinc-300 hover:text-yellow-400 border border-yellow-400/15">
                <Pencil className="w-4 h-4" />
              </Button>
              {t.status !== "completed" && (
                <Button data-testid={`mark-complete-${t.id}`} onClick={() => updateStatus(t, "completed")}
                  size="sm" className="bg-green-500/20 hover:bg-green-500/30 text-green-400 border border-green-400/30 rounded-lg">
                  Mark complete
                </Button>
              )}
              <button data-testid={`delete-task-${t.id}`} onClick={() => remove(t)} className="text-zinc-500 hover:text-red-400 transition">
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        ))}
      </div>

      <Dialog open={!!dialog} onOpenChange={(o) => !o && setDialog(null)}>
        <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl max-w-xl" aria-describedby={undefined}>
          <DialogHeader>
            <DialogTitle className="font-display text-2xl">
              {dialog?.mode === "edit" ? "Edit task" : "Assign a task"}
            </DialogTitle>
          </DialogHeader>
          <form onSubmit={submit} className="space-y-4 max-h-[70vh] overflow-y-auto pr-1">
            <div>
              <label className="text-xs uppercase tracking-widest text-zinc-500">Title</label>
              <Input data-testid="task-title" required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })}
                className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-zinc-500">Description</label>
              <Textarea data-testid="task-description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })}
                className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl min-h-20" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Price (USD)</label>
                <Input data-testid="task-price-input" required type="number" min="0" step="0.01" value={form.price}
                  onChange={(e) => setForm({ ...form, price: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Assignee</label>
                <Select value={form.assignee_id} onValueChange={(v) => setForm({ ...form, assignee_id: v })}>
                  <SelectTrigger data-testid="task-assignee" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11">
                    <SelectValue placeholder="Pick worker" />
                  </SelectTrigger>
                  <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                    {workers.map((w) => (
                      <SelectItem key={w.id} value={w.id} data-testid={`assignee-option-${w.id}`}>{w.name} · {w.email}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Deadline</label>
                <Input data-testid="task-due-at" type="date" value={form.due_at}
                  onChange={(e) => setForm({ ...form, due_at: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11 [color-scheme:dark]" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Total est. hours</label>
                <Input data-testid="task-estimated-hours" type="number" min="0" step="any" inputMode="decimal" placeholder="e.g., 3.33"
                  value={form.estimated_hours}
                  onChange={(e) => setForm({ ...form, estimated_hours: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                <div className="text-[10px] text-zinc-500 mt-1">Any decimal — 3.33, 7.5, 0.25, anything.</div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <div className="flex items-center justify-between">
                  <label className="text-xs uppercase tracking-widest text-zinc-500">Daily required</label>
                  <div className="inline-flex items-center bg-zinc-900 border border-zinc-800 rounded-full p-0.5">
                    {["hours", "minutes"].map((u) => (
                      <button
                        key={u}
                        type="button"
                        data-testid={`unit-${u}`}
                        onClick={() => setForm((f) => ({ ...f, daily_hours_unit: u }))}
                        className={`px-3 py-1 rounded-full text-[10px] uppercase tracking-widest transition ${
                          form.daily_hours_unit === u ? "bg-yellow-400 text-black font-semibold" : "text-zinc-400 hover:text-white"
                        }`}
                      >
                        {u === "hours" ? "Hours" : "Minutes"}
                      </button>
                    ))}
                  </div>
                </div>
                <Input
                  data-testid="task-daily-hours"
                  type="number"
                  min="0"
                  step="any"
                  inputMode="decimal"
                  placeholder={form.daily_hours_unit === "minutes" ? "e.g., 45" : "e.g., 1.5"}
                  value={form.daily_hours}
                  onChange={(e) => setForm({ ...form, daily_hours: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11"
                />
                <div className="text-[10px] text-zinc-500 mt-1">
                  Stored internally as hours · 45 min = 0.75h
                </div>
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Frequency</label>
                <Select value={form.frequency} onValueChange={(v) => setForm({ ...form, frequency: v })}>
                  <SelectTrigger data-testid="task-frequency" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                    {FREQUENCIES.map(f => (
                      <SelectItem key={f.value} value={f.value} data-testid={`freq-${f.value}`}>{f.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-zinc-500">Payout schedule</label>
              <Select value={form.payout_schedule} onValueChange={(v) => setForm({ ...form, payout_schedule: v })}>
                <SelectTrigger data-testid="task-payout" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                  {PAYOUTS.map(p => (
                    <SelectItem key={p.value} value={p.value} data-testid={`payout-${p.value}`}>{p.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <div className="text-xs text-zinc-500 mt-1.5">
                <span className="text-zinc-400">On completion</span> = pay when worker marks done · <span className="text-zinc-400">Daily/Weekly/Monthly</span> = recurring payout.
              </div>
            </div>
            <DialogFooter>
              <Button data-testid="submit-task" type="submit" disabled={busy}
                className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : (dialog?.mode === "edit" ? "Save changes" : "Assign task")}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
