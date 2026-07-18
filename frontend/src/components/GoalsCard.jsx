import { useEffect, useRef, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import {
  Target, Plus, Image as ImageIcon, Link as LinkIcon, Calendar, Loader2,
  Trash2, Sparkles, CheckCircle2, Clock, AlertTriangle, ExternalLink, Pencil,
  TrendingUp, BadgeDollarSign, Percent,
} from "lucide-react";
import { toast } from "sonner";
import Reactions from "@/components/Reactions";
import CongratsModal from "@/components/CongratsModal";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const PERIODS = [
  { value: "once",    label: "One-time" },
  { value: "daily",   label: "Daily" },
  { value: "weekly",  label: "Weekly" },
  { value: "monthly", label: "Monthly" },
  { value: "yearly",  label: "Yearly" },
];
const PERIOD_LABEL = { once: "One-time", daily: "Daily", weekly: "Weekly", monthly: "Monthly", yearly: "Yearly" };

function fmtDate(iso) {
  if (!iso) return null;
  try { return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" }); }
  catch { return null; }
}
function getStatus(g) {
  if (g.status === "completed") {
    if (g.deadline && g.completed_at && new Date(g.completed_at) <= new Date(g.deadline)) {
      return { key: "ahead", label: "Ahead of deadline", icon: Sparkles, className: "bg-yellow-400/15 text-yellow-300" };
    }
    return { key: "done", label: "Achieved", icon: CheckCircle2, className: "bg-green-400/15 text-green-400" };
  }
  if (g.deadline && new Date(g.deadline).getTime() < Date.now()) {
    return { key: "overdue", label: "Overdue", icon: AlertTriangle, className: "bg-red-400/15 text-red-400" };
  }
  return { key: "open", label: "In progress", icon: Clock, className: "bg-zinc-800 text-zinc-300" };
}

const EMPTY = { title: "", product_link: "", deadline: "", target_amount: "", period: "weekly", allocation_percent: "100" };

export default function GoalsCard() {
  const [goals, setGoals] = useState([]);
  const [dialog, setDialog] = useState(null);
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState(EMPTY);
  const [file, setFile] = useState(null);
  const [congrats, setCongrats] = useState(null);
  const fileRef = useRef(null);

  const load = async () => {
    const { data } = await api.get("/goals?kind=goal");
    setGoals(data);
    // Find newest unacknowledged completed goal and pop the modal
    const unack = data.find((g) => g.status === "completed" && g.completed_at && !g.acknowledged_at);
    if (unack && (!congrats || congrats.id !== unack.id)) setCongrats(unack);
  };
  useEffect(() => { load(); /* eslint-disable-next-line */ }, []);

  const openCreate = () => { setForm(EMPTY); setFile(null); setDialog({ mode: "create" }); };
  const openEdit = (g) => {
    setForm({
      title: g.title || "",
      product_link: g.product_link || "",
      deadline: g.deadline ? new Date(g.deadline).toISOString().slice(0, 10) : "",
      target_amount: g.target_amount != null ? String(g.target_amount) : "",
      period: g.period || "weekly",
      allocation_percent: g.allocation_percent != null ? String(g.allocation_percent) : "100",
    });
    setFile(null);
    setDialog({ mode: "edit", goal: g });
  };

  const submit = async (e) => {
    e.preventDefault();
    if (!form.title.trim()) { toast.error("Add a title for your goal"); return; }
    setBusy(true);
    try {
      if (dialog?.mode === "edit") {
        const payload = {
          title: form.title.trim(),
          product_link: form.product_link.trim(),
          deadline: form.deadline || null,
          target_amount: form.target_amount ? parseFloat(form.target_amount) : null,
          period: form.period,
          allocation_percent: form.allocation_percent ? parseFloat(form.allocation_percent) : 0,
        };
        await api.patch(`/goals/${dialog.goal.id}`, payload);
        toast.success("Goal updated");
      } else {
        const params = new URLSearchParams();
        params.set("title", form.title.trim());
        if (form.product_link.trim()) params.set("product_link", form.product_link.trim());
        if (form.deadline) params.set("deadline", form.deadline);
        if (form.target_amount) params.set("target_amount", form.target_amount);
        if (form.period) params.set("period", form.period);
        if (form.allocation_percent !== "") params.set("allocation_percent", form.allocation_percent);
        params.set("kind", "goal");
        const fd = new FormData();
        if (file) fd.append("file", file);
        await api.post(`/goals?${params.toString()}`, fd, { headers: { "Content-Type": "multipart/form-data" } });
        toast.success("Goal added");
      }
      setDialog(null); setForm(EMPTY); setFile(null);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const remove = async (g) => {
    if (!window.confirm(`Delete "${g.title}"?`)) return;
    try { await api.delete(`/goals/${g.id}`); toast.success("Goal removed"); load(); }
    catch (e) { toast.error(formatApiError(e)); }
  };

  const pickFile = () => fileRef.current?.click();
  const onFileChange = (e) => {
    const f = e.target.files?.[0];
    e.target.value = "";
    if (!f) return;
    if (!/^image\/(png|jpe?g|webp|gif)$/i.test(f.type)) { toast.error("Pick a PNG, JPEG, WEBP, or GIF image"); return; }
    if (f.size > 3 * 1024 * 1024) { toast.error("Image too large (max 3 MB)"); return; }
    setFile(f);
  };

  const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;

  return (
    <section data-testid="goals-card">
      <div className="flex items-end justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-yellow-400/10 text-yellow-400 grid place-items-center">
            <Target className="w-5 h-5" />
          </div>
          <div>
            <h2 className="font-display text-2xl font-semibold tracking-tight">Goals & wishlist</h2>
            <p className="text-xs text-zinc-500 mt-0.5">Set a target, an allocation %, and watch each completed task chip in.</p>
          </div>
        </div>
        <Button data-testid="open-create-goal" onClick={openCreate}
          className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-10 px-4">
          <Plus className="w-4 h-4 mr-2" /> New goal
        </Button>
      </div>

      <div className="space-y-4">
        {goals.length === 0 && (
          <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-10 text-center">
            <Target className="w-7 h-7 text-yellow-400 mx-auto" />
            <div className="mt-3 font-display text-xl">No goals yet</div>
            <div className="text-sm text-zinc-500">Hit "New goal" to drop a product you're saving up for or a milestone you want to hit.</div>
          </div>
        )}
        {goals.map((g) => {
          const status = getStatus(g);
          const StatusIcon = status.icon;
          const target = Number(g.target_amount || 0);
          const period = g.period || "weekly";
          const pct = g.progress?.pct_of_target || 0;
          const periodAmt = g.progress?.period_amount || 0;
          return (
            <div key={g.id} data-testid={`worker-goal-${g.id}`}
              className={`bg-[#121214] border rounded-2xl p-5 ${g.status === "completed" ? "border-yellow-400/30" : "border-yellow-400/15"}`}>
              <div className="flex gap-4">
                <div className="shrink-0 w-24 h-24 rounded-xl overflow-hidden bg-zinc-900 border border-yellow-400/10 grid place-items-center">
                  {g.image_url ? (
                    <img alt={g.title} src={`${BACKEND_URL}${g.image_url}${token ? `?auth=${token}` : ""}`} className="w-full h-full object-cover" />
                  ) : (
                    <Target className="w-7 h-7 text-zinc-700" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <div className={`font-display text-lg font-semibold ${g.status === "completed" ? "text-zinc-300 line-through" : ""}`}>{g.title}</div>
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs ${status.className}`}>
                      <StatusIcon className="w-3 h-3" /> {status.label}
                    </span>
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-sky-400/15 text-sky-300">
                      <TrendingUp className="w-3 h-3" /> {PERIOD_LABEL[period]}
                    </span>
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-emerald-400/15 text-emerald-300">
                      <Percent className="w-3 h-3" /> {Number(g.allocation_percent || 0)}% alloc
                    </span>
                  </div>
                  <div className="mt-1 flex flex-wrap items-center gap-3 text-xs text-zinc-500">
                    {g.deadline && <span className="inline-flex items-center gap-1"><Calendar className="w-3 h-3" /> by {fmtDate(g.deadline)}</span>}
                    {g.product_link && (
                      <a href={g.product_link} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-yellow-400 hover:underline truncate max-w-[220px]">
                        <ExternalLink className="w-3 h-3" /> {(() => { try { return new URL(g.product_link).hostname; } catch { return g.product_link; } })()}
                      </a>
                    )}
                  </div>

                  {/* Progress block */}
                  <div className="mt-3">
                    <div className="flex items-baseline gap-2 flex-wrap">
                      <div className="font-display text-2xl font-bold tabular-nums text-yellow-400">${periodAmt.toFixed(2)}</div>
                      {target > 0 && <div className="text-sm text-zinc-400">of ${target.toFixed(2)} · <span className="text-yellow-300">{pct}%</span> this {period}</div>}
                      {!target && <div className="text-xs text-zinc-500">Set a target $ to track % progress</div>}
                    </div>
                    {target > 0 && (
                      <div className="mt-2 h-2.5 bg-zinc-900 rounded-full overflow-hidden">
                        <div className="h-full bg-gradient-to-r from-yellow-300 to-yellow-500 rounded-full transition-all" style={{ width: `${pct}%` }} />
                      </div>
                    )}
                    <div className="mt-3 grid grid-cols-4 gap-2 text-[11px]">
                      <div className="rounded-lg bg-zinc-900/60 border border-zinc-800 px-2 py-1.5">
                        <div className="uppercase tracking-widest text-zinc-500">Today</div>
                        <div className="font-display text-sm font-semibold text-white tabular-nums">${(g.progress?.today || 0).toFixed(2)}</div>
                      </div>
                      <div className="rounded-lg bg-zinc-900/60 border border-zinc-800 px-2 py-1.5">
                        <div className="uppercase tracking-widest text-zinc-500">Week</div>
                        <div className="font-display text-sm font-semibold text-white tabular-nums">${(g.progress?.week || 0).toFixed(2)}</div>
                      </div>
                      <div className="rounded-lg bg-zinc-900/60 border border-zinc-800 px-2 py-1.5">
                        <div className="uppercase tracking-widest text-zinc-500">Month</div>
                        <div className="font-display text-sm font-semibold text-white tabular-nums">${(g.progress?.month || 0).toFixed(2)}</div>
                      </div>
                      <div className="rounded-lg bg-zinc-900/60 border border-zinc-800 px-2 py-1.5">
                        <div className="uppercase tracking-widest text-zinc-500">Year</div>
                        <div className="font-display text-sm font-semibold text-white tabular-nums">${(g.progress?.year || 0).toFixed(2)}</div>
                      </div>
                    </div>
                  </div>

                  {g.status === "completed" && g.appreciation && (
                    <div className="mt-3 px-3 py-2 rounded-xl bg-yellow-400/10 border border-yellow-400/30 text-sm text-yellow-100 flex items-start gap-2">
                      <Sparkles className="w-4 h-4 text-yellow-400 mt-0.5 shrink-0" />
                      <div><span className="text-yellow-400 font-semibold">From your admin:</span> {g.appreciation}</div>
                    </div>
                  )}

                  <div className="mt-3">
                    <Reactions goal={g} onChange={(u) => setGoals((gs) => gs.map((x) => x.id === u.id ? { ...x, reactions: u.reactions } : x))} />
                  </div>
                </div>

                <div className="flex flex-col items-end gap-2">
                  <button data-testid={`edit-goal-${g.id}`} onClick={() => openEdit(g)} className="text-zinc-500 hover:text-yellow-400 transition" aria-label="Edit goal">
                    <Pencil className="w-4 h-4" />
                  </button>
                  <button data-testid={`delete-goal-${g.id}`} onClick={() => remove(g)} className="text-zinc-500 hover:text-red-400 transition" aria-label="Delete goal">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <Dialog open={!!dialog} onOpenChange={(o) => !o && setDialog(null)}>
        <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl" aria-describedby={undefined}>
          <DialogHeader><DialogTitle className="font-display text-2xl">{dialog?.mode === "edit" ? "Edit goal" : "Add a goal"}</DialogTitle></DialogHeader>
          <form onSubmit={submit} className="space-y-4">
            <div>
              <label className="text-xs uppercase tracking-widest text-zinc-500">What do you want?</label>
              <Input data-testid="goal-title" required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })}
                placeholder="e.g., New steel-toe boots" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><BadgeDollarSign className="w-3 h-3" /> Target amount</label>
                <Input data-testid="goal-target" type="number" min="0" step="any" inputMode="decimal" placeholder="e.g., 200"
                  value={form.target_amount} onChange={(e) => setForm({ ...form, target_amount: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Period</label>
                <Select value={form.period} onValueChange={(v) => setForm({ ...form, period: v })}>
                  <SelectTrigger data-testid="goal-period" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                    {PERIODS.map(p => <SelectItem key={p.value} value={p.value} data-testid={`goal-period-${p.value}`}>{p.label}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><Percent className="w-3 h-3" /> Allocation % of task earnings</label>
              <Input data-testid="goal-allocation" type="number" min="0" max="100" step="any" inputMode="decimal" placeholder="e.g., 50"
                value={form.allocation_percent} onChange={(e) => setForm({ ...form, allocation_percent: e.target.value })}
                className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              <div className="text-[10px] text-zinc-500 mt-1">e.g., 50% means half of every completed task's earnings counts toward this goal.</div>
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><LinkIcon className="w-3 h-3" /> Product link (optional)</label>
              <Input data-testid="goal-link" type="url" value={form.product_link} onChange={(e) => setForm({ ...form, product_link: e.target.value })}
                placeholder="https://..." className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><Calendar className="w-3 h-3" /> Deadline (optional)</label>
              <Input data-testid="goal-deadline" type="date" value={form.deadline} onChange={(e) => setForm({ ...form, deadline: e.target.value })}
                className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11 [color-scheme:dark]" />
            </div>
            {dialog?.mode !== "edit" && (
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Photo (optional)</label>
                <input ref={fileRef} type="file" accept="image/png,image/jpeg,image/webp,image/gif" data-testid="goal-file-input" onChange={onFileChange} className="hidden" />
                <button type="button" data-testid="goal-pick-image" onClick={pickFile}
                  className="mt-2 w-full h-11 rounded-xl bg-zinc-900 border border-dashed border-yellow-400/30 hover:border-yellow-400/60 text-zinc-300 flex items-center justify-center gap-2 transition">
                  <ImageIcon className="w-4 h-4" /> {file ? file.name : "Tap to add a picture"}
                </button>
              </div>
            )}
            <DialogFooter>
              <Button data-testid="submit-goal" type="submit" disabled={busy}
                className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : (dialog?.mode === "edit" ? "Save changes" : "Save goal")}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
      {congrats && <CongratsModal goal={congrats} onClose={() => setCongrats(null)} />}
    </section>
  );
}
