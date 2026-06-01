import { useEffect, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import Avatar from "@/components/Avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from "@/components/ui/dialog";
import { Plus, Trash2, UserPlus, Mail, BadgeCheck, Loader2 } from "lucide-react";
import { toast } from "sonner";

export default function AdminWorkers() {
  const [workers, setWorkers] = useState([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ name: "", email: "", password: "" });
  const [busy, setBusy] = useState(false);

  const load = async () => {
    const { data } = await api.get("/workers");
    setWorkers(data);
  };
  useEffect(() => { load(); }, []);

  const create = async (e) => {
    e.preventDefault();
    setBusy(true);
    try {
      await api.post("/workers", form);
      toast.success("Worker invited", { description: `${form.name} can now sign in.` });
      setForm({ name: "", email: "", password: "" });
      setOpen(false);
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const remove = async (w) => {
    if (!window.confirm(`Remove ${w.name}? This also deletes their tasks and time entries.`)) return;
    try {
      await api.delete(`/workers/${w.id}`);
      toast.success("Worker removed");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  };

  return (
    <div className="space-y-8">
      <div className="flex items-end justify-between gap-4 flex-wrap">
        <div>
          <div className="text-xs uppercase tracking-widest text-yellow-400">Crew</div>
          <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">Your workers.</h1>
          <p className="mt-2 text-zinc-400">Invite a teammate, hand them a password, and you're paying them by sundown.</p>
        </div>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button data-testid="open-create-worker" className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-11 px-5">
              <UserPlus className="w-4 h-4 mr-2" /> New worker
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl">
            <DialogHeader>
              <DialogTitle className="font-display text-2xl">Invite a worker</DialogTitle>
            </DialogHeader>
            <form onSubmit={create} className="space-y-4">
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Full name</label>
                <Input data-testid="worker-name" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Email</label>
                <Input data-testid="worker-email" required type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
              </div>
              <div>
                <label className="text-xs uppercase tracking-widest text-zinc-500">Temporary password</label>
                <Input data-testid="worker-password" required minLength={6} type="text" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })}
                  className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                <div className="text-xs text-zinc-500 mt-1">They'll use this to log in. Share it securely.</div>
              </div>
              <DialogFooter>
                <Button data-testid="submit-create-worker" type="submit" disabled={busy} className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Plus className="w-4 h-4 mr-2" /> Create worker</>}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {workers.length === 0 && (
          <div className="col-span-full text-center bg-[#121214] border border-yellow-400/15 rounded-2xl p-10">
            <BadgeCheck className="w-8 h-8 text-yellow-400 mx-auto" />
            <div className="mt-3 font-display text-xl">No workers yet</div>
            <div className="text-sm text-zinc-500">Click "New worker" to invite your first teammate.</div>
          </div>
        )}
        {workers.map((w) => (
          <div key={w.id} data-testid={`worker-card-${w.id}`} className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-5 hover:-translate-y-0.5 hover:shadow-lg hover:shadow-yellow-400/5 transition">
            <div className="flex items-start gap-3">
              <Avatar url={w.avatar_url} name={w.name || w.email} size={44} />
              <div className="flex-1 min-w-0">
                <div className="font-medium truncate">{w.name}</div>
                <div className="text-xs text-zinc-500 flex items-center gap-1 truncate"><Mail className="w-3 h-3" /> {w.email}</div>
              </div>
              <button data-testid={`delete-worker-${w.id}`} onClick={() => remove(w)} className="text-zinc-500 hover:text-red-400 transition">
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
