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

export async function registerServiceWorker() {
  if (!isPushSupported()) return null;
  try {
    return await navigator.serviceWorker.register("/sw.js");
  } catch (e) {
    console.warn("SW registration failed", e);
    return null;
  }
}

export async function enablePush() {
  if (!isPushSupported()) throw new Error("Push notifications aren't supported on this browser.");
  const perm = await Notification.requestPermission();
  if (perm !== "granted") throw new Error("Notifications were blocked.");
  const reg = await registerServiceWorker();
  if (!reg) throw new Error("Service worker failed to register.");
  const { data } = await api.get("/push/public-key");
  if (!data?.key) throw new Error("Server isn't configured for push.");
  let sub = await reg.pushManager.getSubscription();
  if (!sub) {
    sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(data.key),
    });
  }
  await api.post("/push/subscribe", { subscription: sub.toJSON() });
  return sub;
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
  await api.post("/push/test");
}
