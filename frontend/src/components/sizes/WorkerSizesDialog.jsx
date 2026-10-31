import { useEffect, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Loader2, Save, ShieldCheck, Ruler } from "lucide-react";
import { toast } from "sonner";
import SizesForm, { UnitsToggle } from "@/components/sizes/SizesForm";
import LastUpdated from "@/components/sizes/LastUpdated";
import { toForm, fromForm, convertForm } from "@/lib/sizes";

export default function WorkerSizesDialog({ worker, onClose }) {
  const [doc, setDoc] = useState(null);
  const [units, setUnits] = useState("imperial");
  const [form, setForm] = useState(null);
  const [notify, setNotify] = useState(true);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!worker) return;
    setDoc(null); setForm(null); setNotify(true);
    api.get(`/workers/${worker.id}/sizes`).then(({ data }) => {
      const u = data.sizes.units || "imperial";
      setDoc(data.sizes); setUnits(u); setForm(toForm(data.sizes, u));
    }).catch((e) => { toast.error(formatApiError(e)); onClose(); });
  }, [worker, onClose]);

  const switchUnits = (u) => { setForm((f) => convertForm(f, units, u)); setUnits(u); };

  const save = async () => {
    setBusy(true);
    try {
      const { data } = await api.put(`/workers/${worker.id}/sizes`, { fit: form.fit, values: fromForm(form, units), notify });
      const n = data.changes.length;
      if (!n) toast.message("No changes to save");
      else toast.success(`${n} size${n === 1 ? "" : "s"} updated`, { description: data.notified ? `${worker.name} has been notified.` : "Saved quietly — worker not notified." });
      onClose();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  return (
    <Dialog open={!!worker} onOpenChange={(o) => { if (!o) onClose(); }}>
      <DialogContent className="bg-[#09090B] border-yellow-400/20 text-white rounded-2xl max-w-3xl max-h-[92vh] overflow-y-auto p-0" aria-describedby={undefined} data-testid="worker-sizes-dialog">
        <DialogHeader className="px-5 pt-5 pb-3 sticky top-0 z-10 bg-[#09090B]/95 backdrop-blur border-b border-yellow-400/10">
          <div className="flex flex-wrap items-center gap-3">
            <DialogTitle className="font-display text-2xl flex items-center gap-2"><Ruler className="w-5 h-5 text-yellow-400" /> {worker?.name}&apos;s sizes</DialogTitle>
            <span data-testid="editing-as-admin" className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-pink-400/15 text-pink-300 border border-pink-400/30">
              <ShieldCheck className="w-3 h-3" /> Editing as admin
            </span>
            <div className="ml-auto"><UnitsToggle units={units} onChange={switchUnits} /></div>
          </div>
          {doc && <div className="mt-2"><LastUpdated doc={doc} selfId={worker?.id} /></div>}
        </DialogHeader>
        <div className="px-5 pb-5">
          {!form ? (
            <div className="text-zinc-500 flex items-center gap-2 py-8"><Loader2 className="w-4 h-4 animate-spin" /> Loading…</div>
          ) : (
            <SizesForm form={form} setForm={setForm} units={units} />
          )}
        </div>
        <div className="sticky bottom-0 px-5 py-3 bg-[#09090B]/95 backdrop-blur border-t border-yellow-400/10 flex items-center gap-4">
          <label className="flex items-center gap-2 text-sm text-zinc-300 cursor-pointer" data-testid="notify-worker-label">
            <Switch checked={notify} onCheckedChange={setNotify} data-testid="notify-worker-switch" className="data-[state=checked]:bg-yellow-400 data-[state=unchecked]:bg-zinc-700" />
            Notify {worker?.name?.split(" ")[0]}
          </label>
          <Button data-testid="worker-sizes-save-btn" onClick={save} disabled={busy || !form} className="ml-auto h-11 bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl px-6">
            {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Save className="w-4 h-4 mr-2" /> Save</>}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
