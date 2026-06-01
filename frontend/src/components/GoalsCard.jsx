import { useEffect, useRef, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from "@/components/ui/dialog";
import { Target, Plus, Image as ImageIcon, Link as LinkIcon, Calendar, Loader2, Trash2, Sparkles, CheckCircle2, Clock, AlertTriangle, ExternalLink } from "lucide-react";
import { toast } from "sonner";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;

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

export default function GoalsCard() {
  const [goals, setGoals] = useState([]);
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState({ title: "", product_link: "", deadline: "" });
  const [file, setFile] = useState(null);
  const fileRef = useRef(null);

  const load = async () => {
    const { data } = await api.get("/goals");
    setGoals(data);
  };
  useEffect(() => { load(); }, []);

  const submit = async (e) => {
    e.preventDefault();
    if (!form.title.trim()) { toast.error("Add a title for your goal"); return; }
    setBusy(true);
    try {
      const params = new URLSearchParams();
      params.set("title", form.title.trim());
      if (form.product_link.trim()) params.set("product_link", form.product_link.trim());
      if (form.deadline) params.set("deadline", form.deadline);
      const fd = new FormData();
      if (file) fd.append("file", file);
      await api.post(`/goals?${params.toString()}`, fd, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      toast.success("Goal added");
      setForm({ title: "", product_link: "", deadline: "" });
      setFile(null);
      setOpen(false);
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
            <p className="text-xs text-zinc-500 mt-0.5">Things you're working toward — drop a pic, a product link, set a deadline.</p>
          </div>
        </div>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button data-testid="open-create-goal" className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-10 px-4">
              <Plus className="w-4 h-4 mr-2" /> New goal
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl" aria-describedby={undefined}>
            <DialogHeader><DialogTitle className="font-display text-2xl">Add a goal</DialogTitle></DialogHeader>
            <form onSubmit={submit} className="space-y-4">
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">What do you want?</label>
                <Input data-testid="goal-title" required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })}
                  placeholder="e.g., New steel-toe boots" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1"><LinkIcon className="w-3 h-3" /> Product link (optional)</label>
                <Input data-testid="goal-link" type="url" value={form.product_link} onChange={(e) => setForm({ ...form, product_link: e.target.value })}
                  placeholder="https://..." className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1"><Calendar className="w-3 h-3" /> Deadline (optional)</label>
                <Input data-testid="goal-deadline" type="date" value={form.deadline} onChange={(e) => setForm({ ...form, deadline: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11 [color-scheme:dark]" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Photo (optional)</label>
                <input ref={fileRef} type="file" accept="image/png,image/jpeg,image/webp,image/gif" data-testid="goal-file-input" onChange={onFileChange} className="hidden" />
                <button type="button" data-testid="goal-pick-image" onClick={pickFile}
                  className="mt-2 w-full h-11 rounded-xl bg-zinc-900 border border-dashed border-yellow-400/30 hover:border-yellow-400/60 text-zinc-300 flex items-center justify-center gap-2 transition">
                  <ImageIcon className="w-4 h-4" /> {file ? file.name : "Tap to add a picture"}
                </button>
              </div>
              <DialogFooter>
                <Button data-testid="submit-create-goal" type="submit" disabled={busy}
                  className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : "Save goal"}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl divide-y divide-yellow-400/5">
        {goals.length === 0 && (
          <div className="p-10 text-center">
            <Target className="w-7 h-7 text-yellow-400 mx-auto" />
            <div className="mt-3 font-display text-xl">No goals yet</div>
            <div className="text-sm text-zinc-500">Hit "New goal" to drop a product you're saving up for or a milestone you want to hit.</div>
          </div>
        )}
        {goals.map((g) => {
          const status = getStatus(g);
          const StatusIcon = status.icon;
          return (
            <div key={g.id} data-testid={`worker-goal-${g.id}`}
              className={`p-4 sm:p-5 flex gap-4 ${g.status === "completed" ? "bg-yellow-400/[0.03]" : ""}`}>
              <div className="shrink-0 w-20 h-20 sm:w-24 sm:h-24 rounded-xl overflow-hidden bg-zinc-900 border border-yellow-400/10 grid place-items-center">
                {g.image_url ? (
                  <img alt={g.title} src={`${BACKEND_URL}${g.image_url}${token ? `?auth=${token}` : ""}`} className="w-full h-full object-cover" />
                ) : (
                  <Target className="w-7 h-7 text-zinc-700" />
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <div className={`font-medium ${g.status === "completed" ? "line-through text-zinc-500" : ""}`}>{g.title}</div>
                  <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs ${status.className}`}>
                    <StatusIcon className="w-3 h-3" /> {status.label}
                  </span>
                </div>
                <div className="mt-1 flex flex-wrap items-center gap-3 text-xs text-zinc-500">
                  {g.deadline && (
                    <span className="inline-flex items-center gap-1"><Calendar className="w-3 h-3" /> by {fmtDate(g.deadline)}</span>
                  )}
                  {g.product_link && (
                    <a href={g.product_link} target="_blank" rel="noreferrer" data-testid={`goal-link-${g.id}`}
                      className="inline-flex items-center gap-1 text-yellow-400 hover:underline truncate max-w-[260px]">
                      <ExternalLink className="w-3 h-3" /> {new URL(g.product_link).hostname}
                    </a>
                  )}
                </div>
                {g.status === "completed" && g.appreciation && (
                  <div data-testid={`goal-appreciation-${g.id}`}
                    className="mt-3 px-3 py-2 rounded-xl bg-yellow-400/10 border border-yellow-400/30 text-sm text-yellow-100 flex items-start gap-2">
                    <Sparkles className="w-4 h-4 text-yellow-400 mt-0.5 shrink-0" />
                    <div><span className="text-yellow-400 font-semibold">From your admin:</span> {g.appreciation}</div>
                  </div>
                )}
              </div>
              <button data-testid={`delete-goal-${g.id}`} onClick={() => remove(g)}
                className="self-start text-zinc-500 hover:text-red-400 transition">
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          );
        })}
      </div>
    </section>
  );
}
