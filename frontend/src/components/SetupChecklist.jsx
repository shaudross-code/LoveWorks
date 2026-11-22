import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { BellRing, Watch, Scale, CheckCircle2, Circle, Loader2, X, Smartphone } from "lucide-react";
import { toast } from "sonner";
import { useAuth } from "@/context/AuthContext";
import { enablePush, isPushSupported, pushPermission, currentSubscription, needsHomeScreenInstall, registerServiceWorker } from "@/lib/push";
import { getMyHealth } from "@/lib/health";

// Bump when a new feature needs workers to turn something on; everyone sees the checklist again.
const SETUP_VERSION = "2026-11-watch-scale";
const SNOOZE_DAYS = 7;

function Item({ done, icon: Icon, title, detail, action, testid }) {
  return (
    <li data-testid={testid} className="flex items-start gap-3 py-3">
      {done ? <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" /> : <Circle className="w-5 h-5 text-zinc-600 shrink-0 mt-0.5" />}
      <div className="flex-1 min-w-0">
        <div className={`font-medium flex items-center gap-2 ${done ? "text-zinc-400 line-through decoration-zinc-600" : "text-white"}`}><Icon className="w-4 h-4 text-yellow-400" /> {title}</div>
        {!done && <div className="text-xs text-zinc-400 mt-0.5">{detail}</div>}
      </div>
      {!done && action}
    </li>
  );
}

export default function SetupChecklist() {
  const { user } = useAuth();
  const key = `setupChecklist:${SETUP_VERSION}:${user?.id}`;
  const [hiddenUntil, setHiddenUntil] = useState(() => Number(localStorage.getItem(key) || 0));
  const [alerts, setAlerts] = useState(null);
  const [health, setHealth] = useState(null);
  const [busy, setBusy] = useState(false);

  const refresh = useCallback(async () => {
    const sub = await currentSubscription().catch(() => null);
    setAlerts({ perm: pushPermission(), subscribed: !!sub });
    const h = await getMyHealth().catch(() => null);
    const days = h?.days || [];
    setHealth({
      watch: days.some((d) => (d.active_kcal || 0) > 0 || (d.total_kcal || 0) > 0),
      scale: days.some((d) => d.weight_kg != null),
    });
  }, []);
  useEffect(() => { registerServiceWorker(); refresh(); }, [refresh]);

  const turnOnAlerts = async () => {
    setBusy(true);
    try { await enablePush(); toast.success("Alerts are on. You'll hear about new features, alarms and tasks."); }
    catch (e) { toast.error(e.message || "Couldn't turn on alerts"); }
    finally { setBusy(false); refresh(); }
  };
  const snooze = () => {
    const until = Date.now() + SNOOZE_DAYS * 864e5;
    localStorage.setItem(key, String(until));
    setHiddenUntil(until);
  };

  if (!alerts || !health || hiddenUntil > Date.now()) return null;
  const alertsDone = alerts.perm === "granted" && alerts.subscribed;
  if (alertsDone && health.watch && health.scale) return null;
  const remaining = [alertsDone, health.watch, health.scale].filter((d) => !d).length;

  const alertAction = needsHomeScreenInstall() ? null : alerts.perm === "denied" || !isPushSupported() ? null : (
    <button data-testid="setup-enable-alerts" onClick={turnOnAlerts} disabled={busy}
      className="shrink-0 inline-flex items-center gap-2 h-8 px-3 rounded-full text-xs font-semibold bg-yellow-400 text-black hover:bg-yellow-300 transition-colors disabled:opacity-60">
      {busy ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <BellRing className="w-3.5 h-3.5" />} Turn on
    </button>
  );
  const alertDetail = needsHomeScreenInstall()
    ? "On iPhone: tap Share → Add to Home Screen, then open iLoveWorks from the new icon to turn alerts on."
    : alerts.perm === "denied" ? "Alerts are blocked. Allow notifications for iLoveWorks in your browser or phone settings."
    : !isPushSupported() ? "This browser can't show alerts. Try Chrome, Edge or the iPhone Home Screen app."
    : "Get alerts for new features, alarms, task reminders and announcements, even when iLoveWorks is closed.";
  const guide = (
    <Link to="/worker/apple-watch" data-testid="setup-open-guide" className="shrink-0 inline-flex items-center gap-1 h-8 px-3 rounded-full text-xs border border-yellow-400/30 text-yellow-300 hover:bg-yellow-400/10 transition-colors">
      <Smartphone className="w-3.5 h-3.5" /> How to
    </Link>
  );

  return (
    <section data-testid="setup-checklist" className="relative rounded-2xl border border-yellow-400/30 bg-gradient-to-br from-yellow-400/[0.08] via-[#121214] to-[#121214] px-5 py-4">
      <button data-testid="setup-snooze" onClick={snooze} aria-label="Remind me later"
        className="absolute top-3 right-3 w-7 h-7 rounded-full grid place-items-center text-zinc-500 hover:text-white hover:bg-white/5 transition-colors"><X className="w-4 h-4" /></button>
      <div className="font-display font-semibold text-white">Finish setting up iLoveWorks</div>
      <div className="text-sm text-zinc-400 mt-0.5">{remaining} step{remaining === 1 ? "" : "s"} left. Each one is optional and you can turn it off later.</div>
      <ul className="mt-2 divide-y divide-white/5">
        <Item testid="setup-item-alerts" done={alertsDone} icon={BellRing} title="Alerts on this device" detail={alertDetail} action={alertAction} />
        <Item testid="setup-item-watch" done={health.watch} icon={Watch} title="Apple Watch & Apple Health"
          detail="In the iLoveWorks iPhone app: Profile → Apple Watch, Scale & Health. Allow Apple Health and install the Watch app." action={guide} />
        <Item testid="setup-item-scale" done={health.scale} icon={Scale} title="Smart scale over Bluetooth"
          detail="In the iPhone app tap Weigh in with Bluetooth and allow Bluetooth when asked. Or connect VeSync to Apple Health." action={guide} />
      </ul>
    </section>
  );
}
