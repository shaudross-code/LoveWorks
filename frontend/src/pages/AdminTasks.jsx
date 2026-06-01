import { useEffect, useMemo, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus, Trash2, ClipboardList, Loader2, BadgeDollarSign, Calendar, Hourglass } from "lucide-react";
import { toast } from "sonner";

const STATUS = ["all", "assigned", "in_progress", "completed"];
const STATUS_STYLE = {
  assigned:    "bg-zinc-800 text-zinc-300",
  in_progress: "bg-yellow-400/15 text-yellow-300",
  completed:   "bg-green-400/15 text-green-400",
};

export default function AdminTasks() {
  const [tasks, setTasks] = useState([]);
  const [workers, setWorkers] = useState([]);
  const [filter, setFilter] = useState("all");
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ title: "", description: "", price: "", assignee_id: "", due_at: "", estimated_hours: "" });
  const [busy, setBusy] = useState(false);

  const load = async () => {
    const [t, w] = await Promise.all([api.get("/tasks"), api.get("/workers")]);
    setTasks(t.data);
    setWorkers(w.data);
  };
  useEffect(() => { load(); }, []);

  const filtered = useMemo(() => filter === "all" ? tasks : tasks.filter(t => t.status === filter), [tasks, filter]);

  const create = async (e) => {
    e.preventDefault();
    if (!form.assignee_id) { toast.error("Pick a worker"); return; }
    setBusy(true);
    try {
      const payload = {
        title: form.title,
        description: form.description,
        price: parseFloat(form.price),
        assignee_id: form.assignee_id,
        due_at: form.due_at || null,
        estimated_hours: form.estimated_hours ? parseFloat(form.estimated_hours) : null,
      };
      await api.post("/tasks", payload);
      toast.success("Task assigned");
      setForm({ title: "", description: "", price: "", assignee_id: "", due_at: "", estimated_hours: "" });
      setOpen(false);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const updateStatus = async (t, status) => {
    try {
      await api.patch(`/tasks/${t.id}`, { status });
      toast.success(`Marked ${status.replace("_", " ")}`);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  };

  const updatePrice = async (t, price) => {
    const n = parseFloat(price);
    if (Number.isNaN(n) || n < 0) { toast.error("Enter a valid price"); return; }
    try {
      await api.patch(`/tasks/${t.id}`, { price: n });
      toast.success("Price updated");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
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
          <p className="mt-2 text-zinc-400">Set a fixed payout per task. Workers see it the moment they sign in.</p>
        </div>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button data-testid="open-create-task" disabled={workers.length === 0} className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-11 px-5 disabled:opacity-50">
              <Plus className="w-4 h-4 mr-2" /> New task
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl">
            <DialogHeader><DialogTitle className="font-display text-2xl">Assign a task</DialogTitle></DialogHeader>
            <form onSubmit={create} className="space-y-4">
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Title</label>
                <Input data-testid="task-title" required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Description</label>
                <Textarea data-testid="task-description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl min-h-24" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500">Price (USD)</label>
                  <Input data-testid="task-price" required type="number" min="0" step="0.01" value={form.price}
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
                  <label className="text-xs uppercase tracking-widest text-zinc-500">Due date (optional)</label>
                  <Input data-testid="task-due-at" type="date" value={form.due_at}
                    onChange={(e) => setForm({ ...form, due_at: e.target.value })}
                    className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11 [color-scheme:dark]" />
                </div>
                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500">Estimated hours</label>
                  <Input data-testid="task-estimated-hours" type="number" min="0" step="0.5" placeholder="e.g., 2"
                    value={form.estimated_hours}
                    onChange={(e) => setForm({ ...form, estimated_hours: e.target.value })}
                    className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                </div>
              </div>
              <DialogFooter>
                <Button data-testid="submit-create-task" type="submit" disabled={busy} className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : "Assign task"}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <Tabs value={filter} onValueChange={setFilter}>
        <TabsList className="bg-[#121214] border border-yellow-400/15 rounded-xl p-1">
          {STATUS.map(s => (
            <TabsTrigger key={s} value={s} data-testid={`tab-${s}`}
              className="rounded-lg data-[state=active]:bg-yellow-400 data-[state=active]:text-black data-[state=active]:shadow-none capitalize">
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
          <div key={t.id} data-testid={`task-row-${t.id}`} className="px-5 sm:px-6 py-4 flex items-center gap-4 hover:bg-white/[0.02]">
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <div className="font-medium">{t.title}</div>
                <span className={`px-2.5 py-0.5 rounded-full text-xs ${STATUS_STYLE[t.status]}`}>{t.status.replace("_", " ")}</span>
              </div>
              <div className="text-xs text-zinc-500 mt-0.5 truncate flex flex-wrap items-center gap-x-3 gap-y-1">
                <span>{t.assignee_name}</span>
                {t.description && <span>· {t.description}</span>}
                {t.due_at && <span className="text-zinc-400"><Calendar className="inline w-3 h-3 -mt-0.5" /> {new Date(t.due_at).toLocaleDateString(undefined,{month:"short",day:"numeric"})}</span>}
                {t.estimated_hours != null && <span className="text-zinc-400"><Hourglass className="inline w-3 h-3 -mt-0.5" /> {t.estimated_hours}h</span>}
              </div>
            </div>
            <div className="flex items-center gap-2">
              <div className="flex items-center bg-zinc-900 border border-zinc-800 rounded-lg px-2 h-9">
                <BadgeDollarSign className="w-3.5 h-3.5 text-yellow-400 mr-1" />
                <input
                  data-testid={`task-price-input-${t.id}`}
                  type="number" min="0" step="0.01" defaultValue={Number(t.price).toFixed(2)}
                  onBlur={(e) => { if (parseFloat(e.target.value) !== Number(t.price)) updatePrice(t, e.target.value); }}
                  className="w-20 bg-transparent text-white text-sm outline-none"
                />
              </div>
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
    </div>
  );
}
