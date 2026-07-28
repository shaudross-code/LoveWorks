import { useEffect, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Megaphone, Sparkles, Wrench, Bell, Plus, Trash2, Loader2, Pencil } from "lucide-react";
import { toast } from "sonner";

const TAGS = [
  { value: "feature",      label: "New feature", Icon: Sparkles, cls: "bg-yellow-400/15 text-yellow-300" },
  { value: "update",       label: "Update",      Icon: Bell,     cls: "bg-sky-400/15 text-sky-300" },
  { value: "maintenance",  label: "Maintenance", Icon: Wrench,   cls: "bg-orange-400/15 text-orange-300" },
  { value: "announcement", label: "Heads-up",    Icon: Megaphone,cls: "bg-emerald-400/15 text-emerald-300" },
];
const TAG_MAP = Object.fromEntries(TAGS.map(t => [t.value, t]));

export default function Announcements() {
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";
  const [items, setItems] = useState([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null); // announcement being edited
  const [form, setForm] = useState({ title: "", body: "", tag: "feature" });
  const [busy, setBusy] = useState(false);

  const load = async () => {
    try { const { data } = await api.get("/announcements"); setItems(data); }
    catch (e) { toast.error(formatApiError(e)); }
  };
  useEffect(() => { load(); }, []);

  const submit = async (e) => {
    e.preventDefault();
    if (!form.title.trim() || !form.body.trim()) { toast.error("Title and body are required"); return; }
    setBusy(true);
    try {
      if (editing) {
        await api.patch(`/announcements/${editing.id}`, form);
        toast.success("Announcement updated");
      } else {
        await api.post("/announcements", form);
        toast.success("Announcement posted — workers notified");
      }
      setForm({ title: "", body: "", tag: "feature" });
      setEditing(null);
      setOpen(false);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const openCreate = () => {
    setEditing(null);
    setForm({ title: "", body: "", tag: "feature" });
    setOpen(true);
  };

  const openEdit = (a) => {
    setEditing(a);
    setForm({ title: a.title, body: a.body, tag: a.tag || "update" });
    setOpen(true);
  };

  const remove = async (a) => {
    if (!window.confirm(`Delete "${a.title}"?`)) return;
    try { await api.delete(`/announcements/${a.id}`); toast.success("Deleted"); load(); }
    catch (e) { toast.error(formatApiError(e)); }
  };

  return (
    <div className="space-y-8">
      <div className="flex items-end justify-between gap-4 flex-wrap">
        <div>
          <div className="text-xs uppercase tracking-widest text-yellow-400">Announcements</div>
          <h1 className="font-display text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight mt-2">What's new.</h1>
          <p className="mt-2 text-zinc-400">{isAdmin ? "Post an update — every worker gets a notification." : "Updates, new features, and heads-ups from your admin."}</p>
        </div>
        {isAdmin && (
          <Button data-testid="open-create-announcement" onClick={openCreate}
            className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-11 px-5">
            <Plus className="w-4 h-4 mr-2" /> New post
          </Button>
        )}
      </div>

      <div className="space-y-4">
        {items.length === 0 && (
          <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-10 text-center">
            <Megaphone className="w-7 h-7 text-yellow-400 mx-auto" />
            <div className="mt-3 font-display text-xl">No announcements yet</div>
            <div className="text-sm text-zinc-500">{isAdmin ? "Post your first update." : "Check back soon."}</div>
          </div>
        )}
        {items.map((a) => {
          const tag = TAG_MAP[a.tag] || TAG_MAP.update;
          return (
            <div key={a.id} data-testid={`announcement-${a.id}`}
              className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-6 hover:-translate-y-0.5 transition">
              <div className="flex items-start gap-3">
                <div className={`w-11 h-11 rounded-xl grid place-items-center ${tag.cls}`}>
                  <tag.Icon className="w-5 h-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <div className="font-display text-xl font-semibold">{a.title}</div>
                    <span className={`px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest ${tag.cls}`}>{tag.label}</span>
                  </div>
                  <div className="text-xs text-zinc-500 mt-1">
                    {new Date(a.created_at).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" })}
                    {a.edited_at && <span className="text-zinc-600"> · edited</span>}
                  </div>
                  <div className="mt-3 text-zinc-200 whitespace-pre-wrap break-words leading-relaxed">{a.body}</div>
                </div>
                {isAdmin && (
                  <div className="flex items-center gap-2">
                    <button data-testid={`edit-announcement-${a.id}`} onClick={() => openEdit(a)}
                      className="text-zinc-500 hover:text-yellow-300 transition" aria-label="Edit announcement">
                      <Pencil className="w-4 h-4" />
                    </button>
                    <button data-testid={`delete-announcement-${a.id}`} onClick={() => remove(a)}
                      className="text-zinc-500 hover:text-red-400 transition" aria-label="Delete announcement">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {isAdmin && (
        <Dialog open={open} onOpenChange={(o) => { setOpen(o); if (!o) setEditing(null); }}>
          <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl" aria-describedby={undefined}>
            <DialogHeader><DialogTitle className="font-display text-2xl">{editing ? "Edit announcement" : "New announcement"}</DialogTitle></DialogHeader>
            <form onSubmit={submit} className="space-y-4">
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Type</label>
                <Select value={form.tag} onValueChange={(v) => setForm({ ...form, tag: v })}>
                  <SelectTrigger data-testid="ann-tag" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                    {TAGS.map(t => (
                      <SelectItem key={t.value} value={t.value} data-testid={`ann-tag-${t.value}`}>{t.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Title</label>
                <Input data-testid="ann-title" required maxLength={140} value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Message</label>
                <Textarea data-testid="ann-body" required maxLength={4000} value={form.body}
                  onChange={(e) => setForm({ ...form, body: e.target.value })}
                  placeholder="What should your crew know?"
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl min-h-32" />
              </div>
              <DialogFooter>
                <Button data-testid="submit-announcement" type="submit" disabled={busy}
                  className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : "Post & notify workers"}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
}
