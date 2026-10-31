import { useEffect, useState, useCallback } from "react";
import { useSearchParams } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import api, { formatApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Ruler, Save, Loader2, Eraser, Eye, Lock } from "lucide-react";
import { toast } from "sonner";
import SizesForm, { UnitsToggle } from "@/components/sizes/SizesForm";
import LastUpdated from "@/components/sizes/LastUpdated";
import { toForm, fromForm, convertForm } from "@/lib/sizes";

export default function MySizes() {
  const { user } = useAuth();
  const [params, setParams] = useSearchParams();
  const [doc, setDoc] = useState(null);
  const [units, setUnits] = useState("imperial");
  const [form, setForm] = useState(null);
  const [busy, setBusy] = useState(false);
  const [highlight, setHighlight] = useState(() => (params.get("changed") || "").split(",").filter(Boolean));

  const apply = useCallback((d) => { setDoc(d); setUnits(d.units || "imperial"); setForm(toForm(d, d.units || "imperial")); }, []);

  useEffect(() => {
    api.get("/sizes/me").then(({ data }) => apply(data)).catch((e) => toast.error(formatApiError(e)));
  }, [apply]);

  useEffect(() => {
    if (!highlight.length) return;
    const t = setTimeout(() => { setHighlight([]); setParams({}, { replace: true }); }, 6000);
    return () => clearTimeout(t);
  }, [highlight, setParams]);

  const switchUnits = (u) => { setForm((f) => convertForm(f, units, u)); setUnits(u); };

  const save = async () => {
    setBusy(true);
    try {
      const { data } = await api.put("/sizes/me", { fit: form.fit, units, values: fromForm(form) });
      apply(data.sizes);
      toast.success(data.changes.length ? "Sizes saved" : "Saved — nothing changed");
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const clearAll = async () => {
    if (!window.confirm("Clear every size you've entered? This can't be undone.")) return;
    setBusy(true);
    try { const { data } = await api.delete("/sizes/me"); apply(data); toast.success("All sizes cleared"); }
    catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  if (!form) return <div className="text-zinc-500 flex items-center gap-2"><Loader2 className="w-4 h-4 animate-spin" /> Loading your sizes…</div>;
  const isAdmin = user?.role === "admin";

  return (
    <div className="space-y-6 pb-28 sm:pb-8" data-testid="my-sizes-page">
      <div className="flex items-end justify-between gap-4 flex-wrap">
        <div>
          <div className="text-xs uppercase tracking-widest text-yellow-400 inline-flex items-center gap-1.5"><Ruler className="w-3.5 h-3.5" /> My Sizes</div>
          <h1 className="font-display text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight mt-2">Gear that fits.</h1>
          <p className="mt-2 text-zinc-400 max-w-xl">Record your measurements and sizes once — they follow you to every phone or computer you sign in on.</p>
        </div>
        <UnitsToggle units={units} onChange={switchUnits} />
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <LastUpdated doc={doc} selfId={user?.id} />
        <div className="text-xs text-zinc-500 inline-flex items-center gap-1.5" data-testid="visibility-note">
          {isAdmin ? <><Lock className="w-3.5 h-3.5" /> Only you can see your own sizes.</> : <><Eye className="w-3.5 h-3.5" /> Your admin can see and update these to order your gear.</>}
        </div>
      </div>

      <SizesForm form={form} setForm={setForm} units={units} highlight={highlight} />

      <div className="fixed sm:static inset-x-0 bottom-0 z-30 sm:z-auto bg-black/85 sm:bg-transparent backdrop-blur-xl sm:backdrop-blur-none border-t border-yellow-400/10 sm:border-0 px-4 sm:px-0 py-3 sm:py-0 flex items-center gap-3"
        style={{ paddingBottom: "max(0.75rem, env(safe-area-inset-bottom))" }}>
        <Button data-testid="sizes-save-btn" onClick={save} disabled={busy} className="h-12 flex-1 sm:flex-none bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl px-6">
          {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Save className="w-4 h-4 mr-2" /> Save sizes</>}
        </Button>
        <Button data-testid="sizes-clear-btn" variant="ghost" onClick={clearAll} disabled={busy || !doc?.id}
          className="h-12 rounded-xl text-zinc-400 hover:text-red-400 border border-zinc-800 px-4">
          <Eraser className="w-4 h-4 mr-2" /> Clear all
        </Button>
      </div>
    </div>
  );
}
