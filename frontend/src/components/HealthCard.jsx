import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Flame, Scale, Watch, ChevronRight, Users } from "lucide-react";
import { toast } from "sonner";
import { Switch } from "@/components/ui/switch";
import { formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { getMyHealth, setHealthSharing, kgToLb, fmtKcal, timeAgo, sourceLabel, weightSourceLabel } from "@/lib/health";

function Stat({ label, value, unit, tone, testid }) {
  return (
    <div className="rounded-xl bg-white/[0.03] border border-white/5 px-4 py-3">
      <div className="text-[10px] uppercase tracking-widest text-zinc-500">{label}</div>
      <div data-testid={testid} className={`mt-1 font-display text-2xl font-semibold ${tone}`}>
        {value}<span className="text-xs text-zinc-500 font-normal ml-1">{unit}</span>
      </div>
    </div>
  );
}

function ShareNotice({ userId }) {
  const key = `healthShareNotice:${userId}`;
  const [seen, setSeen] = useState(() => localStorage.getItem(key) === "1");
  if (seen) return null;
  return (
    <div data-testid="health-share-notice" className="mt-4 flex items-start gap-3 rounded-xl border border-yellow-400/20 bg-yellow-400/[0.06] px-4 py-3 text-sm">
      <Users className="w-4 h-4 mt-0.5 text-yellow-300 shrink-0" />
      <div className="flex-1">
        <div className="font-semibold text-zinc-100">Your admin can see your calories and weight</div>
        <div className="text-xs text-zinc-400 mt-0.5">Sharing is on by default. Turn it off any time with the switch below.</div>
      </div>
      <button data-testid="health-share-notice-ok" onClick={() => { localStorage.setItem(key, "1"); setSeen(true); }}
        className="text-xs font-semibold text-yellow-300 hover:text-yellow-200 transition-colors">Got it</button>
    </div>
  );
}

export default function HealthCard({ guidePath = "/worker/apple-watch" }) {
  const { user } = useAuth();
  const [data, setData] = useState(null);
  const load = useCallback(() => getMyHealth().then(setData).catch(() => {}), []);
  useEffect(() => {
    load();
    const id = setInterval(load, 60000);
    return () => clearInterval(id);
  }, [load]);

  const toggleShare = async (share) => {
    try { await setHealthSharing(share); setData((d) => ({ ...d, share_with_admin: share })); toast.success(share ? "Sharing with your admin" : "Sharing turned off"); }
    catch (e) { toast.error(formatApiError(e)); }
  };

  const days = data?.days || [];
  const today = days[0];
  const weight = days.find((d) => d.weight_kg != null);

  return (
    <section data-testid="health-card" className="rounded-2xl border border-pink-400/15 bg-[#121214] p-5 sm:p-6">
      <div className="flex items-center justify-between gap-3">
        <h2 className="font-display font-semibold text-base md:text-lg flex items-center gap-2"><Watch className="w-5 h-5 text-pink-400" /> Apple Watch &amp; scale</h2>
        <Link to={guidePath} data-testid="health-guide-link" className="text-xs text-yellow-300 hover:text-yellow-200 inline-flex items-center gap-0.5">How to connect <ChevronRight className="w-3.5 h-3.5" /></Link>
      </div>
      {today ? (
        <>
          <div className="mt-4 grid grid-cols-2 sm:grid-cols-3 gap-3">
            <Stat label="Active calories" value={fmtKcal(today.active_kcal)} unit="kcal" tone="text-pink-300" testid="health-active-kcal" />
            <Stat label="Total calories" value={fmtKcal(today.total_kcal)} unit="kcal" tone="text-white" testid="health-total-kcal" />
            {weight && <Stat label="Weight" value={kgToLb(weight.weight_kg)} unit="lb" tone="text-sky-300" testid="health-weight" />}
          </div>
          <div data-testid="health-updated" className="mt-2 text-xs text-zinc-500 flex items-center gap-1.5">
            <Flame className="w-3.5 h-3.5 text-pink-400" /> {today.date} · updated {timeAgo(today.updated_at)} {sourceLabel(today.source)}
            {weight && <span data-testid="health-weight-source" className="ml-2 inline-flex items-center gap-1"><Scale className="w-3.5 h-3.5 text-sky-400" />weight {weightSourceLabel(weight.weight_source)}{weight.body_fat_pct != null && ` · ${weight.body_fat_pct}% body fat`}</span>}
          </div>
        </>
      ) : (
        <div data-testid="health-empty" className="mt-3 text-sm text-zinc-400">
          No numbers yet. Open the iLoveWorks iPhone app and tap <b>Profile → Apple Watch, Scale &amp; Health</b>. Calories and weight can only be read on the iPhone.
        </div>
      )}
      {data?.share_with_admin && user?.id && <ShareNotice userId={user.id} />}
      <label className="mt-4 flex items-center justify-between gap-3 text-sm">
        <span className="text-zinc-300">Share my calories and weight with my admin <span className="block text-xs text-zinc-500">On by default. Turn it off any time.</span></span>
        <Switch data-testid="health-share-switch" checked={!!data?.share_with_admin} onCheckedChange={toggleShare} />
      </label>
    </section>
  );
}
