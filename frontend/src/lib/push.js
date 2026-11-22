// Web Push subscription helpers (Service Worker + VAPID)
import api from "@/lib/api";

function urlBase64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const rawData = atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; ++i) outputArray[i] = rawData.charCodeAt(i);
  return outputArray;
}

export function isPushSupported() {
  return (
    typeof window !== "undefined" &&
    "serviceWorker" in navigator &&
    "PushManager" in window &&
    "Notification" in window
  );
}

export function pushPermission() {
  if (!isPushSupported()) return "unsupported";
  return Notification.permission; // "default" | "granted" | "denied"
}

export function isIOS() {
  const ua = navigator.userAgent || "";
  return /iPad|iPhone|iPod/.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
}

export function isStandalone() {
  return window.navigator.standalone === true || !!window.matchMedia?.("(display-mode: standalone)").matches;
}

// iPhone Safari only allows web push from an app opened from the Home Screen.
export function needsHomeScreenInstall() {
  return isIOS() && !isStandalone();
}

export async function currentSubscription() {
  if (!isPushSupported()) return null;
  const reg = await navigator.serviceWorker.getRegistration();
  return reg ? reg.pushManager.getSubscription() : null;
}

export async function registerServiceWorker() {
  if (!isPushSupported()) return null;
  try {
    return await navigator.serviceWorker.register("/sw.js");
  } catch (e) {
    console.warn("SW registration failed", e);
    return null;
  }
}

const sameKey = (buf, key) => {
  if (!buf) return true; // browser doesn't expose it; trust the existing subscription
  const a = new Uint8Array(buf);
  return a.length === key.length && a.every((v, i) => v === key[i]);
};

// Makes sure this browser's subscription matches the server's key and is saved on the server.
async function syncSubscription() {
  const reg = await registerServiceWorker();
  if (!reg) throw new Error("Service worker failed to register.");
  const { data } = await api.get("/push/public-key");
  if (!data?.key || !data.available) throw new Error(`Web alerts aren't set up on the server${data?.problem ? `: ${data.problem}` : " yet"}.`);
  const key = urlBase64ToUint8Array(data.key);
  let sub = await reg.pushManager.getSubscription();
  if (sub && !sameKey(sub.options?.applicationServerKey, key)) {
    await sub.unsubscribe();
    sub = null;
  }
  if (!sub) sub = await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: key });
  await api.post("/push/subscribe", { subscription: sub.toJSON() });
  return sub;
}

export async function enablePush() {
  if (needsHomeScreenInstall()) throw new Error("On iPhone, add iLoveWorks to your Home Screen first, then open it from the new icon.");
  if (!isPushSupported()) throw new Error("Push notifications aren't supported on this browser.");
  const perm = await Notification.requestPermission();
  if (perm !== "granted") throw new Error("Notifications were blocked.");
  return syncSubscription();
}

export async function disablePush() {
  if (!isPushSupported()) return;
  const reg = await navigator.serviceWorker.getRegistration();
  if (!reg) return;
  const sub = await reg.pushManager.getSubscription();
  if (sub) {
    try { await api.post("/push/unsubscribe", { subscription: sub.toJSON() }); } catch { /* noop */ }
    await sub.unsubscribe();
  }
}

export async function sendTestPush() {
  const sub = await syncSubscription();
  const { data } = await api.post("/push/test", { endpoint: sub.endpoint });
  if (data?.ok) return;
  if (data?.web?.errors?.some((e) => /^(404|410)\b/.test(e))) {
    await sub.unsubscribe();
    throw new Error("This device's alert sign-up had expired. Tap Turn on alerts to sign up again.");
  }
  throw new Error(data?.message || "The alert couldn't be delivered.");
}
