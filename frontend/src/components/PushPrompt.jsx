import { useEffect, useState, useCallback } from "react";
import { BellRing, BellOff, X, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { enablePush, disablePush, isPushSupported, pushPermission, registerServiceWorker } from "@/lib/push";
import { isNative, initNativePush, nativePushPermission, disableNativePush } from "@/lib/nativePush";

const DISMISS_KEY = "cw_push_dismissed_at";
const DISMISS_DAYS = 7;

function isDismissedRecently() {
  try {
    const at = parseInt(localStorage.getItem(DISMISS_KEY) || "0", 10);
    if (!at) return false;
    return Date.now() - at < DISMISS_DAYS * 24 * 60 * 60 * 1000;
  } catch { return false; }
}

export default function PushPrompt() {
  const [perm, setPerm] = useState("default");
  const [busy, setBusy] = useState(false);
  const [supported, setSupported] = useState(false);

  useEffect(() => {
    if (isNative()) {
      setSupported(true);
      nativePushPermission().then((p) =>
        setPerm(p === "prompt" || p === "prompt-with-rationale" ? "default" : p)
      );
      return;
    }
    setSupported(isPushSupported());
    setPerm(pushPermission());
    // Always register SW so push works as soon as user opts in
    registerServiceWorker();
  }, []);

  const enable = useCallback(async () => {
    setBusy(true);
    try {
      if (isNative()) {
        const res = await initNativePush();
        if (res !== "granted") throw new Error("Notifications were blocked.");
      } else {
        await enablePush();
      }
      setPerm("granted");
      toast.success("🔔 Push notifications on — you'll get pings even when the app is closed.");
    } catch (e) {
      toast.error(e.message || "Couldn't enable push notifications");
      setPerm(isNative() ? "denied" : pushPermission());
    } finally {
      setBusy(false);
    }
  }, []);

  const dismiss = () => {
    try { localStorage.setItem(DISMISS_KEY, String(Date.now())); } catch { /* noop */ }
    setPerm("dismissed");
  };

  if (!supported) return null;
  if (perm === "granted") return null;
  if (perm === "denied") return null;
  if (perm === "dismissed") return null;
  if (isDismissedRecently()) return null;

  return (
    <div
      data-testid="push-prompt"
      className="relative overflow-hidden rounded-2xl border border-yellow-400/30 bg-gradient-to-br from-yellow-400/[0.08] via-[#121214] to-[#121214] px-5 py-4 flex items-start gap-4"
    >
      <div className="shrink-0 w-11 h-11 rounded-xl bg-yellow-400/15 text-yellow-400 grid place-items-center">
        <BellRing className="w-5 h-5" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-display font-semibold text-white">Never miss a task deadline.</div>
        <div className="text-sm text-zinc-400 mt-0.5">
          Turn on push notifications and we&apos;ll ping you 30 minutes before every task is due — even when iLoveWorks is closed.
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-2">
          <button
            data-testid="push-enable-btn"
            onClick={enable}
            disabled={busy}
            className="inline-flex items-center gap-2 bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full px-4 h-9 text-sm transition disabled:opacity-60"
          >
            {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <BellRing className="w-4 h-4" />}
            Enable notifications
          </button>
          <button
            data-testid="push-dismiss-btn"
            onClick={dismiss}
            className="inline-flex items-center gap-1.5 text-xs text-zinc-400 hover:text-zinc-200 transition px-3 h-9 rounded-full"
          >
            Not now
          </button>
        </div>
      </div>
      <button
        data-testid="push-close-btn"
        onClick={dismiss}
        className="absolute top-2 right-2 w-7 h-7 rounded-full grid place-items-center text-zinc-500 hover:text-white hover:bg-white/5"
        aria-label="Dismiss"
      >
        <X className="w-4 h-4" />
      </button>
    </div>
  );
}

// Inline status used inside the Profile page to let users toggle/test.
export function PushSettings() {
  const [perm, setPerm] = useState("default");
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    if (isNative()) {
      nativePushPermission().then((p) => setPerm(p === "granted" ? "granted" : "default"));
    } else {
      setPerm(pushPermission());
    }
  }, []);

  const toggle = async () => {
    setBusy(true);
    try {
      if (perm === "granted") {
        if (isNative()) await disableNativePush();
        else await disablePush();
        toast.success("Push notifications disabled.");
        setPerm("default");
      } else {
        if (isNative()) {
          const res = await initNativePush();
          if (res !== "granted") throw new Error("Notifications were blocked in system settings.");
        } else {
          await enablePush();
        }
        setPerm("granted");
        toast.success("Push notifications enabled.");
      }
    } catch (e) {
      toast.error(e.message || "Couldn't toggle notifications");
    } finally { setBusy(false); }
  };

  if (!isNative() && !isPushSupported()) {
    return (
      <div className="text-sm text-zinc-500 inline-flex items-center gap-2">
        <BellOff className="w-4 h-4" /> Push notifications aren&apos;t supported on this browser.
      </div>
    );
  }
  return (
    <button
      data-testid="push-toggle"
      onClick={toggle}
      disabled={busy}
      className={`inline-flex items-center gap-2 rounded-full h-9 px-4 text-sm font-semibold border transition ${
        perm === "granted"
          ? "bg-zinc-900 border-yellow-400/30 text-yellow-300 hover:bg-yellow-400/10"
          : "bg-yellow-400 border-yellow-400 text-black hover:bg-yellow-300"
      }`}
    >
      {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : perm === "granted" ? <BellOff className="w-4 h-4" /> : <BellRing className="w-4 h-4" />}
      {perm === "granted" ? "Disable push notifications" : "Enable push notifications"}
    </button>
  );
}
