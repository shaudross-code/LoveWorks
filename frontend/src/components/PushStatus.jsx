import { useCallback, useEffect, useState } from "react";
import { BellRing, Loader2, Share, Smartphone, CheckCircle2, XCircle, CircleDashed } from "lucide-react";
import { toast } from "sonner";
import { enablePush, isPushSupported, pushPermission, isIOS, isStandalone, needsHomeScreenInstall, currentSubscription, sendTestPush } from "@/lib/push";
import { isNative } from "@/lib/nativePush";
import { PushSettings } from "@/components/PushPrompt";

function Row({ label, value, ok, testid }) {
  const Icon = ok === true ? CheckCircle2 : ok === false ? XCircle : CircleDashed;
  const tone = ok === true ? "text-green-400" : ok === false ? "text-red-400" : "text-zinc-500";
  return (
    <div className="flex items-center justify-between gap-3 py-1.5 text-sm">
      <span className="text-zinc-400">{label}</span>
      <span data-testid={testid} className={`inline-flex items-center gap-1.5 ${tone}`}><Icon className="w-4 h-4" />{value}</span>
    </div>
  );
}

function InstallSteps() {
  return (
    <div data-testid="ios-install-steps" className="mt-3 rounded-xl border border-yellow-400/25 bg-yellow-400/[0.06] p-3 text-sm text-zinc-200">
      <div className="font-semibold text-white flex items-center gap-2"><Smartphone className="w-4 h-4 text-yellow-400" /> Add iLoveWorks to your Home Screen</div>
      <ol className="mt-2 space-y-1 list-decimal list-inside text-zinc-300">
        <li>Tap the <Share className="inline w-3.5 h-3.5 -mt-0.5" /> Share button in Safari.</li>
        <li>Choose <b>Add to Home Screen</b>, then <b>Add</b>.</li>
        <li>Open iLoveWorks from the new icon and come back here to turn alerts on.</li>
      </ol>
      <div className="mt-2 text-xs text-zinc-500">iPhone only delivers web alerts to apps opened from the Home Screen, never to a Safari tab.</div>
    </div>
  );
}

export default function PushStatus() {
  const [perm, setPerm] = useState(pushPermission());
  const [subscribed, setSubscribed] = useState(null);
  const [busy, setBusy] = useState(false);
  const refresh = useCallback(async () => {
    setPerm(pushPermission());
    setSubscribed(!!(await currentSubscription().catch(() => null)));
  }, []);
  useEffect(() => { if (!isNative()) refresh(); }, [refresh]);

  const run = (fn, ok) => async () => {
    setBusy(true);
    try { await fn(); toast.success(ok); } catch (e) { toast.error(e.message || "Something went wrong"); }
    finally { setBusy(false); refresh(); }
  };

  if (isNative()) return <PushSettings />;
  const installNeeded = needsHomeScreenInstall();
  const where = isIOS() ? (isStandalone() ? "Home Screen app" : "Safari tab") : (isStandalone() ? "Installed app" : "Browser tab");
  const permLabel = { granted: "Allowed", denied: "Blocked", default: "Not asked yet", unsupported: "Not available here" }[perm];

  return (
    <div data-testid="push-status" className="rounded-2xl border border-yellow-400/15 bg-[#0d0d0f] p-4">
      <div className="text-xs uppercase tracking-widest text-zinc-500 mb-1">Why an alert would or wouldn&apos;t fire</div>
      <Row label="Opened as" value={where} ok={installNeeded ? false : true} testid="push-status-install" />
      <Row label="Notification permission" value={permLabel} ok={perm === "granted" ? true : perm === "default" ? null : false} testid="push-status-permission" />
      <Row label="This device signed up for alerts" value={subscribed ? "Yes" : "No"} ok={subscribed ? true : installNeeded ? null : false} testid="push-status-subscribed" />
      {installNeeded && <InstallSteps />}
      {perm === "denied" && (
        <div className="mt-2 text-xs text-red-300">Notifications are blocked. Turn them back on in your phone or browser settings for iLoveWorks.</div>
      )}
      {!installNeeded && isPushSupported() && perm !== "denied" && (
        <div className="mt-3 flex flex-wrap gap-2">
          {!subscribed && (
            <button data-testid="push-status-enable" disabled={busy} onClick={run(enablePush, "Alerts are on for this device.")}
              className="inline-flex items-center gap-2 bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full px-4 h-9 text-sm transition-colors disabled:opacity-60">
              {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <BellRing className="w-4 h-4" />} Turn on alerts
            </button>
          )}
          {subscribed && (
            <button data-testid="push-status-test" disabled={busy} onClick={run(sendTestPush, "Test alert sent — it should appear in a few seconds.")}
              className="inline-flex items-center gap-2 border border-yellow-400/30 text-yellow-300 hover:bg-yellow-400/10 rounded-full px-4 h-9 text-sm transition-colors disabled:opacity-60">
              {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <BellRing className="w-4 h-4" />} Send test alert
            </button>
          )}
        </div>
      )}
    </div>
  );
}
