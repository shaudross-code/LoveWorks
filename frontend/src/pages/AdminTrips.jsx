import { useEffect, useMemo, useRef, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import Avatar from "@/components/Avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Target, Calendar, ExternalLink, Sparkles, CheckCircle2, Clock, AlertTriangle, RotateCcw, Loader2, Percent, BadgeDollarSign, TrendingUp, Pencil, Plus, UserCircle2, Image as ImageIcon, Upload, Trash2 } from "lucide-react";
import { toast } from "sonner";
import Reactions from "@/components/Reactions";

const QUICK_QUOTES = [
  "🛒 Ordering it soon!",
  "✅ It's already ordered.",
  "📦 It will be shipped soon.",
  "👏 Good job — you earned it!",
  "🌟 So proud of you!",
  "🎉 Way to go — crushed it!",
];

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const STATUS_TABS = ["all", "open", "overdue", "completed"];
const PERIODS = [
  { value: "daily",   label: "Daily" },
  { value: "weekly",  label: "Weekly" },
  { value: "monthly", label: "Monthly" },
  { value: "yearly",  label: "Yearly" },
];
const PERIOD_LABEL = { daily: "Daily", weekly: "Weekly", monthly: "Monthly", yearly: "Yearly" };

function fmtDate(iso) {
  if (!iso) return null;
  try { return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" }); }
  catch { return null; }
}

function statusOf(g) {
  if (g.status === "completed") return "completed";
  if (g.deadline && new Date(g.deadline).getTime() < Date.now()) return "overdue";
  return "open";
}

function statusBadge(s) {
  const map = {
    open:      { Icon: Clock,          cls: "bg-zinc-800 text-zinc-300",          label: "In progress" },
    overdue:   { Icon: AlertTriangle,  cls: "bg-red-400/15 text-red-400",         label: "Overdue" },
    completed: { Icon: CheckCircle2,   cls: "bg-green-400/15 text-green-400",     label: "Achieved" },
  };
  return map[s] || map.open;
}

export default function AdminTrips() {
  const [goals, setGoals] = useState([]);
  const [workers, setWorkers] = useState([]);
  const [filter, setFilter] = useState("all");
  const [dialog, setDialog] = useState(null); // {goal, mode: 'complete' | 'edit'} | {mode: 'assign'}
  const [appreciation, setAppreciation] = useState("");
  const [editForm, setEditForm] = useState({ target_amount: "", period: "weekly", allocation_percent: "100" });
  const [assignForm, setAssignForm] = useState({
    assignee_id: "", title: "", target_amount: "", period: "weekly",
    allocation_percent: "100", deadline: "", product_link: "",
  });
  const [busy, setBusy] = useState(false);

  const load = async () => {
    const [g, w] = await Promise.all([api.get("/goals?kind=trip"), api.get("/workers")]);
    setGoals(g.data);
    setWorkers(w.data);
  };
  useEffect(() => { load(); }, []);

  const filtered = useMemo(() => {
    if (filter === "all") return goals;
    return goals.filter((g) => statusOf(g) === filter);
  }, [goals, filter]);

  const openComplete = (g) => {
    setDialog({ goal: g, mode: "complete" });
    setAppreciation(g.deadline && new Date(g.deadline).getTime() > Date.now()
      ? `Wow, ahead of schedule — proud of you for hitting "${g.title}"!`
      : `Goal achieved — nice work on "${g.title}"!`);
  };

  const openEdit = (g) => {
    setEditForm({
      target_amount: g.target_amount != null ? String(g.target_amount) : "",
      period: g.period || "weekly",
      allocation_percent: g.allocation_percent != null ? String(g.allocation_percent) : "100",
    });
    setDialog({ goal: g, mode: "edit" });
  };

  const openAssign = () => {
    setAssignForm({
      assignee_id: workers[0]?.id || "",
      title: "", target_amount: "", period: "weekly",
      allocation_percent: "100", deadline: "", product_link: "",
    });
    setDialog({ mode: "assign" });
  };

  const confirmAssign = async () => {
    if (!assignForm.assignee_id) { toast.error("Pick a worker"); return; }
    if (!assignForm.title.trim()) { toast.error("Add a title"); return; }
    setBusy(true);
    try {
      const params = new URLSearchParams();
      params.set("title", assignForm.title.trim());
      params.set("assignee_id", assignForm.assignee_id);
      params.set("kind", "trip");
      if (assignForm.target_amount) params.set("target_amount", assignForm.target_amount);
      if (assignForm.period) params.set("period", assignForm.period);
      if (assignForm.allocation_percent !== "") params.set("allocation_percent", assignForm.allocation_percent);
      if (assignForm.deadline) params.set("deadline", assignForm.deadline);
      if (assignForm.product_link.trim()) params.set("product_link", assignForm.product_link.trim());
      await api.post(`/goals?${params.toString()}`, new FormData(), { headers: { "Content-Type": "multipart/form-data" } });
      toast.success("Trip assigned ✈️");
      setDialog(null);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const confirmEdit = async () => {
    if (!dialog?.goal) return;
    setBusy(true);
    try {
      await api.patch(`/goals/${dialog.goal.id}`, {
        target_amount: editForm.target_amount ? parseFloat(editForm.target_amount) : null,
        period: editForm.period,
        allocation_percent: editForm.allocation_percent ? parseFloat(editForm.allocation_percent) : 0,
      });
      toast.success("Trip settings saved");
      setDialog(null);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const editFileRef = useRef(null);
  const [uploadingImg, setUploadingImg] = useState(false);

  const onPickImage = () => editFileRef.current?.click();

  const uploadGoalImage = async (file) => {
    if (!dialog?.goal || !file) return;
    if (file.size > 3 * 1024 * 1024) { toast.error("Image too large (max 3 MB)"); return; }
    setUploadingImg(true);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const { data } = await api.post(`/goals/${dialog.goal.id}/image`, fd, { headers: { "Content-Type": "multipart/form-data" } });
      // refresh both the dialog goal and the list
      setDialog((d) => d?.goal ? { ...d, goal: { ...d.goal, image_url: data.image_url, image_path: data.image_path } } : d);
      toast.success("Image updated");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setUploadingImg(false); if (editFileRef.current) editFileRef.current.value = ""; }
  };

  const removeGoalImage = async () => {
    if (!dialog?.goal) return;
    setUploadingImg(true);
    try {
      const { data } = await api.delete(`/goals/${dialog.goal.id}/image`);
      setDialog((d) => d?.goal ? { ...d, goal: { ...d.goal, image_url: data.image_url, image_path: null } } : d);
      toast.success("Image removed");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setUploadingImg(false); }
  };

  const openDelete = (g) => setDialog({ goal: g, mode: "delete" });

  const confirmDelete = async () => {
    if (!dialog?.goal) return;
    setBusy(true);
    try {
      await api.delete(`/goals/${dialog.goal.id}`);
      toast.success("Trip deleted");
      setDialog(null);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const confirmComplete = async () => {
    if (!dialog?.goal) return;
    setBusy(true);
    try {
      await api.post(`/goals/${dialog.goal.id}/complete`, { appreciation });
      toast.success("Trip booked 🎉");
      setDialog(null);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const reopen = async (g) => {
    try { await api.post(`/goals/${g.id}/reopen`); toast.success("Trip reopened"); load(); }
    catch (e) { toast.error(formatApiError(e)); }
  };

  const counts = useMemo(() => ({
    all: goals.length,
    open: goals.filter(g => statusOf(g) === "open").length,
    overdue: goals.filter(g => statusOf(g) === "overdue").length,
    completed: goals.filter(g => statusOf(g) === "completed").length,
  }), [goals]);

  const totals = useMemo(() => {
    const sum = (arr) => arr.reduce((s, g) => s + Number(g.target_amount || 0), 0);
    const completed = goals.filter(g => statusOf(g) === "completed");
    const outstanding = goals.filter(g => statusOf(g) !== "completed");
    return {
      all: sum(goals),
      completed: sum(completed),
      outstanding: sum(outstanding),
    };
  }, [goals]);

  const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;

  return (
    <div className="space-y-8">
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <div className="text-xs uppercase tracking-widest text-yellow-400">Trips</div>
          <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">Travel plans.</h1>
          <p className="mt-2 text-zinc-400">Where your crew dreams of going. Mark a trip booked when they earn it and leave a note of celebration.</p>
        </div>
        <Button data-testid="assign-trip-btn" onClick={openAssign}
          className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-10 px-5">
          <Plus className="w-4 h-4 mr-2" /> Assign trip to worker
        </Button>
      </div>

      {/* Totals row — combined goal value & how much has already been delivered */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div data-testid="trips-total-all"
          className="relative overflow-hidden rounded-2xl p-5 bg-gradient-to-br from-yellow-400/[0.07] via-[#121214] to-[#121214] border border-yellow-400/20">
          <div className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1.5">
            <Target className="w-3.5 h-3.5 text-yellow-400" /> All trips combined
          </div>
          <div className="mt-2 font-display text-3xl font-bold text-yellow-400 tabular-nums">
            ${totals.all.toFixed(2)}
          </div>
          <div className="text-xs text-zinc-500 mt-1">{counts.all} trip{counts.all === 1 ? "" : "s"} on the itinerary</div>
        </div>
        <div data-testid="trips-total-delivered"
          className="relative overflow-hidden rounded-2xl p-5 bg-gradient-to-br from-emerald-400/[0.07] via-[#121214] to-[#121214] border border-emerald-400/25">
          <div className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1.5">
            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" /> Booked / completed
          </div>
          <div className="mt-2 font-display text-3xl font-bold text-emerald-400 tabular-nums">
            ${totals.completed.toFixed(2)}
          </div>
          <div className="text-xs text-zinc-500 mt-1">{counts.completed} trip{counts.completed === 1 ? "" : "s"} celebrated</div>
        </div>
        <div data-testid="trips-total-outstanding"
          className="relative overflow-hidden rounded-2xl p-5 bg-gradient-to-br from-rose-400/[0.06] via-[#121214] to-[#121214] border border-rose-400/20">
          <div className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1.5">
            <Clock className="w-3.5 h-3.5 text-rose-300" /> Still to book
          </div>
          <div className="mt-2 font-display text-3xl font-bold text-rose-300 tabular-nums">
            ${totals.outstanding.toFixed(2)}
          </div>
          <div className="text-xs text-zinc-500 mt-1">{counts.all - counts.completed} planning + overdue</div>
        </div>
      </div>

      <Tabs value={filter} onValueChange={setFilter}>
        <TabsList className="bg-[#121214] border border-yellow-400/15 rounded-xl p-1">
          {STATUS_TABS.map((s) => (
            <TabsTrigger key={s} value={s} data-testid={`trips-tab-${s}`}
              className="rounded-lg data-[state=active]:bg-yellow-400 data-[state=active]:text-black capitalize">
              {s} <span className="ml-1.5 text-xs opacity-60">{counts[s]}</span>
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>

      <div className="grid md:grid-cols-2 gap-4">
        {filtered.length === 0 && (
          <div className="col-span-full bg-[#121214] border border-yellow-400/15 rounded-2xl p-10 text-center">
            <Target className="w-8 h-8 text-yellow-400 mx-auto" />
            <div className="mt-3 font-display text-xl">No trips planned yet</div>
            <div className="text-sm text-zinc-500">Use <span className="text-yellow-400 font-semibold">Assign trip to worker</span> to set someone's next adventure.</div>
          </div>
        )}
        {filtered.map((g) => {
          const s = statusOf(g);
          const { Icon, cls, label } = statusBadge(s);
          const ahead = g.status === "completed" && g.deadline && g.completed_at && new Date(g.completed_at) <= new Date(g.deadline);
          return (
            <div key={g.id} data-testid={`admin-goal-${g.id}`}
              className={`bg-[#121214] border rounded-2xl p-5 transition ${
                g.status === "completed" ? "border-yellow-400/30 shadow-lg shadow-yellow-400/5" : "border-yellow-400/15"
              }`}>
              <div className="flex items-start gap-4">
                <div className="w-24 h-24 rounded-xl overflow-hidden bg-zinc-900 border border-yellow-400/10 grid place-items-center shrink-0">
                  {g.image_url ? (
                    <img alt={g.title} src={`${BACKEND_URL}${g.image_url}${token ? `?auth=${token}` : ""}`} className="w-full h-full object-cover" />
                  ) : (
                    <Target className="w-7 h-7 text-zinc-700" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <div className={`font-display text-lg font-semibold ${g.status === "completed" ? "text-zinc-300" : "text-white"}`}>{g.title}</div>
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs ${cls}`}>
                      <Icon className="w-3 h-3" /> {label}
                    </span>
                    {ahead && (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs bg-yellow-400/15 text-yellow-300">
                        <Sparkles className="w-3 h-3" /> Ahead of deadline
                      </span>
                    )}
                  </div>
                  <div className="mt-2 flex items-center gap-2 text-xs text-zinc-500">
                    <Avatar url={g.owner?.avatar_url} name={g.owner?.name} size={20} />
                    <span className="truncate">{g.owner?.name || g.owner?.email}</span>
                  </div>
                  <div className="mt-2 flex flex-wrap items-center gap-2">
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-sky-400/15 text-sky-300">
                      <TrendingUp className="w-3 h-3" /> {PERIOD_LABEL[g.period || "weekly"]}
                    </span>
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-emerald-400/15 text-emerald-300">
                      <Percent className="w-3 h-3" /> {Number(g.allocation_percent || 0)}% alloc
                    </span>
                  </div>
                  <div className="mt-3 flex flex-wrap items-center gap-3 text-xs text-zinc-500">
                    {g.deadline && <span className="inline-flex items-center gap-1"><Calendar className="w-3 h-3" /> by {fmtDate(g.deadline)}</span>}
                    {g.product_link && (
                      <a href={g.product_link} target="_blank" rel="noreferrer"
                        className="inline-flex items-center gap-1 text-yellow-400 hover:underline truncate max-w-[220px]">
                        <ExternalLink className="w-3 h-3" /> {(() => { try { return new URL(g.product_link).hostname; } catch { return g.product_link; } })()}
                      </a>
                    )}
                  </div>

                  {/* Progress block */}
                  {(() => {
                    const target = Number(g.target_amount || 0);
                    const period = g.period || "weekly";
                    const pct = g.progress?.pct_of_target || 0;
                    const amt = g.progress?.period_amount || 0;
                    return (
                      <div className="mt-3">
                        <div className="flex items-baseline gap-2 flex-wrap">
                          <div className="font-display text-2xl font-bold tabular-nums text-yellow-400">${amt.toFixed(2)}</div>
                          {target > 0
                            ? <div className="text-sm text-zinc-400">of ${target.toFixed(2)} · <span className="text-yellow-300">{pct}%</span> this {period}</div>
                            : <div className="text-xs text-zinc-500">No target set</div>}
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
                    );
                  })()}
                </div>
              </div>

              {g.status === "completed" && g.appreciation && (
                <div className="mt-4 px-3 py-2 rounded-xl bg-yellow-400/10 border border-yellow-400/30 text-sm text-yellow-100 flex items-start gap-2">
                  <Sparkles className="w-4 h-4 text-yellow-400 mt-0.5 shrink-0" />
                  <div>{g.appreciation}</div>
                </div>
              )}

              <div className="mt-3">
                <Reactions goal={g} onChange={(u) => setGoals((gs) => gs.map((x) => x.id === u.id ? { ...x, reactions: u.reactions } : x))} />
              </div>

              <div className="mt-4 flex items-center gap-2 justify-end flex-wrap">
                <Button data-testid={`delete-goal-${g.id}`} onClick={() => openDelete(g)} variant="ghost"
                  className="text-zinc-400 hover:text-red-400 hover:bg-red-500/10 rounded-full h-9 px-3">
                  <Trash2 className="w-4 h-4 mr-1.5" /> Delete
                </Button>
                <Button data-testid={`edit-goal-${g.id}`} onClick={() => openEdit(g)} variant="ghost"
                  className="text-zinc-300 hover:text-yellow-400 rounded-full h-9 px-4 border border-yellow-400/20">
                  <Pencil className="w-4 h-4 mr-2" /> Edit goal
                </Button>
                {g.status === "open" ? (
                  <Button data-testid={`celebrate-goal-${g.id}`} onClick={() => openComplete(g)}
                    className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-9 px-4">
                    <Sparkles className="w-4 h-4 mr-2" /> Celebrate
                  </Button>
                ) : (
                  <Button data-testid={`reopen-goal-${g.id}`} onClick={() => reopen(g)} variant="ghost"
                    className="text-zinc-300 hover:text-yellow-400 rounded-full h-9 px-4 border border-yellow-400/20">
                    <RotateCcw className="w-4 h-4 mr-2" /> Reopen
                  </Button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      <Dialog open={!!dialog} onOpenChange={(o) => !o && setDialog(null)}>
        <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl" aria-describedby={undefined}>
          {dialog?.mode === "assign" ? (
            <>
              <DialogHeader>
                <DialogTitle className="font-display text-2xl flex items-center gap-2">
                  <Target className="w-5 h-5 text-yellow-400" /> Assign a new trip
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-4">
                <div className="text-sm text-zinc-400">Set a target for one of your workers — they'll get a 🔔 notification right away and the goal will show up on their dashboard.</div>
                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><UserCircle2 className="w-3 h-3" /> Worker</label>
                  <Select value={assignForm.assignee_id} onValueChange={(v) => setAssignForm({ ...assignForm, assignee_id: v })}>
                    <SelectTrigger data-testid="assign-worker" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11"><SelectValue placeholder="Pick a worker" /></SelectTrigger>
                    <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                      {workers.map(w => <SelectItem key={w.id} value={w.id} data-testid={`assign-worker-${w.id}`}>{w.name || w.email}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500">Trip title</label>
                  <Input data-testid="assign-title" value={assignForm.title}
                    onChange={(e) => setAssignForm({ ...assignForm, title: e.target.value })}
                    placeholder="e.g., Cabo for 4 nights"
                    className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><BadgeDollarSign className="w-3 h-3" /> Target amount</label>
                    <Input data-testid="assign-target" type="number" min="0" step="any" placeholder="e.g., 250"
                      value={assignForm.target_amount} onChange={(e) => setAssignForm({ ...assignForm, target_amount: e.target.value })}
                      className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                  </div>
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500">Period</label>
                    <Select value={assignForm.period} onValueChange={(v) => setAssignForm({ ...assignForm, period: v })}>
                      <SelectTrigger data-testid="assign-period" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11"><SelectValue /></SelectTrigger>
                      <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                        {PERIODS.map(p => <SelectItem key={p.value} value={p.value} data-testid={`assign-period-${p.value}`}>{p.label}</SelectItem>)}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><Percent className="w-3 h-3" /> Allocation %</label>
                    <Input data-testid="assign-allocation" type="number" min="0" max="100" step="any" placeholder="e.g., 50"
                      value={assignForm.allocation_percent} onChange={(e) => setAssignForm({ ...assignForm, allocation_percent: e.target.value })}
                      className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                  </div>
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><Calendar className="w-3 h-3" /> Deadline (optional)</label>
                    <Input data-testid="assign-deadline" type="date" value={assignForm.deadline}
                      onChange={(e) => setAssignForm({ ...assignForm, deadline: e.target.value })}
                      className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                  </div>
                </div>
                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500">Product link (optional)</label>
                  <Input data-testid="assign-link" type="url" value={assignForm.product_link}
                    onChange={(e) => setAssignForm({ ...assignForm, product_link: e.target.value })}
                    placeholder="https://…"
                    className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                </div>
              </div>
              <DialogFooter>
                <Button data-testid="confirm-assign" onClick={confirmAssign} disabled={busy}
                  className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Target className="w-4 h-4 mr-2" /> Assign goal & notify</>}
                </Button>
              </DialogFooter>
            </>
          ) : dialog?.mode === "edit" ? (
            <>
              <DialogHeader>
                <DialogTitle className="font-display text-2xl flex items-center gap-2">
                  <Pencil className="w-5 h-5 text-yellow-400" /> Edit goal settings
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-4">
                <div className="text-sm text-zinc-400">Update the photo, target, period, and what % of every task earned counts toward this goal.</div>
                {/* Image */}
                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><ImageIcon className="w-3 h-3" /> Trip photo</label>
                  <div className="mt-2 flex items-center gap-4">
                    <div className="relative w-24 h-24 rounded-xl overflow-hidden bg-zinc-900 border border-yellow-400/20 shrink-0 grid place-items-center">
                      {dialog?.goal?.image_url ? (
                        <img src={dialog.goal.image_url} alt={`Trip photo for ${dialog.goal.title || "goal"}`} className="w-full h-full object-cover" data-testid="edit-image-preview" />
                      ) : (
                        <ImageIcon className="w-7 h-7 text-zinc-700" />
                      )}
                    </div>
                    <div className="flex flex-wrap gap-2">
                      <input ref={editFileRef} type="file" accept="image/jpeg,image/png,image/webp,image/gif" className="hidden"
                        onChange={(e) => uploadGoalImage(e.target.files?.[0])} data-testid="edit-image-input" />
                      <Button data-testid="edit-image-upload-btn" type="button" onClick={onPickImage} disabled={uploadingImg}
                        className="bg-yellow-400 hover:bg-yellow-300 text-black rounded-full h-9 px-4 text-sm font-semibold">
                        {uploadingImg ? <Loader2 className="w-4 h-4 animate-spin mr-1.5" /> : <Upload className="w-4 h-4 mr-1.5" />}
                        {dialog?.goal?.image_url ? "Replace photo" : "Upload photo"}
                      </Button>
                      {dialog?.goal?.image_url && (
                        <Button data-testid="edit-image-remove-btn" type="button" onClick={removeGoalImage} disabled={uploadingImg}
                          variant="ghost" className="text-zinc-400 hover:text-red-400 hover:bg-red-500/10 rounded-full h-9 px-3 text-sm">
                          <Trash2 className="w-4 h-4 mr-1.5" /> Remove
                        </Button>
                      )}
                    </div>
                  </div>
                  <div className="text-[10px] text-zinc-500 mt-2">JPEG, PNG, WEBP, or GIF — up to 3 MB.</div>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><BadgeDollarSign className="w-3 h-3" /> Target amount</label>
                    <Input data-testid="edit-target" type="number" min="0" step="any" placeholder="e.g., 200"
                      value={editForm.target_amount} onChange={(e) => setEditForm({ ...editForm, target_amount: e.target.value })}
                      className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                  </div>
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500">Period</label>
                    <Select value={editForm.period} onValueChange={(v) => setEditForm({ ...editForm, period: v })}>
                      <SelectTrigger data-testid="edit-period" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11"><SelectValue /></SelectTrigger>
                      <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                        {PERIODS.map(p => <SelectItem key={p.value} value={p.value} data-testid={`edit-period-${p.value}`}>{p.label}</SelectItem>)}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><Percent className="w-3 h-3" /> Allocation % of task earnings</label>
                  <Input data-testid="edit-allocation" type="number" min="0" max="100" step="any" placeholder="e.g., 50"
                    value={editForm.allocation_percent} onChange={(e) => setEditForm({ ...editForm, allocation_percent: e.target.value })}
                    className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                  <div className="text-[10px] text-zinc-500 mt-1">e.g., 50% means half of every completed task's earnings is credited toward this goal.</div>
                </div>
              </div>
              <DialogFooter>
                <Button data-testid="confirm-edit" onClick={confirmEdit} disabled={busy}
                  className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : "Save settings"}
                </Button>
              </DialogFooter>
            </>
          ) : dialog?.mode === "delete" ? (
            <>
              <DialogHeader>
                <DialogTitle className="font-display text-2xl flex items-center gap-2">
                  <Trash2 className="w-5 h-5 text-red-400" /> Delete trip?
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-3">
                <div className="text-sm text-zinc-300">
                  This permanently removes <span className="font-semibold text-white">&ldquo;{dialog?.goal?.title}&rdquo;</span> and all its reactions. Completed task earnings are <span className="font-semibold">not</span> affected — payroll still counts them.
                </div>
                <div className="text-xs text-zinc-500">This cannot be undone.</div>
              </div>
              <DialogFooter className="flex gap-2 sm:gap-2">
                <Button data-testid="cancel-delete" type="button" variant="ghost"
                  onClick={() => setDialog(null)}
                  className="text-zinc-300 hover:text-white rounded-xl h-11 px-4 border border-zinc-700">
                  Cancel
                </Button>
                <Button data-testid="confirm-delete" onClick={confirmDelete} disabled={busy}
                  className="bg-red-500 hover:bg-red-400 text-white font-semibold rounded-xl h-11 flex-1">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Trash2 className="w-4 h-4 mr-2" /> Delete trip</>}
                </Button>
              </DialogFooter>
            </>
          ) : (
            <>
              <DialogHeader>
                <DialogTitle className="font-display text-2xl flex items-center gap-2">
                  <Sparkles className="w-5 h-5 text-yellow-400" /> Celebrate this goal
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-3">
                <div className="text-sm text-zinc-400">Pick a quick note or write your own — the worker will see it in a big congrats popup.</div>
                <div className="flex flex-wrap gap-2">
                  {QUICK_QUOTES.map((q) => (
                    <button
                      key={q}
                      type="button"
                      data-testid={`quote-${q.replace(/[^a-z]/gi, '').slice(0, 12)}`}
                      onClick={() => setAppreciation(q)}
                      className="text-xs px-3 py-1.5 rounded-full bg-zinc-900 border border-yellow-400/20 hover:border-yellow-400/60 hover:bg-yellow-400/10 transition"
                    >
                      {q}
                    </button>
                  ))}
                </div>
                <Textarea data-testid="appreciation-textarea" value={appreciation} onChange={(e) => setAppreciation(e.target.value)}
                  placeholder="You earned this. Proud of the hustle."
                  className="bg-zinc-900 border-zinc-800 text-white rounded-xl min-h-24" />
              </div>
              <DialogFooter>
                <Button data-testid="confirm-celebrate" onClick={confirmComplete} disabled={busy}
                  className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : "Mark complete & send appreciation"}
                </Button>
              </DialogFooter>
            </>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
